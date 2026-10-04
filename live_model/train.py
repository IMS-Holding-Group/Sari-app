# torch must load before pandas, otherwise c10.dll fails to initialise on Windows
import torch
import json
import os
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
from numpy.lib.stride_tricks import sliding_window_view
from torch import nn

import sim
from model import CONFIRM, WARN_CONFIRM, SariLSTM, over_limit, predict
from sim import FAULTS, SHORT_PU, WINDOW

ROOT = Path(__file__).resolve().parent
CLIENT_TRAIN = Path(os.environ.get("SARI_CLIENT_TRAIN", r"d:\VSCode\Projects\sari-client-data\train_.csv"))
TOL = 3
GRID = np.round(np.arange(0.30, 0.991, 0.05), 2)


def first_alarm(probs, raw, tau):
    hits = probs[..., :len(FAULTS)] >= np.asarray(tau)
    confirm = np.zeros_like(hits)
    confirm[:, CONFIRM - 1:] = np.all(np.stack([hits[:, k:hits.shape[1] - CONFIRM + 1 + k] for k in range(CONFIRM)]), axis=0)
    confirm &= over_limit(raw)
    confirm[..., 0] |= hits[..., 0] & (raw[..., 0] >= SHORT_PU)
    fired = confirm.any(axis=1)
    return np.where(fired, confirm.argmax(axis=1), -1)


def first_warning(probs, tau_pre, latched_at):
    hits = probs[..., -1] >= tau_pre
    out = np.full(len(hits), -1)
    for n in range(len(hits)):
        stop = hits.shape[1] if latched_at[n] < 0 else latched_at[n]
        run = 0
        for t in range(stop):
            run = run + 1 if hits[n, t] else 0
            if run >= WARN_CONFIRM:
                out[n] = t
                break
    return out


def near(label, t):
    return label[max(0, t - TOL):t + TOL + 1].any()


def score_sequences(probs, y, raw, tau):
    first = first_alarm(probs, raw, tau)
    fault = y[..., :len(FAULTS)] > 0.5
    any_fault = fault.any(axis=2)
    report = {}
    false_cut = 0
    for n in range(len(y)):
        fired = first[n][first[n] >= 0]
        if len(fired) and not near(any_fault[n], int(fired.min())):
            false_cut += 1
    for k, name in enumerate(FAULTS):
        has = fault[:, :, k].any(axis=1)
        onset = np.where(has, fault[:, :, k].argmax(axis=1), -1)
        hit = latency = wrong = 0
        lat = []
        for n in range(len(y)):
            t = first[n, k]
            if has[n] and t >= 0 and t >= onset[n] - TOL:
                hit += 1
                lat.append(t - onset[n])
            elif t >= 0 and not near(fault[n, :, k], t):
                wrong += 1
        report[name] = {
            "episodes": int(has.sum()),
            "detected": round(hit / max(int(has.sum()), 1), 4),
            "median_latency_s": float(np.median(lat)) if lat else None,
            "max_latency_s": int(np.max(lat)) if lat else None,
            "wrong_class_alarms": int(wrong),
        }
    report["false_cutoffs"] = int(false_cut)
    report["sequences"] = int(len(y))
    report["normal_sequences"] = int((~any_fault.any(axis=1)).sum())
    return report


def train_model(x, y, xv, yv, epochs=12):
    torch.manual_seed(0)
    model = SariLSTM()
    pos = y.reshape(-1, y.shape[-1]).mean(axis=0)
    weight = torch.tensor(np.clip((1 - pos) / np.maximum(pos, 1e-6), 1, 25), dtype=torch.float32)
    loss_fn = nn.BCEWithLogitsLoss(pos_weight=weight)
    opt = torch.optim.Adam(model.parameters(), lr=2e-3)
    sched = torch.optim.lr_scheduler.StepLR(opt, step_size=5, gamma=0.4)
    xt, yt = torch.from_numpy(x), torch.from_numpy(y)
    xvt, yvt = torch.from_numpy(xv), torch.from_numpy(yv)
    for epoch in range(epochs):
        model.train()
        order = torch.randperm(len(xt))
        total = 0.0
        for start in range(0, len(xt), 256):
            idx = order[start:start + 256]
            opt.zero_grad()
            loss = loss_fn(model(xt[idx]), yt[idx])
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            opt.step()
            total += loss.item() * len(idx)
        sched.step()
        model.eval()
        with torch.no_grad():
            val = loss_fn(model(xvt[:4000]), yvt[:4000]).item()
        print(f"epoch {epoch + 1} train {total / len(xt):.4f} val {val:.4f}", flush=True)
    return model


