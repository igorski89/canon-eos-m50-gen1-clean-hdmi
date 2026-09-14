# Native payload feasibility: EOS M50 1.1.0

Status: **architecturally plausible; bootstrap not yet proven; do not deploy.**

## What "native payload" means

This is not a modified Canon firmware image. It would be a Magic-Lantern-style
`AUTOEXEC.BIN` on an SD card. If Canon's boot flag is enabled and the card has
the `BOOTDISK` marker, Canon's loader copies the payload to RAM and transfers
control. The payload can then allow Canon to boot and later run a small
background task.

The M50 ROM contains `AUTOEXEC.BIN`, `BOOTDISK`, `EnableBootDisk`, and
`DisableBootDisk` strings. The local M50.110 platform configuration also sets
`AUTOEXEC_BASE = 0x800000`, uses `boot-d678.o`, and includes a boot-flag menu
feature. These are positive architectural signals.

## Blocking bootstrap gap

The local source tree has no `installer/M50.110/` target. In
`platform/M50.110/Makefile`, the M50 Canon-FIR and update-name fields are
commented out. Therefore this repository has an M50 payload build
configuration, but does not contain a validated 1.1.0 installation path for
enabling the persistent camera boot flag.

Online development material documents an M50 boot-flag FIR for firmware 1.0.1
and later M50 payload work only after boot-flag activation via UART; neither
is evidence of a safe 1.1.0 installer. Official Magic Lantern downloads also
do not list the M50 as a released supported build.

## Why Canon Basic is not a bootstrap solution yet

Canon Basic can run the validated HDMI routine, and the ROM exposes the named
`EnableBootDisk` event. It is tempting to call that event from a script.
However, `ExecuteEventProcedure("DisablePowerSave")` failed on this camera and
the boot flag is persistent. Enabling it through an unvalidated script would
be a material risk, not an ordinary reversible test.

## Recovery model and prerequisites

An SD-card image restores the card only; it cannot restore the camera's
nonvolatile boot flag. Before any bootstrap test, retain:

1. the current known-good clean-HDMI card, untouched;
2. a raw, sector-level image of it;
3. a separate sacrificial test card;
4. a separate ordinary card with no BOOTDISK marker or payload;
5. a charged battery, card reader, and official Canon 1.1.0 updater.

With a boot flag enabled, a normal card without boot markers should boot the
stock firmware. A marked card with a missing/bad `AUTOEXEC.BIN` may hang until
the battery is removed and the card is repaired or reformatted externally.
Do not assume reflashing Canon firmware clears the boot flag.

## Gated development plan

1. Establish a documented, reversible 1.1.0 boot-flag method on a sacrificial
   card; do not modify the production card.
2. Boot a payload that only writes a log or flashes a harmless indicator.
3. Verify repeated boot, no-card boot, normal-card boot, and recovery after a
   deliberately malformed payload.
4. Add a native diagnostic task, with crash logging, around the display
   power-save controller.
5. Only after those pass, add a periodic timer-reset call and perform long
   HDMI, thermal, autofocus, and recovery tests.

This work has not begun on hardware. No native payload, BOOTDISK marker, or
camera boot flag has been installed or changed.

## External references

- [Magic Lantern boot architecture](https://github.com/reticulatedpines/magiclantern_simplified/blob/dev/developer_guide/03_00_architecture.md)
- [M50 DIGIC 8 development discussion](https://www.magiclantern.fm/forum/index.php?topic=23296.75)
- [Official Magic Lantern download list](https://builds.magiclantern.fm/index.html)
