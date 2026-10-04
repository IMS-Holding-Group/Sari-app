import os
from pathlib import Path

import numpy as np
import pandas as pd

UCI_PATH = Path(os.environ.get("SARI_UCI_PATH", r"d:\VSCode\Projects\sari-client-data\uci\household_power_consumption.txt"))

OVERLOAD_PU = 1.13
SHORT_PU = 5.0
V_LOW = 0.90
V_HIGH = 1.10
LEAK_MA = 30.0
TEMP_C = 70.0
PERSIST = 3
HORIZON = 60
WINDOW = 120
FAULTS = ("overcurrent", "voltage", "leakage", "overheat")


def load_uci(path=UCI_PATH):
    df = pd.read_csv(path, sep=";", na_values="?", usecols=["Date", "Time", "Voltage", "Global_intensity"], low_memory=False)
    index = pd.to_datetime(df.Date + " " + df.Time, format="%d/%m/%Y %H:%M:%S")
    return pd.DataFrame({"v": df.Voltage.to_numpy(float), "i": df.Global_intensity.to_numpy(float)}, index=index)


def split_uci(frame):
    return {
        "train": frame[frame.index < "2010-01-01"],
        "val": frame[(frame.index >= "2010-01-01") & (frame.index < "2010-06-01")],
        "test": frame[frame.index >= "2010-06-01"],
    }


class UciSource:
    RATED = 60.0

    def __init__(self, frame, span=5):
        self.v = frame.v.to_numpy()
        self.i = frame.i.to_numpy()
        self.v_ref = float(np.nanmedian(self.v))
        bad = np.isnan(self.v) | np.isnan(self.i)
        counts = np.concatenate([[0], np.cumsum(bad)])
        self.span = span
        self.starts = np.nonzero(counts[span:] - counts[:-span] == 0)[0]

    def seconds(self, rng, length):
        start = int(rng.choice(self.starts))
        minutes = np.arange(self.span) * 60.0 + 30.0
        offset = rng.uniform(0, 60)
        t = np.arange(length) + offset
        i = np.interp(t, minutes, self.i[start:start + self.span]) / self.RATED
        v = np.interp(t, minutes, self.v[start:start + self.span]) / self.v_ref
        return i, v


def thermal(i_pu, rng, ambient=None):
    ambient = rng.uniform(18, 42) if ambient is None else ambient
    rise = rng.uniform(10, 30)
    tau = rng.uniform(120, 900)
    temp = np.empty_like(i_pu)
    temp[0] = ambient + rise * i_pu[0] ** 2
    for t in range(1, len(i_pu)):
        target = ambient + rise * i_pu[t] ** 2
        temp[t] = temp[t - 1] + (target - temp[t - 1]) / tau
    return temp


def _span(rng, length, start, ramp):
    shape = np.zeros(length)
    if ramp:
        dur = int(rng.integers(20, 150))
        stop = min(length, start + dur)
        shape[start:stop] = np.linspace(0, 1, stop - start, endpoint=False)
        shape[stop:] = 1.0
    else:
        shape[start:] = 1.0
    return shape


def inject(kind, raw, rng, start, app_style):
    i, v, leak, temp = raw
    length = len(i)
    ramp = (not app_style) and rng.random() < 0.4
    shape = _span(rng, length, start, ramp)
    if kind == "overcurrent":
        if app_style:
            level = (48.5 + rng.uniform(0, 4, length)) / 40.0
            temp += 8.0 * shape
        elif rng.random() < 0.15:
            level = rng.uniform(SHORT_PU, 12.0) * (1 + rng.normal(0, 0.02, length))
            shape = _span(rng, length, start, False)
        else:
            level = rng.uniform(1.2, 3.0) * (1 + rng.normal(0, 0.02, length))
        i[:] = i + shape * (level - i)
    elif kind == "voltage":
        if app_style:
            level = (172.0 + rng.uniform(0, 5, length)) / 220.0
        elif rng.random() < 0.5:
            level = rng.uniform(0.05, 0.86) + rng.normal(0, 0.004, length)
        else:
            level = rng.uniform(1.14, 1.35) + rng.normal(0, 0.004, length)
        v[:] = v + shape * (level - v)
    elif kind == "leakage":
        if app_style:
            level = 420.0 + rng.uniform(0, 100, length)
        else:
            level = rng.uniform(40, 800) + rng.uniform(-2, 2, length)
        leak[:] = leak + shape * (level - leak)
    else:
        peak = rng.uniform(72, 110)
        shape = _span(rng, length, start, True)
        temp[:] = temp + shape * (peak - temp)


