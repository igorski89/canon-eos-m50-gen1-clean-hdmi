# Card preparation, 2026-09-11

- Canon Basic file-writing test succeeded on the user's M50: `M50TEST.TXT` contains the expected 41 bytes. The user entered playback from a grid and pressed SET once.
- Full card file backup: `/Users/igorievsiukov/Desktop/EOS_DIGITAL-backup-2026-09-11`.
- All 45 regular files (31,882,703,951 bytes) matched their backup by SHA-256. See `card-backup-verification.json`. Empty directories were also copied by rsync. This is a file backup, not a whole-card image.
- Removed only `DCIM/100CANON/MVI_0314.MP4` from the card after full verification. Its 1,392,637,160-byte backup remains in the matching Desktop backup location and can be copied back.
- Card free space after removal: 1,411,284,992 bytes, approximately 1.4 GB.
- Replaced the card's `extend.m` with `extend-rom-dump.m`; byte-for-byte comparison passed. The prior test script is retained in the full backup.
- SCRIPT marker was previously written and read-back verified by the user-run helper. Original primary partition boot sector: `EOS_DIGITAL-original-boot-sector.bin`.
- Next hardware run should create `M50DUMP.LOG`, invoke `SaveAllRomImageToFile()`, then create `M50DONE.TXT` if the routine returns. Neither marker proves a valid ROM dump; inspect generated binary files afterward.
- The export routine remains untested on this camera. No firmware-update procedure or boot-flag change is part of this script.

## ROM export attempt result

On the next return, both `M50DUMP.LOG` and `M50DONE.TXT` contained their expected messages, but no ROM dump was found. This establishes that script execution reached the end, not that the export succeeded. The return code was not captured, so the cause remains unknown.

Both status names appeared three times in the root directory. The M50 development thread (topic 23296, page starting at 225, msg227190) reports that repeated Canon Basic file creation can produce duplicate names. A read-only `diskutil verifyVolume` invoked `fsck_msdos -n` and returned exit code 0. No repair or deletion of those entries was performed.

The card's `extend.m` was replaced with a small hex-dump test based on the SRSA method linked by `cbasic_examples/Universal/extend_dump_hex.m`. It first read 64 KiB at `0xe0040000`, then successfully read 8 MiB at `0xe0000000` and wrote `M50ROM0A.TXT` (262,144 valid lines). The reconstructed binary is saved as `m50-firmware-analysis/M50-ROM0-00000000-00800000.bin`, SHA-256 `88455fbca0ff445e770f95f1208652d1eba90b3d4bea7235c7121b3e9e0baa90`. Each 8-character word is packed little-endian when reconstructing the binary.

The replacement removes only its own experiment output before creating it and uses an in-memory guard against repeated Initialize calls in the same interpreter lifetime. Hardware execution remains pending; firmware memory is only read.
