#!/usr/bin/env python3
"""Disassemble a range of the locally dumped M50 ROM0 in Thumb mode."""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).with_name('third_party')))
from capstone import Cs, CS_ARCH_ARM, CS_MODE_THUMB

ROM_BASE = 0xE0000000

parser = argparse.ArgumentParser()
parser.add_argument('binary', type=Path)
parser.add_argument('address', type=lambda s: int(s, 0))
parser.add_argument('--length', type=lambda s: int(s, 0), default=0x100)
args = parser.parse_args()

data = args.binary.read_bytes()
offset = args.address - ROM_BASE
if offset < 0 or offset + args.length > len(data):
    raise SystemExit('Requested range is outside the local ROM dump')

engine = Cs(CS_ARCH_ARM, CS_MODE_THUMB)
engine.detail = True
for instruction in engine.disasm(data[offset:offset + args.length], args.address):
    print(f'{instruction.address:08x}: {instruction.bytes.hex():<12} '
          f'{instruction.mnemonic:<8} {instruction.op_str}')