def stream_arrays(frame, rng, days):
    frame = frame.dropna()
    gaps = frame.index.to_series().diff() != pd.Timedelta(minutes=1)
    runs = gaps.cumsum()
    streams = []
    total = 0
    for _, part in frame.groupby(runs):
        if len(part) < 60 * 6:
            continue
        minutes = len(part)
        t = np.arange(minutes * 60)
        i = np.interp(t, np.arange(minutes) * 60 + 30, part.i.to_numpy()) / sim.UciSource.RATED
        v = np.interp(t, np.arange(minutes) * 60 + 30, part.v.to_numpy()) / float(np.median(frame.v))
        i = np.clip(i * (1 + rng.normal(0, 0.02, len(t))), 0, None)
        v = v * (1 + rng.normal(0, 0.003, len(t)))
        leak = np.clip(15 + 3 * i + rng.uniform(-2, 2, len(t)), 0, None)
        temp = sim.thermal(i, np.random.default_rng(1), ambient=30.0) + rng.uniform(-0.3, 0.3, len(t))
        streams.append(np.stack([i, v, leak, temp], axis=1).astype(np.float32))
        total += len(t)
        if total >= days * 86400:
            break
    return streams


def stream_probs(model, raw):
    feats = sim.features(raw[:, 0], raw[:, 1], raw[:, 2], raw[:, 3])
    windows = sliding_window_view(feats, (WINDOW, 4))[:, 0]
    model.eval()
    outs = []
    with torch.no_grad():
        for start in range(0, len(windows), 4096):
            chunk = torch.from_numpy(np.ascontiguousarray(windows[start:start + 4096]))
            outs.append(torch.sigmoid(model(chunk)[:, -1]).numpy())
    probs = np.concatenate(outs)
    return probs, raw[WINDOW - 1:]


def stream_alarms(probs, raw, tau):
    hits = probs[:, :len(FAULTS)] >= np.asarray(tau)
    confirm = np.zeros_like(hits)
    confirm[CONFIRM - 1:] = np.all(np.stack([hits[k:len(hits) - CONFIRM + 1 + k] for k in range(CONFIRM)]), axis=0)
    confirm &= over_limit(raw)
    confirm[:, 0] |= hits[:, 0] & (raw[:, 0] >= SHORT_PU)
    return confirm


def app_stream(rng, seconds, mode=()):
    i = 14.5 + rng.uniform(-0.6, 0.6, seconds)
    v = 220.0 + rng.uniform(-2, 2, seconds)
    leak = 0.02 + rng.uniform(-0.002, 0.002, seconds)
    temp = 32.0 + rng.uniform(-0.3, 0.3, seconds)
    if "surge" in mode:
        i = 48.5 + rng.uniform(0, 4, seconds)
        temp = temp + 8.0
    if "dip" in mode:
        v = 172.0 + rng.uniform(0, 5, seconds)
    if "leak" in mode:
        leak = 0.42 + rng.uniform(0, 0.1, seconds)
    return np.stack([i / 40.0, v / 220.0, leak * 1000.0, temp], axis=1).astype(np.float32)


def app_scenarios(model, tau):
    rng = np.random.default_rng(7)
    normal = app_stream(rng, 86400)
    probs, raw = stream_probs(model, normal)
    out = {"normal_24h_false_alarms": int(stream_alarms(probs, raw, tau).any(axis=1).sum())}
    for name, mode in (("surge", ("surge",)), ("dip", ("dip",)), ("leak", ("leak",)), ("surge+leak", ("surge", "leak"))):
        stream = np.concatenate([app_stream(rng, 300), app_stream(rng, 60, mode)])
        probs, raw = stream_probs(model, stream)
        confirm = stream_alarms(probs, raw, tau)
        onset = 300 - (WINDOW - 1)
        fired = {FAULTS[k]: (int(np.argmax(confirm[:, k])) - onset if confirm[:, k].any() else None) for k in range(len(FAULTS))}
        out[name] = {
            "before_fault_alarms": int(confirm[:onset].any(axis=1).sum()),
            "latency_s": {key: val for key, val in fired.items() if val is not None},
        }
    return out


