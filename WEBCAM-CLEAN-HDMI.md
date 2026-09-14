# EOS M50 1.1.0 clean-HDMI webcam workflow

The working `extend.m` invokes Canon's own HDMI-Line OSD mute routine at `0xE0538114` with user ID `0x1000`. It suppresses the AF square and other HDMI overlays while preserving live video, autofocus, and the built-in LCD. It does not patch firmware.

## Known continuous-use limitation

This is not a permanent webcam mode. The camera's separate `Display off`
timer powers down the display/TFT path and makes HDMI capture black. Even with
Eco mode off, Auto power off disabled, and Viewfinder off disabled, the M50
offers no Disable choice for Display off; 30 minutes is the maximum menu value.

The confirmed clean-HDMI call returns immediately and cannot observe or reset
that later timeout. Use the maximum timeout for occasional use. For continuous
operation, use an external keep-awake method (for example a tested USB remote
half-press loop) rather than the archived Canon Basic power-save probes.

## Use

1. Insert the prepared card and connect HDMI to the capture card.
2. Power on in Movie mode and confirm live HDMI.
3. Press Playback, then SET once to run Canon Basic.
4. Wait three seconds, then press Playback again to return to live view.
5. Use the clean HDMI feed as the webcam source.
6. Power-cycle the camera when finished to restore normal HDMI overlays.

Do not press SET while already in live view; that opens the normal AF menu instead of running the script.

## Card compatibility

Canon Basic launching was verified on the prepared FAT32 card. The same `extend.m` and `script.req` copied to a camera-formatted 256 GB exFAT card did not launch, even though the camera could record normally. The FAT32 card's boot-sector `SCRIPT` marker is required by this setup. Use a FAT32 card; do not apply the FAT32 marker procedure to an exFAT card.

## Recovery

If HDMI becomes black or the camera appears stuck, power it off and remove the battery for 30 seconds. Reinsert the battery and start once without the card. The script is reversible and does not alter firmware.

## Files

- `test_hdmi_line_hold.m`: validated one-shot script (mute and return).
- `minimal_status.m`: harmless fallback script.
- `test_hdmi_line_hold_trace.m`: diagnostic variant. Hardware result:
  `M50TRACE.TXT` reported `3 HDMI routine returned` before the 15-second
  Display off transition.
- `M50-ROM0-00000000-00800000.bin`: 8 MiB ROM evidence used for address recovery.
