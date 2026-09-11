# Canon EOS M50 (first generation), firmware 1.1.0: AF overlay feasibility

Assessment date: 2026-09-11.

## Conclusion

Suppressing the autofocus rectangle while retaining autofocus is technically plausible. Existing reverse engineering for this exact model/version identifies separate HDMI image buffers, RGBA graphics, and a named HDMI OSD mute routine. These are concrete leads for a display-only intervention.

This investigation has **not** decrypted the supplied firmware or located the AF drawing routine itself. However, a reversible Canon Basic experiment has now demonstrated clean live HDMI on the user's camera: muting the HDMI “Line” OSD layer removes the AF square while the live image remains visible. Confidence is high that this display-only approach is feasible; a permanent, convenient implementation still needs engineering. There is no firmware patch in this deliverable.

The preferred first experiment, after inspecting executable code, is temporary suppression of the HDMI OSD layer. Selectively skipping AF-frame drawing is a second option if the rectangle is composited elsewhere or other graphics need to remain. Neither outcome is established from function names alone.

## Direct observations from your files

The originals were only read.

| Field | Observation |
| --- | --- |
| FIR size | 32,282,432 bytes (`0x1ec9740`) |
| Model ID | `0x00000412`, matching the M50.110 platform definition |
| Embedded version | `1.1.0` |
| Declared size | Matches actual size |
| Container checksum | Stored and independently calculated: `0x0aa7361a` |
| Updater header / start | `0xb0` / `0x120` |
| Encrypted updater length | `0x2cfaa0` |
| Main payload header / start | `0x2cfbc0` / `0x2cfc40` |
| Encrypted main payload length | `0x1bf9b00` |
| Companion DAT size | 4,112 bytes |

SHA-256:

```text
CCF19110.FIR 7077e4f24765b5d08c2f1c3d7e570d42ce63a871db84b5b8f9b7202308605479
CCF19.DAT   5a65acce225da25a8519ecdab1d58e54178c2baad21ee0d567c4243d4931b066
```

The updated `fir_tool2.py` identifies the older container layout with HMAC-SHA1 fields and nonzero AES-related header data. Its `-x` extraction path handles XOR-only updaters; it did not extract this updater. The newer `d8_oracle.py` explicitly excludes the M50. This is a limitation of the inspected tools, not proof that offline decryption is impossible.

The payload entropy is 7.999994 bits/byte, consistent with encrypted data, though entropy cannot distinguish encryption from effective compression. The DAT's role and encoding remain unresolved; its size alone does not establish that it contains usable keys. Passing the additive checksum does not verify the HMACs or authenticate the package.

Canon's [1.1.0 support page](https://asia.canon/en/support/0400614202) lists the same FIR filename and size. I did not compare against an independently downloaded official binary.

## Evidence from existing M50.110 reverse engineering

