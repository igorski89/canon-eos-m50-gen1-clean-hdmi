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
# The HDMI dongle scales 16:9 into whatever mode an app picks (often 4:3);
# m50ptp.py forces this format on every camera connect.
if [ ! -x capture-format ] || [ capture-format.swift -nt capture-format ]; then
  swiftc -O capture-format.swift -o capture-format
fi
export CAPTURE_FORMAT_BIN="$PWD/capture-format"
export CAPTURE_FORMAT="${CAPTURE_FORMAT:-1920x1080}"
exec .venv/bin/python -I m50ptp.py run "${1:-60}"