def tune(probs, y, raw, val_stream):
    tau = []
    for k, name in enumerate(FAULTS):
        best = None
        for t in GRID:
            trial = [1.01] * len(FAULTS)
            trial[k] = t
            rep = score_sequences(probs, y, raw, trial)
            stream_fp = sum(int(stream_alarms(p, r, trial)[:, k].sum()) for p, r in val_stream)
            fp = rep["false_cutoffs"] + rep[name]["wrong_class_alarms"] + stream_fp
            key = (fp, -rep[name]["detected"], t)
            if best is None or key < best[0]:
                best = (key, float(t))
        tau.append(best[1])
        print(f"tau {name} = {best[1]} (false {best[0][0]}, detected {-best[0][1]})", flush=True)
    latched = first_alarm(probs, raw, tau)
    latched = np.where((latched >= 0).any(axis=1), np.where(latched >= 0, latched, 10 ** 6).min(axis=1), -1)
    any_fault = (y[..., :len(FAULTS)] > 0.5).any(axis=2)
    tau_pre = 1.01
    for t in GRID:
        warn = first_warning(probs, t, latched)
        false = sum(1 for n in range(len(y)) if warn[n] >= 0 and not any_fault[n, warn[n]:warn[n] + sim.HORIZON + TOL].any())
        if false == 0:
            tau_pre = float(t)
            break
    return tau, tau_pre


def main():
    torch.set_num_threads(os.cpu_count() or 4)
    started = time.time()
    parts = sim.split_uci(sim.load_uci())
    sources = {name: sim.UciSource(frame) for name, frame in parts.items()}
    x, y, _ = sim.batch(80000 if "--eval" not in sys.argv else 10, 1, sources["train"])
    xv, yv, rv = sim.batch(8000, 2, sources["val"])
    xs, ys, rs = sim.batch(20000, 3, sources["test"])
    print(f"data ready in {time.time() - started:.0f}s", flush=True)
    if "--eval" in sys.argv:
        model = SariLSTM()
        model.load_state_dict(torch.load(ROOT / "sari_lstm.pt"))
    else:
        model = train_model(x, y, xv, yv)
        torch.save(model.state_dict(), ROOT / "sari_lstm.pt")
    rng = np.random.default_rng(11)
    val_stream = [stream_probs(model, s) for s in stream_arrays(parts["val"], rng, 3)]
    tau, tau_pre = tune(predict(model, xv), yv, rv, val_stream)
    config = {
        "window": WINDOW,
        "tau": tau,
        "tau_pre": tau_pre,
        "confirm": CONFIRM,
        "limits": {
            "overload_pu": sim.OVERLOAD_PU,
            "short_pu": SHORT_PU,
            "v_low_pu": sim.V_LOW,
            "v_high_pu": sim.V_HIGH,
            "leak_ma": sim.LEAK_MA,
            "temp_c": sim.TEMP_C,
            "persist_s": sim.PERSIST,
        },
    }
    (ROOT / "sari_config.json").write_text(json.dumps(config, indent=2), encoding="utf-8")
    test_probs = predict(model, xs)
    real_test = [stream_probs(model, s) for s in stream_arrays(parts["test"], np.random.default_rng(12), 20)]
    real_seconds = sum(len(p) for p, _ in real_test)
    real_false = sum(int(stream_alarms(p, r, tau).any(axis=1).sum()) for p, r in real_test)
    client = pd.read_csv(CLIENT_TRAIN, usecols=["anomaly"]).anomaly
    metrics = {
        "test_sequences": score_sequences(test_probs, ys, rs, tau),
        "real_uci_held_out": {"days": round(real_seconds / 86400, 1), "false_alarm_seconds": real_false},
        "app_simulation": app_scenarios(model, tau),
        "client_dataset_all_normal_accuracy": round(float(1 - client.mean()), 4),
        "tau": tau,
        "tau_pre": tau_pre,
        "minutes": round((time.time() - started) / 60, 1),
    }
    (ROOT / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(json.dumps(metrics, indent=2), flush=True)


if __name__ == "__main__":
    main()
