# EOS M50 1.1.0 clean-HDMI webcam workflow

The working `extend.m` invokes Canon's own HDMI-Line OSD mute routine at `0xE0538114` with user ID `0x1000`. It suppresses the AF square and other HDMI overlays while preserving live video, autofocus, and the built-in LCD. It does not patch firmware.

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
- `M50-ROM0-00000000-00800000.bin`: 8 MiB ROM evidence used for address recovery.
