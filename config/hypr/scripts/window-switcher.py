#!/usr/bin/env python3
"""Super+Tab: pick any window on the current workspace from a rofi list."""
import json
import subprocess
import sys


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


def workspace_windows():
    try:
        data = json.loads(hypr("-j", "clients").stdout or "[]")
    except json.JSONDecodeError:
        return []
    current = active_workspace_id()
    out = []
    for c in data:
        cls = (c.get("class") or "").lower()
        if not c.get("mapped") or c.get("hidden"):
            continue
        if cls in ("", "rofi"):
            continue
        ws = (c.get("workspace") or {}).get("id")
        if current is not None and ws != current:
            continue
        if not c.get("address"):
            continue
        out.append(c)
    out.sort(key=lambda w: w.get("focusHistoryID", 9999))
    return out


def main():
    wins = workspace_windows()
    if not wins:
        return

    lines = []
    by_label = {}
    for i, w in enumerate(wins, 1):
        title = (w.get("title") or "").replace("\n", " ").strip() or "Untitled"
        cls = w.get("class") or "app"
        label = f"{i}  {title}   {cls}"
        lines.append(label)
        by_label[label] = w

    proc = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-p",
            "Apps",
            "-config",
            "/home/ping/.config/rofi/config.rasi",
            "-theme-str",
            "window { width: 520px; } listview { lines: 10; fixed-height: false; }",
        ],
        input="\n".join(lines) + "\n",
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return
    choice = (proc.stdout or "").rstrip("\n")
    w = by_label.get(choice)
    if not w:
        return
    addr = w.get("address")
    hypr("dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})')
    if w.get("floating"):
        hypr("dispatch", "hl.dsp.window.bring_to_top()")


if __name__ == "__main__":
    sys.exit(main() or 0)
