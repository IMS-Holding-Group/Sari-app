# torch must load before pandas, otherwise c10.dll fails to initialise on Windows
import torch
import hmac
import json
import logging
import os
import re
import threading
import time
from collections import deque
from datetime import datetime
from pathlib import Path

import numpy as np
from flask import Flask, abort, jsonify, request, send_from_directory
from werkzeug.serving import WSGIRequestHandler

import sim
from model import AlarmPolicy, SariLSTM
from reports import FAULT_AR, FILES, format_ar, write_report

ROOT = Path(__file__).resolve().parent
DEVICE_ID = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
REPORT_ID = re.compile(r"^[A-Za-z0-9_-]{1,64}_\d{8}T\d{6}$")
MAX_DEVICES = 500
MAX_GAP_S = 10
RATE_PER_SECOND = 30

FAULT_INFO = {
    "overcurrent": ("CRITICAL", "Overcurrent Thermal Overload", "Reduce the load and inspect the circuit before re-energizing.", "خفف الأحمال وافحص الدائرة قبل إعادة التشغيل."),
    "leakage": ("CRITICAL", "Current Leakage Hazard", "Inspect insulation and the grounding line before re-energizing.", "افحص العوازل وخط التأريض قبل إعادة التشغيل."),
    "overheat": ("CRITICAL", "Conductor Overheating", "Check terminals, connections and cable sizing before re-energizing.", "افحص نقاط التوصيل ومقاس الكابلات قبل إعادة التشغيل."),
    "voltage": ("HIGH", "Voltage Fluctuation Anomaly", "Verify the supply and the voltage regulator before re-energizing.", "تحقق من مصدر التغذية ومنظم الجهد قبل إعادة التشغيل."),
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("sari.server")


def _load_env():
    path = ROOT / ".env"
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


_load_env()
TOKEN = os.environ.get("MODEL_TOKEN", "")
if len(TOKEN) < 16:
    raise SystemExit("MODEL_TOKEN must be set in live_model/.env (16+ characters)")
ALLOWED_ORIGINS = {o.strip() for o in os.environ.get("ALLOWED_ORIGINS", "").split(",") if o.strip()}
REPORTS = Path(os.environ.get("REPORTS_DIR", str(ROOT / "reports")))

CONFIG = json.loads((ROOT / "sari_config.json").read_text(encoding="utf-8"))
DEVICES = json.loads((ROOT / "devices.json").read_text(encoding="utf-8"))
torch.set_num_threads(2)
MODEL = SariLSTM()
MODEL.load_state_dict(torch.load(ROOT / "sari_lstm.pt", map_location="cpu"))
MODEL.eval()

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 4096
WSGIRequestHandler.server_version = "SARI"
WSGIRequestHandler.sys_version = ""
lock = threading.Lock()
states = {}
hits = {}


class DeviceState:
    def __init__(self, device_id):
        spec = DEVICES.get(device_id, DEVICES["default"])
        self.rated = float(spec["rated_current"])
        self.nominal = float(spec["nominal_voltage"])
        self.location = spec.get("location", "")
        self.raw = deque(maxlen=CONFIG["window"])
        self.rows = deque(maxlen=CONFIG["window"])
        self.policy = AlarmPolicy(CONFIG["tau"], CONFIG["tau_pre"])
        self.manual_cutoff = False
        self.last_ts = None
        self.last = None
        self.report = None


def _authorized():
    return hmac.compare_digest(request.headers.get("X-Model-Token", ""), TOKEN)


def _rate_ok():
    now = time.monotonic()
    key = request.remote_addr or "?"
    window = hits.setdefault(key, deque())
    while window and now - window[0] > 1.0:
        window.popleft()
    if len(window) >= RATE_PER_SECOND:
        return False
    window.append(now)
    return True


def _number(body, key, low, high):
    value = float(body[key])
    if not (low <= value <= high):
        raise ValueError(key)
    return value


def _state(device_id):
    state = states.get(device_id)
    if state is None:
        if len(states) >= MAX_DEVICES:
            abort(429)
        state = states[device_id] = DeviceState(device_id)
    return state


def _result(state, probs, pre, decision, reading):
    pmax = float(probs.max())
    pre_term = pre if pre >= CONFIG["tau_pre"] else 0.0
    score = int(round(100 * (1 - max(pmax, 0.5 * pre_term))))
    limits = CONFIG["limits"]
    if decision["alarm"]:
        faults = decision["faults"]
        level, title, action, _ = FAULT_INFO[faults[0]]
        if any(FAULT_INFO[f][0] == "CRITICAL" for f in faults):
            level = "CRITICAL"
        causes = []
        for f in faults:
            if f == "overcurrent":
                causes.append(f"Current {reading['current']:.1f} A above {limits['overload_pu'] * state.rated:.1f} A")
            elif f == "voltage":
                causes.append(f"Voltage {reading['voltage']:.1f} V outside {state.nominal:.0f} V +/-10%")
            elif f == "leakage":
                causes.append(f"Leakage {reading['leakage'] * 1000:.0f} mA above {limits['leak_ma']:.0f} mA")
            else:
                causes.append(f"Temperature {reading['temperature']:.1f} C above {limits['temp_c']:.0f} C")
        return {
            "safetyScore": min(score, 40),
            "riskLevel": level,
            "riskType": " + ".join(FAULT_INFO[f][1] for f in faults),
            "probability": round(max(pmax, 0.5), 4),
            "cause": "; ".join(causes),
            "recommendedAction": "Power was cut automatically. " + action,
            "hasAnomaly": True,
        }
    if decision["warning"]:
        likely = sim.FAULTS[int(np.argmax(probs))]
        return {
            "safetyScore": min(score, 70),
            "riskLevel": "MEDIUM",
            "riskType": f"Early Warning: {FAULT_INFO[likely][1]} expected",
            "probability": round(float(pre), 4),
            "cause": "Readings are trending toward a fault within 60 s",
            "recommendedAction": "Inspect the circuit now. No cutoff yet.",
            "hasAnomaly": False,
        }
    return {
        "safetyScore": score,
        "riskLevel": "LOW",
        "riskType": "No abnormal behavior detected",
        "probability": round(pmax, 4),
        "cause": "Optimal Operating Parameters",
        "recommendedAction": "System operating normally. Continue scheduled monitoring.",
        "hasAnomaly": False,
    }


@app.after_request
def _headers(response):
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Content-Security-Policy"] = "default-src 'none'"
    response.headers["Cache-Control"] = "no-store"
    origin = request.headers.get("Origin", "")
    if origin in ALLOWED_ORIGINS:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-Model-Token"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Vary"] = "Origin"
    return response