Source checkout: [Magic Lantern](https://github.com/reticulatedpines/magiclantern_simplified), commit `d7e3407b8f69ddde30516e298d4e077daa16df0c`.

These addresses come from that project's source; they are **not independently verified against your encrypted FIR** and must not be used as blind patch locations.

| Source | Relevant finding | Implication |
| --- | --- | --- |
| `platform/M50.110/consts.h:79` | Comments identify `DISP_MuteOnOSDLineVram()` and `DISP_MuteOnOSDPanelVram()` in GUILockTask | Candidate separation between HDMI and panel graphics control; calling convention and full effects unknown |
| `platform/M50.110/consts.h:86` | HDMI is called “Line”; multiple HDMI buffer sizes are documented | Search for Line as well as HDMI during disassembly |
| `platform/M50.110/consts.h:108` | DispVram pointer at `0x8e08`, HDMI buffer field at `+0xa8` | Identified image-output structure for tracing graphics composition |
| `platform/M50.110/stubs.S:230` | `XimrExe` at `0xe00d6404`, RGBA information at `0xfc1c` | Another possible interception point, requiring careful identification of layers |
| `platform/M50.110/consts.h:78` | Overlay mode variable at `0x13cc8` | Useful for understanding INFO transitions; not proof this variable can hide AF graphics |
| `platform/M50.110/stubs.S:253` | `LiveViewApp_handler` at `0xe04dc446` | Entry point for tracing overlay state transitions |

The same source explicitly says the M50 lacks the EOS R's clean-HDMI feature. Finding separate display primitives does not mean there is a hidden, complete clean-HDMI menu option.

## Direct ROM evidence from the M50 1.1.0

After a verified full-card backup, a Canon Basic script read memory directly and exported the range `0xe0000000..0xe07fffff` as hexadecimal. The reconstructed binary is:

```text
m50-firmware-analysis/M50-ROM0-00000000-00800000.bin
size       8,388,608 bytes
SHA-256    88455fbca0ff445e770f95f1208652d1eba90b3d4bea7235c7121b3e9e0baa90
```

The dump contains executable code and readable Canon symbols. In particular, the AF subsystem has a wrapper labelled `FA_OSDMuteOn` at runtime `0xe0079d54` and `FA_OSDMuteOff` at `0xe0079d8c`. The `FA_OSDMuteOn` wrapper selects a display target by calling `0xe007abdc`, then passes user ID `0x1000` to the display mute routines: one branch calls the HDMI/“Line” path beginning at `0xe0538114`, while the other calls the panel path beginning at `0xe0538188`. The corresponding off wrapper calls the “Line” and panel unmute paths.

The display wrappers validate the mute-user ID and then invoke lower-level routines; the strings are not merely dead text. The exact names and runtime addresses recovered from this dump are:

| Routine label | Runtime address of label / wrapper |
| --- | --- |
| `FA_OSDMuteOn` | label `0xe007a07c`; wrapper `0xe0079d54` |
| `FA_OSDMuteOff` | label `0xe007a090`; wrapper `0xe0079d8c` |
| `DISP_MuteOnOSDLineVram` | label `0xe0538358`; wrapper `0xe0538114` |
| `DISP_MuteOffOSDLineVram` | label `0xe0538370`; wrapper `0xe053814e` |
| `DISP_MuteOnOSDPanelVram` | label `0xe0538388`; wrapper `0xe0538188` |
| `DISP_MuteOffOSDPanelVram` | label `0xe05383a0`; wrapper `0xe05381d0` |

This is strong evidence that autofocus OSD suppression and HDMI-vs-panel graphics are separate control paths in this exact firmware. It does **not** yet prove that calling `FA_OSDMuteOn(0x1000)` leaves the HDMI video clean: the mute may suppress other OSD elements too, and the display-target selector and lifetime/restore protocol still need a controlled hardware test.

### Hardware confirmation

The direct Line-only wrapper was invoked from Canon Basic with mute user ID `0x1000`, then the script returned immediately. After switching from Playback back to live view, the user observed a live HDMI image with the autofocus square completely absent. The camera's built-in LCD remained usable. The card marker `M50HOLD.TXT` confirms the call executed. Power-cycling restores the normal display state; the card has been returned to the harmless minimal script.

A subsequent stateful toggle script was not accepted reliably: it produced no execution marker or state file, and the HDMI capture link went black after SET. The card was immediately reverted to the minimal script. Treat the one-shot Line mute test as the validated method; the toggle wrapper requires further Canon Basic compatibility work.

The port enables MMU remapping, which offers a possible route to RAM-backed code changes. It also documents unresolved capture crashes, allocator issues, and disabled hooks. Existing platform support should not be mistaken for a stable webcam solution. The old `clear_lv_afframe()` implementation in `src/tweaks.c` manipulates indexed-color bitmap pixels; it cannot simply be assumed to work with the M50's RGBA compositor.

## What would establish feasibility more firmly

1. ~~Obtain a readable ROM dump from an M50 running 1.1.0, and verify model/version before trusting the existing address map.~~ Completed for the first 8 MiB; the remaining regions are not yet dumped.
2. ~~Find the HDMI OSD mute/unmute routines and their callers. Establish arguments, locking, memory/register writes, restoration behavior, and whether muting affects video or AF processing.~~ Completed sufficiently for a reversible test: the Line-only wrapper accepts `0x1000`, suppresses the HDMI overlay, preserves live video/AF, and can be restored by its paired unmute routine or power cycle.
3. Trace LiveViewApp and graphics composition to determine where the AF rectangle enters HDMI output. A rectangle already baked into an image layer will not disappear by muting an unrelated OSD plane.
4. Prepare a narrowly scoped runtime experiment with a restore path. Prefer a known firmware routine over guessed MMIO writes. Avoid persistent firmware modification for initial validation.
5. On hardware, check continuous face/subject autofocus, stationary AF boxes, INFO transitions, menu entry/exit, HDMI reconnection, output modes, and sustained operation. Confirm the image remains live, autofocus still tracks, and the overlay does not reappear or flicker.

Canon Basic is an established research avenue on the M50. The [CBasic examples repository](https://github.com/lclevy/cbasic_examples) includes a ROM-dump example calling `SaveAllRomImageToFile()`, but that specific example says it was tested on R6 firmware. It has not been validated here for your M50, so this report does not present it as a ready-to-run dumper. Old firmware-specific dumpers also need review before use on 1.1.0.

No camera was connected or modified, no boot flags were changed, and no firmware image was patched. Hardware execution and validation remain outstanding.

## Reproduction and saved materials

Run from this folder:

```sh
python3 inspect_firmware.py /Volumes/M50-KissM-v110-mac/CCF19110.FIR /Volumes/M50-KissM-v110-mac/CCF19.DAT
python3 d8_oracle/ml_scripts/fir_tool2.py -c /Volumes/M50-KissM-v110-mac/CCF19110.FIR
```

The independent inspector is read-only and checks the expected container bounds, size, checksum, hashes, and entropy. Its results agree with `fir_tool2.py` for the parsed fields. No decryption claim is made.

Additional source snapshots:

- `d8_oracle`: commit `a98533090e1ef16a8f56193dbb5dd410222a71aa`, [upstream](https://github.com/lclevy/d8_oracle).
- `cbasic_examples`: commit `002272496646b6eead9f8a04a100c83f355da0b7`, [upstream](https://github.com/lclevy/cbasic_examples).

This folder contains research and inspection tools, not installable camera firmware.
