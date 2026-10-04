import torch
import numpy as np
from torch import nn

from sim import FAULTS, LEAK_MA, OVERLOAD_PU, SHORT_PU, TEMP_C, V_HIGH, V_LOW

CONFIRM = 3
WARN_CONFIRM = 5


def over_limit(raw):
    return np.stack([
        raw[..., 0] >= OVERLOAD_PU,
        (raw[..., 1] < V_LOW) | (raw[..., 1] > V_HIGH),
        raw[..., 2] >= LEAK_MA,
        raw[..., 3] >= TEMP_C,
    ], axis=-1)


class SariLSTM(nn.Module):
    def __init__(self, hidden=64):
        super().__init__()
        self.lstm = nn.LSTM(4, hidden, num_layers=2, batch_first=True, dropout=0.1)
        self.head = nn.Linear(hidden, len(FAULTS) + 1)

    def forward(self, x):
        out, _ = self.lstm(x)
        return self.head(out)


def predict(model, x, batch_size=4096):
    model.eval()
    outs = []
    with torch.no_grad():
        for start in range(0, len(x), batch_size):
            chunk = torch.from_numpy(x[start:start + batch_size])
            outs.append(torch.sigmoid(model(chunk)).numpy())
    return np.concatenate(outs)


class AlarmPolicy:
    def __init__(self, tau, tau_pre):
        self.tau = np.asarray(tau, dtype=float)
        self.tau_pre = float(tau_pre)
        self.reset()

    def reset(self):
        self.count = np.zeros(len(FAULTS), dtype=int)
        self.warn = 0
        self.latched = np.zeros(len(FAULTS), dtype=bool)

    def step(self, probs, pre, raw_row):
        hits = probs >= self.tau
        self.count = np.where(hits, self.count + 1, 0)
        confirmed = (self.count >= CONFIRM) & over_limit(np.asarray(raw_row))
        confirmed[0] |= hits[0] and raw_row[0] >= SHORT_PU
        rising = bool(confirmed.any() and not self.latched.any())
        self.latched |= confirmed
        self.warn = self.warn + 1 if pre >= self.tau_pre and not self.latched.any() else 0
        return {
            "alarm": bool(self.latched.any()),
            "rising": rising,
            "faults": [FAULTS[k] for k in np.nonzero(self.latched)[0]],
            "warning": self.warn >= WARN_CONFIRM,
        }


def run_policy(probs, raw, tau, tau_pre):
    policy = AlarmPolicy(tau, tau_pre)
    first = np.full(len(FAULTS), -1)
    warn_first = -1
    for t in range(probs.shape[0]):
        decision = policy.step(probs[t, :len(FAULTS)], probs[t, -1], raw[t])
        for name in decision["faults"]:
            k = FAULTS.index(name)
            if first[k] < 0:
                first[k] = t
        if decision["warning"] and warn_first < 0:
            warn_first = t
    return first, warn_first
