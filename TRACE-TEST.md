# HDMI trace test

`test_hdmi_line_hold_trace.m` is a deliberately narrow diagnostic: it retains
the single firmware call that is already known to remove the HDMI focus square.
It adds a file marker at each phase, allowing us to distinguish a routine that
does not return from the later, separate display-off timeout.

It does **not** attempt to prevent the display timeout. The Canon Basic script
has no demonstrated way to remain scheduled after `Initialize()` returns, and
the camera rejected every prior test that added an unsupported call or delay.

Observed card result after Playback -> SET:

```
M50TRACE.TXT: 3 HDMI routine returned
```

The HDMI feed then went black when Display off was set to 15 seconds. This
establishes that the HDMI routine completed normally and the blackout is the
independent TFT/display power-save transition.
