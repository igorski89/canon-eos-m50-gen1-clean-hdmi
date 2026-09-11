#!/usr/bin/env python3
"""Compare every regular card file with its backup using SHA-256; never delete."""
import hashlib
import json
from pathlib import Path

CARD = Path('/Volumes/EOS_DIGITAL')
BACKUP = Path('/Users/igorievsiukov/Desktop/EOS_DIGITAL-backup-2026-09-11')
MANIFEST = Path(__file__).with_name('card-backup-verification.json')


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        while block := f.read(4 * 1024 * 1024):
            h.update(block)
    return h.hexdigest()


def main():
    records = []
    paths = sorted(p for p in CARD.rglob('*') if p.is_file())
    for index, source in enumerate(paths, 1):
        relative = source.relative_to(CARD)
        target = BACKUP / relative
        before = source.stat()
        source_hash = digest(source)
        target_hash = digest(target)
        after = source.stat()
        if (before.st_size != after.st_size or before.st_mtime_ns != after.st_mtime_ns
                or source_hash != target_hash or target.stat().st_size != before.st_size):
            raise RuntimeError(f'Backup mismatch or changing source: {relative}')
        records.append({'path': str(relative), 'bytes': before.st_size,
                        'sha256': source_hash})
        print(f'Verified {index}/{len(paths)}: {relative}', flush=True)
    if sorted(p.relative_to(CARD) for p in CARD.rglob('*') if p.is_file()) != [
            p.relative_to(CARD) for p in paths]:
        raise RuntimeError('Card file inventory changed during verification')
    with MANIFEST.open('x') as f:
        json.dump({'card': str(CARD), 'backup': str(BACKUP), 'files': records,
                   'total_bytes': sum(r['bytes'] for r in records)}, f, indent=2)
    print(f'ALL {len(records)} FILES VERIFIED. Manifest: {MANIFEST}', flush=True)


if __name__ == '__main__':
    main()
