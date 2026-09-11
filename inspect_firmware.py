#!/usr/bin/env python3
"""Read-only inspection of the supplied M50 FIR container; does not decrypt it."""
import argparse
import hashlib
import json
import math
import struct
from collections import Counter
from pathlib import Path


def entropy(data):
    counts = Counter(data)
    return round(-sum((n / len(data)) * math.log2(n / len(data))
                      for n in counts.values()), 6) if data else 0


def inspect(fir_path, dat_path):
    data = fir_path.read_bytes()
    if len(data) < 0x120:
        raise ValueError("File too short for expected M50 container")
    u32 = lambda offset: struct.unpack_from('<I', data, offset)[0]
    if u32(0) != 0x412 or u32(0x24) != 0xB0:
        raise ValueError("Not the expected M50 container layout")
    payload = u32(0x30)
    if not 0x120 <= payload <= len(data) - 12:
        raise ValueError("Invalid payload header offset")
    enc_header = payload + u32(payload)
    enc_start = payload + u32(payload + 4)
    end = payload + u32(payload + 8)
    if not payload <= enc_header <= enc_start <= end == len(data):
        raise ValueError("Invalid payload bounds")
    stored = u32(0x20)
    computed = (~(sum(data[:0x20]) + sum(data[0x24:]))) & 0xFFFFFFFF
    result = {
        'fir': str(fir_path), 'bytes': len(data),
        'sha256': hashlib.sha256(data).hexdigest(),
        'model_id': hex(u32(0)),
        'version': data[0x10:0x20].split(b'\0')[0].decode('ascii'),
        'declared_size_matches': u32(0x38) == len(data),
        'checksum_stored': hex(stored), 'checksum_computed': hex(computed),
        'checksum_matches': stored == computed,
        'updater_header': hex(u32(0x24)), 'updater_start': hex(u32(0x28)),
        'updater_encrypted_length': hex(u32(u32(0x24))),
        'payload_header': hex(payload), 'payload_crypto_header': hex(enc_header),
        'payload_start': hex(enc_start), 'payload_end': hex(end),
        'payload_encrypted_length': hex(u32(enc_header)),
        'payload_entropy_bits_per_byte': entropy(data[enc_start:end]),
        'note': 'Entropy alone does not establish encryption. Layout interpretation follows fir_tool2.py.',
    }
    companion = dat_path.read_bytes()
    result['dat'] = {
        'path': str(dat_path), 'bytes': len(companion),
        'sha256': hashlib.sha256(companion).hexdigest(),
        'entropy_bits_per_byte': entropy(companion),
        'interpretation': 'Role and encoding not established by this inspection.'
    }
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fir', type=Path)
    parser.add_argument('dat', type=Path)
    args = parser.parse_args()
    print(json.dumps(inspect(args.fir, args.dat), indent=2))
