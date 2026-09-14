# EOS M50 Mk I HDMI display-off investigation

Status: **resolved as a Canon Basic limitation; no Canon Basic fix was found.**

## Confirmed behavior

The menu settings below do not prevent the HDMI capture from becoming black
when `Display off` expires:

| Menu setting | Tested value |
| --- | --- |
| Eco mode | Off |
| Auto power off | Disable |
| Viewfinder off | Disable |
| Display off | 15 seconds for accelerated testing; 30 minutes is the maximum |

`Display off` is independent from Auto power off. The M50 menu exposes no
Disable value for it.

The clean-HDMI routine at `0xE0538114` was independently traced. Its card log
contained `3 HDMI routine returned`, then the HDMI feed still went black at
the 15-second Display off timeout. This separates the successful overlay mute
from the later TFT/display power-save transition.

## ROM leads examined

The M50 1.1.0 ROM contains these relevant leads:

- `PropertyMgr.c` `pRequestChange` at `0xE0559D60`;
- generic `PROP_ICU_AUTO_POWEROFF` (`0x80030024`), with generic values permit,
  prohibit, and prolong/reset;
- `GuiUtilTftPowerSaveController`, `ResetPowerSave`, and
  `PROP_POWER_SAVE_TIMER_RESET(%d)`;
- property literal `0x80020048` near that controller's strings;
- event-name strings including `DisablePowerSave`.

These strings and IDs identify likely internals; they do not establish a safe
Canon Basic ABI or a persistent scheduling mechanism.

## Hardware results: rejected probes

Every probe below resulted in black output/unresponsiveness after Playback →
SET and did not create its expected first marker. The known-good
`test_hdmi_line_hold.m` was restored after each attempt.

| Archived script | Attempt | Result |
| --- | --- | --- |
| `test_powersave_prolong.m` / `test_hdmi_keepawake.m` | Direct PropertyMgr request for generic auto-power-off prolong/prohibit | Failed before marker |
| `test_disable_powersave.m` | Named `ExecuteEventProcedure("DisablePowerSave")` | Failed before marker |
| `test_hdmi_line_active_120s.m` | Known HDMI call plus `SleepTask(120000)` | Failed before marker |
| `test_hdmi_line_active_8x15s.m` | Eight `SleepTask(15000)` calls | Failed before marker |
| `test_power_save_timer_reset.m` | Direct request of `0x80020048` as signed decimal | Failed before marker |

Some tests exported a firmware routine before writing their first marker, so
the exact failure boundary is not proven. The practical conclusion is still
clear: this Canon Basic environment has only demonstrated the narrow
one-shot HDMI routine; it cannot be relied on for PropertyMgr, event
dispatch, or task delays on this camera.

## Next paths

1. **Recommended:** test USB remote control alongside HDMI and automate a
   half-press/release every few seconds. This does not require camera-firmware
   modification, but coexistence with the capture setup must be tested.
2. **Research only:** native `autoexec.bin` payload with a proper background
   task. See [NATIVE-PAYLOAD-FEASIBILITY.md](NATIVE-PAYLOAD-FEASIBILITY.md).
3. Internal recording keeps the camera active but is bounded by the recording
   duration and is not a continuous webcam solution.

## Card status at conclusion

The active card contains `test_hdmi_line_hold_trace.m`, a safe trace variant
of the validated one-shot HDMI call. Its `M50TRACE.TXT` result is recorded
above; the original `test_hdmi_line_hold.m` remains the reference script and
a same-content working backup remains on the card. No firmware was flashed
and no camera boot flag was changed during these Canon Basic experiments.
