#!/bin/bash
# Hypridle dim: 15% of max, not "10" raw (that is ~0% on this panel).
exec /usr/bin/brightnessctl -d amdgpu_bl1 --class backlight -s set 15%
