#!/usr/bin/env python3
"""Alt+Tab: swap the two most recent applications on this workspace."""
import json
import subprocess


def hypr(*args):
    return subprocess.run(
        ["hyprctl", *args],
        check=False,
        capture_output=True,
        text=True,
    )


def active_workspace_id():
    try:
        ws = json.loads(hypr("-j", "activeworkspace").stdout or "{}")
    except json.JSONDecodeError:
        return None
    return ws.get("id")


def clients():
    try:
        data = json.loads(hypr("-j", "clients").stdout or "[]")
    except json.JSONDecodeError:
        return []
    current = active_workspace_id()
    out = []
    for c in data:
        cls = c.get("class") or ""
        if not c.get("mapped") or c.get("hidden"):
            continue
        if cls == "" or cls.lower() == "rofi":
            continue
        ws = (c.get("workspace") or {}).get("id")
        if current is not None and ws != current:
            continue
        out.append(c)
    return out


def main():
    wins = clients()
    newest = {}
    for w in wins:
        cls = w.get("class")
        hist = w.get("focusHistoryID", 9999)
        prev = newest.get(cls)
        if prev is None or hist < prev.get("focusHistoryID", 9999):
            newest[cls] = w
    order = sorted(newest.values(), key=lambda w: w.get("focusHistoryID", 9999))
    if len(order) < 2:
        return
    target = order[1]
    addr = target.get("address")
    if not addr:
        return
    hypr("dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})')
    if target.get("floating"):
        hypr("dispatch", "hl.dsp.window.bring_to_top()")


if __name__ == "__main__":
    main()
