# Display power-save reset property: archived lead

The M50 1.1.0 ROM contains `GuiUtilTftPowerSaveController`, `ResetPowerSave`,
and `PROP_POWER_SAVE_TIMER_RESET(%d)`. A nearby literal pool contains property
ID `0x80020048` (signed 32-bit `-2147352504`). This is a credible native-code
research lead for resetting the TFT power-save timer.

`test_power_save_timer_reset.m` attempted one PropertyMgr request using that
ID and a value of `1`. On hardware it produced black output/unresponsiveness
and created neither expected marker. It is therefore an **archived failed
probe**, not a safe script or a recommended retest.

The candidate should be revisited only from a properly booted native payload,
where the calling convention, task context, error return, and periodic
scheduling can be instrumented.
