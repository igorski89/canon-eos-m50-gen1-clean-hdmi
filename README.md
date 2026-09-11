# Canon EOS M50 (1st gen) clean HDMI research

This repository documents a reversible Canon Basic method for removing the autofocus square from the EOS M50 firmware 1.1.0 HDMI feed while retaining live autofocus.

## Validated result

The camera's HDMI OSD layer can be muted at runtime with Canon's internal routines:

```text
DISP_MuteOnOSDLineVram(0x1000)  @ 0xE0538114
DISP_MuteOffOSDLineVram(0x1000) @ 0xE053814E
```

The validated script is `test_hdmi_line_hold.m`. Copy it to an SD card as `extend.m`, keep `script.req` in the card root, and trigger it with Playback → SET. Return to live view to obtain clean HDMI. Power-cycle the camera afterward to restore the normal overlay.

## Card-format requirement

The working card is FAT32 and has the Canon Basic `SCRIPT` marker in its boot sector. A second 256 GB card formatted in-camera as exFAT accepted the same two files but did not launch `extend.m`; the HDMI AF square remained. Shooting photos and videos on that exFAT card worked normally. Thus, file copying alone is not sufficient: use a FAT32 card prepared with the marker. Do not write the FAT32 marker at the FAT32 offset into an exFAT boot sector.

See [WEBCAM-CLEAN-HDMI.md](WEBCAM-CLEAN-HDMI.md) for the user procedure and recovery steps, and [ASSESSMENT.md](ASSESSMENT.md) for the reverse-engineering evidence and limitations.

## Contents

- `firmware-originals/` — local-only copies of the supplied Canon 1.1.0 firmware files; ignored by Git.
- `M50-ROM0-00000000-00800000.bin` — local-only 8 MiB ROM region read directly from the camera; ignored by Git.
- `test_hdmi_line_hold.m` — validated one-shot clean-HDMI script.
- `cbasic_examples/`, `d8_oracle/`, `magiclantern/` — source snapshots used for research.
- `card-diagnostics-archive-2026-09-11/` — diagnostic outputs retained for provenance.
- `EOS_DIGITAL-original-boot-sector.bin` and card manifests — card-preparation records.

No firmware image was patched or flashed. The method uses runtime Canon Basic code only. The separate 30 GB photo backup is intentionally not included in this repository. Proprietary firmware and ROM binaries are deliberately excluded from commits; obtain firmware from [Canon's official EOS M50 download page](https://www.canon-europe.com/support/consumer/products/cameras/eos-m/eos-m50.html?type=firmware) and generate ROM dumps locally if needed.

## Integrity

The original firmware hashes and ROM-dump hash are recorded in `ASSESSMENT.md`. Generated research files are retained rather than silently discarded so the investigation is reproducible.

## Licensing

Original scripts, documentation, and analysis code in this repository are released under the MIT License; see [LICENSE](LICENSE). The Canon firmware/ROM files are local-only and excluded from Git. Vendored source snapshots under `magiclantern/`, `cbasic_examples/`, `d8_oracle/`, and `third_party/` retain their original upstream licenses and are not relicensed by this repository.
