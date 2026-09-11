#!/usr/bin/env python3
"""Enable SCRIPT on the identified EOS_DIGITAL card; no formatting or deletion.

Reference: https://chdk.fandom.com/wiki/Canon_Basic/Card_Setup
Changes bytes 496..501 of the primary FAT32 partition boot sector only.
Run with sudo after reviewing. A backup is saved next to this script.
"""
import os
import plistlib
import subprocess
from pathlib import Path

VOLUME = '/Volumes/EOS_DIGITAL'
EXPECTED_UUID = '1A7B6ABD-B53C-36F8-860D-C2809102AF56'
EXPECTED_OFFSET = 4194304
EXPECTED_SIZE = 31910789120
BACKUP = Path(__file__).resolve().parent / 'EOS_DIGITAL-original-boot-sector.bin'


def info(target):
    return plistlib.loads(subprocess.check_output(
        ['/usr/sbin/diskutil', 'info', '-plist', target]))


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(os.geteuid() == 0, 'Administrator access required: run with sudo.')
    part = info(VOLUME)
    require(part.get('VolumeUUID') == EXPECTED_UUID, 'Wrong card UUID; stopping.')
    require(part.get('FilesystemType') == 'msdos', 'Expected FAT filesystem.')
    require(part.get('PartitionMapPartitionOffset') == EXPECTED_OFFSET,
            'Unexpected partition offset.')
    require(part.get('Size') == EXPECTED_SIZE, 'Unexpected partition size.')
    require(part.get('DeviceBlockSize') == 512, 'Expected 512-byte sectors.')
    require(part.get('Writable') is True, 'Card is not writable.')
    whole_id = part['ParentWholeDisk']
    whole = info('/dev/' + whole_id)
    require(whole.get('BusProtocol') == 'Secure Digital', 'Expected SD reader.')
    require(whole.get('RemovableMedia') is True, 'Expected removable media.')
    require(whole_id.startswith('disk') and whole_id[4:].isdigit(), 'Bad disk ID.')
    partition_node = part['DeviceNode']
    raw = '/dev/r' + whole_id
    print('Verified card:', partition_node, EXPECTED_UUID, flush=True)
    subprocess.run(['/usr/sbin/diskutil', 'unmount', partition_node], check=True)
    try:
        with open(raw, 'r+b', buffering=0) as disk:
            disk.seek(EXPECTED_OFFSET)
            original = disk.read(512)
            require(len(original) == 512, 'Short sector read.')
            require(original[510:512] == b'\x55\xaa', 'Invalid boot signature.')
            require(original[82:90] == b'FAT32   ', 'Not a FAT32 boot sector.')
            require(original[11:13] == b'\x00\x02', 'Invalid sector size in BPB.')
            if original[496:502] == b'SCRIPT':
                print('SCRIPT marker is already present; no write needed.')
                return
            require(original[496:502] == bytes(6),
                    'Marker location is not empty; manual review required.')
            require(not BACKUP.exists(), 'Backup exists; review before retrying.')
            with BACKUP.open('xb') as backup:
                backup.write(original)
                backup.flush()
                os.fsync(backup.fileno())
            patched = bytearray(original)
            patched[496:502] = b'SCRIPT'
            disk.seek(EXPECTED_OFFSET)
            require(disk.write(patched) == 512, 'Incomplete sector write.')
            os.fsync(disk.fileno())
            disk.seek(EXPECTED_OFFSET)
            require(disk.read(512) == patched, 'Read-back verification failed.')
            print('SCRIPT marker written and verified. Backup:', BACKUP)
    finally:
        subprocess.run(['/usr/sbin/diskutil', 'mount', partition_node], check=True)


if __name__ == '__main__':
    main()
