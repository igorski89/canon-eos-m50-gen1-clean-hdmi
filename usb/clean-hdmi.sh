#!/bin/sh
# Clean HDMI over USB for the EOS M50: keeps the camera in PTP remote mode
# (so HDMI shows live view, not the PC-connect screen), hides the AF overlay
# with FA_OSDMuteOn, and re-applies both whenever the camera reconnects.
# Stop with Ctrl-C; power-cycle the camera to restore the overlay.
set -e
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  python3 -m venv .venv
  .venv/bin/pip -q install pyusb
fi
exec .venv/bin/python -I m50ptp.py run "${1:-60}"