@app.before_request
def _guard():
    if request.method == "OPTIONS":
        return app.make_default_options_response()
    if request.path == "/health":
        return None
    if not _rate_ok():
        return jsonify({"error": "too many requests"}), 429
    if not _authorized():
        return jsonify({"error": "unauthorized"}), 401
    return None


@app.errorhandler(Exception)
def _error(exc):
    code = getattr(exc, "code", 500)
    if not isinstance(code, int) or code >= 500:
        log.exception("request failed")
        return jsonify({"error": "server error"}), 500
    return jsonify({"error": "request rejected"}), code


@app.post("/v1/reading")
def reading():
    body = request.get_json(silent=True) or {}
    device_id = str(body.get("device_id", ""))
    if not DEVICE_ID.match(device_id):
        return jsonify({"error": "invalid device"}), 400
    try:
        values = {
            "current": _number(body, "current", 0, 10000),
            "voltage": _number(body, "voltage", 0, 1000),
            "leakage": _number(body, "leakage", 0, 100),
            "temperature": _number(body, "temperature", -50, 300),
        }
        ts = datetime.fromisoformat(str(body["timestamp"]).replace("Z", "")) if body.get("timestamp") else datetime.now()
    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "invalid reading"}), 400
    with lock:
        state = _state(device_id)
        if state.last_ts is not None and (ts - state.last_ts).total_seconds() > MAX_GAP_S:
            state.raw.clear()
            state.rows.clear()
        state.last_ts = ts
        i_pu = values["current"] / state.rated
        state.raw.append((i_pu, values["voltage"] / state.nominal, values["leakage"] * 1000, values["temperature"]))
        raw = np.asarray(state.raw, dtype=np.float32)
        feats = sim.features(raw[:, 0], raw[:, 1], raw[:, 2], raw[:, 3])
        with torch.no_grad():
            out = torch.sigmoid(MODEL(torch.from_numpy(feats[None]))[0, -1]).numpy()
        probs, pre = out[:len(sim.FAULTS)], float(out[-1])
        decision = state.policy.step(probs, pre, raw[-1])
        state.rows.append({
            "time": ts.isoformat(timespec="seconds"),
            "current_a": round(values["current"], 3),
            "voltage_v": round(values["voltage"], 2),
            "leakage_ma": round(values["leakage"] * 1000, 1),
            "temperature_c": round(values["temperature"], 2),
            **{f"p_{name}": round(float(p), 4) for name, p in zip(sim.FAULTS, probs)},
            "p_prefault": round(pre, 4),
        })
        result = _result(state, probs, pre, decision, values)
        payload = {
            "device_id": device_id,
            "timestamp": ts.isoformat(timespec="seconds"),
            "time_display": format_ar(ts),
            "alarm": decision["alarm"],
            "cutoff": decision["alarm"] or state.manual_cutoff,
            "warning": decision["warning"],
            "faults": decision["faults"],
            "probabilities": {name: round(float(p), 4) for name, p in zip(sim.FAULTS, probs)},
            "prefault": round(pre, 4),
            "result": result,
        }
        if decision["rising"]:
            report_id = f"{device_id}_{ts:%Y%m%dT%H%M%S}"
            summary = {
                "device_id": device_id,
                "location": state.location,
                "time": ts.isoformat(timespec="seconds"),
                "time_display": format_ar(ts),
                "faults": decision["faults"],
                "faults_ar": [FAULT_AR[f] for f in decision["faults"]],
                "probability": result["probability"],
                "current_a": values["current"],
                "voltage_v": values["voltage"],
                "leakage_ma": values["leakage"] * 1000,
                "temperature_c": values["temperature"],
                "cause": result["cause"],
                "action": result["recommendedAction"],
                "action_ar": "تم قطع التيار تلقائياً. " + FAULT_INFO[decision["faults"][0]][3],
                "limits": CONFIG["limits"],
                "rated_current_a": state.rated,
                "nominal_voltage_v": state.nominal,
            }
            state.report = {"id": report_id, "files": write_report(REPORTS, report_id, summary, list(state.rows))}
            log.info("alarm %s %s", device_id, ",".join(decision["faults"]))
        if decision["alarm"] and state.report:
            payload["report"] = state.report
        state.last = payload
    return jsonify(payload)


