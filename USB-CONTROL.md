# Clean HDMI over USB (no SD-card script)

Status: **validated on hardware 2026-10-21**, including `usb/clean-hdmi.sh`
(M50 firmware 1.1.0, internal build `7.3.0 34(00)`, macOS, Apple Silicon).
Power-cycling the camera mid-session was also validated: the launcher logged
the loss, reconnected 4 s after power-on, and re-hid the AF square 6 s later.

## Result

The camera exposes Canon's PTP event-procedure opcodes over USB, and the
factory routine `FA_OSDMuteOn` is registered by name. Calling it over USB
removes the AF square from the HDMI feed; `FA_OSDMuteOff` restores it. This was
toggled off → on → off on hardware with no Canon Basic script involved.

Holding a PTP session in **remote mode** also solves the display-off problem
in testing: with `Display off = 15 sec`, the HDMI feed stayed live past 15
seconds, and a remote-mode session survived a 15-minute soak without any
keep-alive pings.

## Usage

1. Camera on, in live view; HDMI to the capture device; USB to the Mac.
2. Run `usb/clean-hdmi.sh` (first run creates `usb/.venv` with pyusb; needs
   Homebrew `libusb`).
3. Keep it running. Ctrl-C stops it; power-cycle the camera to restore the
   overlay.

The launcher stops macOS's `ptpcamerad`/`mscamerad-xpc`, opens a session,
sends `SetRemoteMode 1` / `SetEventMode 1`, waits 5 s, calls `FA_OSDMuteOn`
and re-applies it every 30 s, polls `GetEvent`, sends `KeepDeviceOn` every
60 s as extra margin, and repeats the whole sequence if the camera
disconnects.

The delay matters: when the script was started first and the camera powered
on afterwards, a mute sent the moment USB came up returned `0x2001` but the AF
square stayed on HDMI. `FA_OSDMuteOn` selects its display target when called,
so it must run after live view and HDMI are up. Delayed, periodic re-muting
fixed this on hardware.

## Findings

| Observation | Detail |
| --- | --- |
| Opcodes advertised | `0x9050` EnableEventProc, `0x9052` ExecuteEventProc, `0x9053` GetEventProcReturnData, `0x911D` KeepDeviceOn, `0x9114` SetRemoteMode; `0x9060` IsNeoKabotanProcMode absent |
| Channel check | `FA_GetProperty 0x2000005 0` returned `7.3.0 34(00)` |
| Unknown name | `0x9052` returns `0x201D` (Invalid Parameter); nothing executes |
| `DISP_MuteOnOSDLineVram` | Not registered by name (`0x201D`); the Canon Basic script registers it itself |
| `FA_OSDMuteOn` / `FA_OSDMuteOff` | Registered; `0x2001`; hides/restores the HDMI AF square |
| Plain session (or macOS `ptpcamerad`) | Camera shows the PC-connect laptop icon on HDMI instead of live view |
| Remote-mode session | Live view returns on HDMI; rear LCD stays off while HDMI is connected |

`ExportToEventProcedure` and `CreateProxyOfEventProcedure` are in the ROM and
could register `0xE0538114` directly, but that needs a string parameter whose
PTP encoding is untested on this camera. It was not tried because
`FA_OSDMuteOn` already works.

## Capture resolution

The MacroSilicon HDMI dongle ("USB Video") offers many 4:3 modes (640×480 up
to 1600×1200) alongside 1920×1080, and scales the camera's 16:9 signal into
whichever one an app selects, squeezing the image horizontally. QuickTime's
`High` quality sometimes picks 1280×960; `Maximum` picks 1920×1080 but in the 5 fps uncompressed format (see below).

The active format is shared by every app using the device, so
`usb/capture-format.swift` sets it once for all of them (Zoom included):

```sh
swift usb/capture-format.swift            # list modes and show the active one
swift usb/capture-format.swift 1920x1080  # set 1080p (30 fps by default)
```

`clean-hdmi.sh` compiles this tool to `usb/capture-format` and checks the
format every 5 s while the camera is connected, restoring `CAPTURE_FORMAT`
(default `1920x1080`) only when it differs. This is needed because apps
renegotiate the format on their own: turning the camera off and on in web
Zoom (Chrome) switched the dongle back to a squeezed 4:3 mode. When the size
already matches, the tool exits without touching the device, so a running
stream is not disturbed.

"Matches" means size **and** frame rate. The dongle has two 1920×1080
formats: `420v` (60/30/25/20/10 fps) and uncompressed `yuvs`, limited to
5 fps by USB 2.0. QuickTime's `Maximum` quality selects `yuvs`, which makes
the feed visibly laggy (measured 5 fps); restoring `420v` at 30 fps measured
29–30 fps.

## Connection notes

- On the Apple USB-C Digital AV Multiport Adapter, only the **USB-A** port
  carries data. Its USB-C port is a charging passthrough: neither the camera
  nor the HDMI capture dongle enumerates there. Direct connection to the Mac
  works.
- USB does not power or charge the M50. A flat battery drops both HDMI and USB.
- The M50 disables USB while Wi-Fi is active.

## Safety

`usb/m50ptp.py` can call arbitrary named event procedures. Do not use it for
`EnableBootDisk`/`DisableBootDisk` (persistent boot flag) or for the power-save
procedures that failed under Canon Basic. Only the calls listed above have been
exercised on this camera.

## Tool reference

`usb/m50ptp.py` subcommands: `info`, `session`, `remote`, `enable`, `evproc`,
`keepalive`, `serve FIFO [KEEPALIVE]` with `send FIFO …`, and `run [KEEPALIVE]`.