def distract(raw, rng, app_style):
    i, v, leak, temp = raw
    length = len(i)
    for _ in range(int(rng.integers(1, 5))):
        at = int(rng.integers(0, length - 2))
        dur = int(rng.integers(1, PERSIST))
        kind = rng.integers(0, 5)
        if kind == 0:
            i[at:at + dur] = np.minimum(i[at:at + dur] * rng.uniform(1.5, 4.0) + rng.uniform(0.3, 1.2), 4.5)
        elif kind == 1:
            v[at:at + dur] *= rng.uniform(0.75, 0.95)
        elif kind == 2:
            leak[at:at + dur] += rng.uniform(10, 60)
        elif kind == 3:
            temp[at:at + dur] += rng.uniform(5, 40)
        else:
            hold = min(length, at + int(rng.integers(1, 6)))
            for arr in (i, v, leak, temp):
                arr[at:hold] = arr[at - 1] if at > 0 else arr[0]


def app_like(rng, length):
    i = rng.uniform(0.1, 0.9) + rng.uniform(-0.6, 0.6, length) / 40.0
    v = rng.uniform(0.95, 1.05) + rng.uniform(-2, 2, length) / 220.0
    leak = rng.uniform(2, 25) + rng.uniform(-2, 2, length)
    temp = rng.uniform(20, 40) + rng.uniform(-0.3, 0.3, length)
    return [i, v, leak, temp]


def uci_like(source, rng, length):
    i, v = source.seconds(rng, length)
    i = i * rng.uniform(0.5, 2.0)
    v = v * rng.uniform(0.97, 1.03)
    if rng.random() < 0.3:
        at = int(rng.integers(0, length))
        dur = int(rng.integers(10, 200))
        i[at:at + dur] += rng.uniform(0.05, 0.4)
    i = np.clip(i * (1 + rng.normal(0, 0.02, length)), 0, None)
    v = v * (1 + rng.normal(0, 0.003, length))
    leak = np.clip(rng.uniform(1, 25) + 3.0 * i + rng.uniform(-2, 2, length), 0, None)
    temp = thermal(i, rng) + rng.uniform(-0.3, 0.3, length)
    return [i, v, leak, temp]


def labels(i, v, leak, temp):
    cond = np.stack([i >= OVERLOAD_PU, (v < V_LOW) | (v > V_HIGH), leak >= LEAK_MA, temp >= TEMP_C], axis=1)
    run = np.zeros(cond.shape, dtype=int)
    for t in range(len(i)):
        run[t] = np.where(cond[t], (run[t - 1] if t else 0) + 1, 0)
    fault = run >= PERSIST
    fault[:, 0] |= i >= SHORT_PU
    any_fault = fault.any(axis=1)
    pre = np.zeros(len(i), dtype=bool)
    upcoming = np.nonzero(any_fault)[0]
    for t in np.nonzero(~any_fault)[0]:
        nxt = upcoming[np.searchsorted(upcoming, t + 1)] if np.searchsorted(upcoming, t + 1) < len(upcoming) else None
        pre[t] = nxt is not None and nxt - t <= HORIZON
    return np.concatenate([fault, pre[:, None]], axis=1).astype(np.float32)


def features(i, v, leak, temp):
    i = np.clip(np.nan_to_num(i), 0, 20)
    v = np.clip(np.nan_to_num(v, nan=1.0), 0, 1.6)
    leak = np.clip(np.nan_to_num(leak), 0, 2000)
    temp = np.clip(np.nan_to_num(temp, nan=25.0), -20, 150)
    return np.stack([np.log1p(i), v, np.log1p(leak) / 7.0, temp / 100.0], axis=-1).astype(np.float32)


def sequence(rng, source, fault_rate=0.55):
    length = WINDOW + HORIZON
    app_style = rng.random() < 0.35
    raw = app_like(rng, length) if app_style else uci_like(source, rng, length)
    if rng.random() < 0.5:
        distract(raw, rng, app_style)
    kinds = []
    if rng.random() < fault_rate:
        kinds.append(FAULTS[int(rng.integers(0, 4))])
        if rng.random() < 0.15:
            kinds.append(FAULTS[int(rng.integers(0, 4))])
        start = int(rng.integers(5, WINDOW + HORIZON - 10))
        for kind in kinds:
            inject(kind, raw, rng, start, app_style and kind != "overheat")
    i, v, leak, temp = raw
    y = labels(i, v, leak, temp)
    return features(i, v, leak, temp)[:WINDOW], y[:WINDOW], np.stack(raw, axis=1)[:WINDOW].astype(np.float32)


def batch(n, seed, source, fault_rate=0.55):
    rng = np.random.default_rng(seed)
    xs, ys, raws = zip(*(sequence(rng, source, fault_rate) for _ in range(n)))
    return np.stack(xs), np.stack(ys), np.stack(raws)