@app.get("/v1/devices/<device_id>/command")
def command(device_id):
    if not DEVICE_ID.match(device_id):
        return jsonify({"error": "invalid device"}), 400
    with lock:
        state = states.get(device_id)
        latched = bool(state and (state.policy.latched.any() or state.manual_cutoff))
    return jsonify({"device_id": device_id, "cutoff": latched})


@app.post("/v1/devices/<device_id>/cutoff")
def cutoff(device_id):
    if not DEVICE_ID.match(device_id):
        return jsonify({"error": "invalid device"}), 400
    with lock:
        state = _state(device_id)
        state.manual_cutoff = True
    log.info("manual cutoff %s", device_id)
    return jsonify({"device_id": device_id, "cutoff": True})


@app.post("/v1/devices/<device_id>/reset")
def reset(device_id):
    if not DEVICE_ID.match(device_id):
        return jsonify({"error": "invalid device"}), 400
    with lock:
        states.pop(device_id, None)
    log.info("reset %s", device_id)
    return jsonify({"device_id": device_id, "cutoff": False})


@app.get("/v1/reports/<report_id>/<name>")
def report_file(report_id, name):
    if not REPORT_ID.match(report_id) or name not in FILES:
        return jsonify({"error": "not found"}), 404
    folder = REPORTS / report_id
    if not (folder / name).is_file():
        return jsonify({"error": "not found"}), 404
    return send_from_directory(folder, name, as_attachment=True)


@app.get("/health")
def health():
    return jsonify({"ok": True})


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8080"))
    try:
        from waitress import serve
        serve(app, host=host, port=port, ident="SARI")
    except ImportError:
        app.run(host=host, port=port, debug=False, threaded=True)
