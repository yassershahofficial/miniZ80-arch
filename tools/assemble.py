#!/usr/bin/env python3
"""Minimal Z80-style assembler for miniZ80."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from opcodes import HALT, LD_A_N, NOP, ROM_ORIGIN

FIRMWARE_DIR = Path("firmware")

RE_COMMENT = re.compile(r";.*$")

REGS = {
    "b": 0,
    "c": 1,
    "d": 2,
    "e": 3,
    "h": 4,
    "l": 5,
    "(hl)": 6,
    "a": 7,
}

PAIRS = {
    "bc": 0x01,
    "de": 0x11,
    "hl": 0x21,
    "sp": 0x31,
}

ALU_OPS = {
    "add": (0x80, 0xC6),
    "sub": (0x90, 0xD6),
    "and": (0xA0, 0xE6),
    "xor": (0xA8, 0xEE),
    "or":  (0xB0, 0xF6),
    "cp":  (0xB8, 0xFE),
}

INC_RP = {"bc": 0x03, "de": 0x13, "hl": 0x23, "sp": 0x33}
DEC_RP = {"bc": 0x0B, "de": 0x1B, "hl": 0x2B, "sp": 0x3B}

PUSH = {"bc": 0xC5, "de": 0xD5, "hl": 0xE5, "af": 0xF5}
POP  = {"bc": 0xC1, "de": 0xD1, "hl": 0xE1, "af": 0xF1}

ROTATE = {"rlca": 0x07, "rrca": 0x0F, "rla": 0x17, "rra": 0x1F}

JR_COND = {
    "nz": 0x20,
    "z":  0x28,
    "nc": 0x30,
    "c":  0x38,
}

CALL_COND = {
    "nz": 0xC4,
    "z":  0xCC,
    "nc": 0xD4,
    "c":  0xDC,
}

RET_COND = {
    "nz": 0xC0,
    "z":  0xC8,
    "nc": 0xD0,
    "c":  0xD8,
}


def parse_number(token: str) -> int:
  token = token.strip()
  if token.startswith("0x") or token.startswith("0X"):
      value = int(token, 16)
  elif token.lower().endswith("h"):
      value = int(token[:-1], 16)
  else:
      value = int(token, 10)
  if not 0 <= value <= 0xFF:
      raise ValueError(f"8-bit value out of range: {token}")
  return value


def parse_number16(token: str) -> int:
  token = token.strip()
  if token.startswith("0x") or token.startswith("0X"):
      value = int(token, 16)
  elif token.lower().endswith("h"):
      value = int(token[:-1], 16)
  else:
      value = int(token, 10)
  if not 0 <= value <= 0xFFFF:
      raise ValueError(f"16-bit value out of range: {token}")
  return value


def reg_index(name: str) -> int:
  key = name.strip().lower()
  if key not in REGS:
      raise ValueError(f"unknown register: {name}")
  return REGS[key]


def parse_org(line: str) -> int | None:
  parts = line.split()
  if len(parts) >= 2 and parts[0].lower() == ".org":
      return int(parts[1], 0)
  return None


def encode_ld(parts: list[str], line_no: int) -> list[int]:
  if len(parts) < 3:
      raise ValueError(f"line {line_no}: ld needs destination and source")

  dest = parts[1].lower()
  src = parts[2].lower()

  # LD rp,nn
  if dest in PAIRS and src not in REGS:
      nn = parse_number16(parts[2])
      return [PAIRS[dest], nn & 0xFF, (nn >> 8) & 0xFF]

  # LD A,n
  if dest == "a" and src not in REGS:
      return [LD_A_N, parse_number(parts[2])]

  # LD r,n
  if src not in REGS:
      d = reg_index(dest)
      return [0x06 | (d << 3), parse_number(parts[2])]

  # LD r,r'
  d = reg_index(dest)
  s = reg_index(src)
  return [0x40 | (d << 3) | s]


def encode_alu(parts: list[str], line_no: int) -> list[int]:
  if len(parts) < 2:
      raise ValueError(f"line {line_no}: {parts[0]} needs operands")

  op = parts[0].lower()
  if op not in ALU_OPS:
      raise ValueError(f"line {line_no}: unknown ALU op: {op}")

  reg_base, imm_op = ALU_OPS[op]

  if len(parts) == 2 and parts[1].lower() not in REGS:
      return [imm_op, parse_number(parts[1])]

  if len(parts) >= 3:
      dest = parts[1].lower()
      src = parts[2].lower()
      if dest != "a":
          raise ValueError(f"line {line_no}: {op} only supports A as destination")
      if src in REGS:
          return [reg_base | reg_index(src)]
      return [imm_op, parse_number(parts[2])]

  raise ValueError(f"line {line_no}: invalid {op} operands")


def parse_signed8(token: str) -> int:
  token = token.strip()
  if token.startswith("-") or token.startswith("+"):
      value = int(token, 10)
  else:
      value = parse_number(token)
      if value > 127:
          value -= 256
  if not -128 <= value <= 127:
      raise ValueError(f"signed 8-bit value out of range: {token}")
  return value


def signed8_byte(value: int) -> int:
  return value & 0xFF


def encode_push_pop(parts: list[str], line_no: int) -> list[int]:
  if len(parts) < 2:
      raise ValueError(f"line {line_no}: {parts[0]} needs register pair")

  op = parts[0].lower()
  pair = parts[1].lower()
  table = PUSH if op == "push" else POP
  if pair not in table:
      raise ValueError(f"line {line_no}: unknown pair for {op}: {pair}")
  return [table[pair]]


def encode_branch(parts: list[str], line_no: int) -> list[int]:
  mnemonic = parts[0].lower()

  if mnemonic == "jp":
      if len(parts) < 2:
          raise ValueError(f"line {line_no}: jp needs address")
      nn = parse_number16(parts[1])
      return [0xC3, nn & 0xFF, (nn >> 8) & 0xFF]

  if mnemonic == "jr":
      if len(parts) < 2:
          raise ValueError(f"line {line_no}: jr needs displacement or condition")
      if parts[1].lower() in JR_COND:
          cond = parts[1].lower()
          if len(parts) < 3:
              raise ValueError(f"line {line_no}: jr {cond} needs displacement")
          e = signed8_byte(parse_signed8(parts[2]))
          return [JR_COND[cond], e]
      e = signed8_byte(parse_signed8(parts[1]))
      return [0x18, e]

  if mnemonic == "call":
      if len(parts) < 2:
          raise ValueError(f"line {line_no}: call needs address or condition")
      if parts[1].lower() in CALL_COND:
          cond = parts[1].lower()
          if len(parts) < 3:
              raise ValueError(f"line {line_no}: call {cond} needs address")
          nn = parse_number16(parts[2])
          return [CALL_COND[cond], nn & 0xFF, (nn >> 8) & 0xFF]
      nn = parse_number16(parts[1])
      return [0xCD, nn & 0xFF, (nn >> 8) & 0xFF]

  if mnemonic == "ret":
      if len(parts) == 1:
          return [0xC9]
      cond = parts[1].lower()
      if cond not in RET_COND:
          raise ValueError(f"line {line_no}: unknown ret condition: {cond}")
      return [RET_COND[cond]]

  if mnemonic == "djnz":
      if len(parts) < 2:
          raise ValueError(f"line {line_no}: djnz needs displacement")
      e = signed8_byte(parse_signed8(parts[1]))
      return [0x10, e]

  raise ValueError(f"line {line_no}: unknown branch: {mnemonic}")


def encode_rotate_flag(parts: list[str], line_no: int) -> list[int]:
  mnemonic = parts[0].lower()
  if mnemonic in ROTATE:
      return [ROTATE[mnemonic]]
  if mnemonic == "scf":
      return [0x37]
  if mnemonic == "ccf":
      return [0x3F]
  raise ValueError(f"line {line_no}: unknown instruction: {mnemonic}")


def encode_inc_dec(parts: list[str], line_no: int) -> list[int]:
  if len(parts) < 2:
      raise ValueError(f"line {line_no}: {parts[0]} needs operand")

  op = parts[0].lower()
  reg = parts[1].lower()

  if reg in INC_RP:
      table = INC_RP if op == "inc" else DEC_RP
      return [table[reg]]

  if reg in REGS:
      base = 0x04 if op == "inc" else 0x05
      return [base | (reg_index(reg) << 3)]

  raise ValueError(f"line {line_no}: unknown inc/dec operand: {reg}")


def encode_line(line: str, line_no: int) -> list[int]:
  line = RE_COMMENT.sub("", line).strip()
  if not line:
      return []

  org = parse_org(line)
  if org is not None:
      if org != ROM_ORIGIN:
          raise ValueError(f"line {line_no}: only .org 0x0000 supported for now")
      return []

  parts = [p.strip() for p in line.replace(",", " ").split()]
  mnemonic = parts[0].lower()

  if mnemonic == ".db":
      return [parse_number(p) for p in parts[1:]]

  if mnemonic == "nop":
      return [NOP]
  if mnemonic == "halt":
      return [HALT]
  if mnemonic == "ld":
      return encode_ld(parts, line_no)
  if mnemonic in ALU_OPS:
      return encode_alu(parts, line_no)
  if mnemonic in ("inc", "dec"):
      return encode_inc_dec(parts, line_no)
  if mnemonic in ("push", "pop"):
      return encode_push_pop(parts, line_no)
  if mnemonic in ("jp", "jr", "call", "ret", "djnz"):
      return encode_branch(parts, line_no)
  if mnemonic in ROTATE or mnemonic in ("scf", "ccf"):
      return encode_rotate_flag(parts, line_no)

  raise ValueError(f"line {line_no}: unknown instruction: {line}")


def assemble(source: str) -> list[int]:
  image: list[int] = []
  for line_no, line in enumerate(source.splitlines(), start=1):
      image.extend(encode_line(line, line_no))
  return image


def write_bin(path: Path, data: list[int]) -> None:
  path.write_bytes(bytes(data))


def write_hex(path: Path, data: list[int], origin: int = ROM_ORIGIN) -> None:
  """Write $readmemh-compatible hex (iverilog / Verilog simulators)."""
  lines = [f"@{origin:08X}"]
  for i in range(0, len(data), 16):
      chunk = data[i : i + 16]
      lines.append(" ".join(f"{b:02X}" for b in chunk))
  path.write_text("\n".join(lines) + "\n")


def main() -> int:
  parser = argparse.ArgumentParser(description="Assemble .asm to firmware image")
  parser.add_argument("input", type=Path, help="Source .asm file")
  parser.add_argument("-o", "--output", type=Path, help="Output .bin (default: firmware/<stem>.bin)")
  args = parser.parse_args()

  source = args.input.read_text()
  try:
      data = assemble(source)
  except ValueError as exc:
      print(exc, file=sys.stderr)
      return 1

  out_bin = args.output or FIRMWARE_DIR / f"{args.input.stem}.bin"
  out_hex = out_bin.with_suffix(".hex")
  out_bin.parent.mkdir(parents=True, exist_ok=True)

  write_bin(out_bin, data)
  write_hex(out_hex, data)
  print(f"wrote {out_bin} ({len(data)} bytes)")
  print(f"wrote {out_hex}")
  return 0


if __name__ == "__main__":
  sys.exit(main())
