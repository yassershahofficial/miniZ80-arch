# Instruction Set Architecture

Reduced Z80-style ISA for miniZ80. All instructions use **no prefix** (no CB, ED, DD, FD). Opcodes match the standard Z80 where included.

**Total: 186 encodings**

---

## Memory map

| Region | Start  | Size   | Notes                          |
|--------|--------|--------|--------------------------------|
| ROM    | 0x0000 | TBD    | Programs load at reset (PC=0)  |

RAM and peripherals TBD.

---

## Registers

| Name | Width | Role                                      |
|------|-------|-------------------------------------------|
| A    | 8     | Accumulator                               |
| F    | 8     | Flags (see below)                         |
| B, C | 8     | General purpose; pair as **BC**           |
| D, E | 8     | General purpose; pair as **DE**           |
| H, L | 8     | General purpose; pair as **HL**           |
| AF   | 16    | A (high) + F (low)                        |
| BC   | 16    | B (high) + C (low)                        |
| DE   | 16    | D (high) + E (low)                        |
| HL   | 16    | H (high) + L (low); primary memory pointer|
| SP   | 16    | Stack pointer                             |
| PC   | 16    | Program counter                           |

### Flags (F register)

| Bit | Name | Meaning                          |
|-----|------|----------------------------------|
| 7   | S    | Sign (result bit 7 set)          |
| 6   | Z    | Zero (result = 0)                |
| 5   | —    | Unused (read as 0)               |
| 4   | H    | Half-carry (bit 3 overflow)      |
| 3   | —    | Unused (read as 0)               |
| 2   | P/V  | Parity / overflow (instruction-dependent) |
| 1   | N    | Subtract (last op was subtraction)|
| 0   | C    | Carry                            |

Lower 5 bits of F are not all used by every instruction; unused bits are unaffected or forced to 0 per standard Z80 rules.

---

## Operand notation

| Symbol | Meaning                    |
|--------|----------------------------|
| r, r'  | One of B, C, D, E, H, L, A |
| (HL)   | Byte at address in HL      |
| nn     | 16-bit immediate (little-endian) |
| n      | 8-bit immediate            |
| e      | 8-bit signed displacement (PC-relative) |

Register encoding (used in opcode tables):

| r / rp | Code | rp pair |
|--------|------|---------|
| B      | 000  | BC      |
| C      | 001  | DE      |
| D      | 010  | HL      |
| E      | 011  | SP      |
| H      | 100  |         |
| L      | 101  |         |
| (HL)   | 110  |         |
| A      | 111  |         |

---

## Instruction summary

| Category              | Count |
|-----------------------|-------|
| LD r,r'               | 63    |
| LD r,n / LD (HL),n    | 8     |
| LD rp,nn              | 4     |
| ADD / SUB / AND / OR / XOR / CP A,r | 48 |
| ADD / SUB / AND / OR / XOR / CP A,n | 6  |
| INC / DEC r           | 16    |
| INC / DEC rp          | 8     |
| PUSH / POP            | 8     |
| JP nn                 | 1     |
| JR / JR cc            | 5     |
| CALL / CALL cc        | 5     |
| RET / RET cc          | 5     |
| DJNZ e                | 1     |
| RLCA / RRCA / RLA / RRA | 4   |
| NOP / HALT / SCF / CCF | 4    |
| **Total**             | **186** |

---

## Instruction fetch, length, and memory access

The **first byte at PC** fully identifies the instruction. No prefix bytes.
Extra fetches are **operands** (immediate or displacement), not additional opcodes.

### Fetch model

| Phase | Address | Purpose |
|-------|---------|---------|
| 1 | PC+0 | Opcode — decode instruction |
| 2 | PC+1 | 8-bit operand `n` or `e` (if length ≥ 2) |
| 3 | PC+1, PC+2 | 16-bit operand `nn` low, high (if length = 3) |
| exec | HL | Data read/write for `(HL)` operands (not part of insn length) |
| exec | SP | Stack read/write for PUSH/POP/CALL/RET |

After execution: `PC ← PC + instruction_length` (unless the instruction branches).

### Length summary

| Length | Count | Operand layout |
|--------|-------|----------------|
| 1 byte | 156 | opcode only |
| 2 bytes | 20 | opcode + `n` or `e` |
| 3 bytes | 10 | opcode + `nn` (little-endian) |
| **Total legal** | **186** | |
| Illegal first byte | 70 | treat as fault / NOP per CPU policy |

### Decoder rules (by opcode pattern)

Use these in Verilog `case` or a lookup ROM instead of decoding 256 rows by hand.

| Condition | Length | Examples |
|-----------|--------|----------|
| `op == 0x01, 0x11, 0x21, 0x31` | 3 | `LD BC/DE/HL/SP,nn` |
| `op == 0xC3` | 3 | `JP nn` |
| `op == 0xCD` | 3 | `CALL nn` |
| `op in {0xC4,0xCC,0xD4,0xDC}` | 3 | `CALL cc,nn` |
| `op in {0x06,0x0E,0x16,0x1E,0x26,0x2E,0x3E}` | 2 | `LD r,n` |
| `op == 0x36` | 2 | `LD (HL),n` |
| `op in {0xC6,0xD6,0xE6,0xEE,0xF6,0xFE}` | 2 | `ADD/SUB/AND/XOR/OR/CP` immediate |
| `op == 0x10` | 2 | `DJNZ e` |
| `op == 0x18` | 2 | `JR e` |
| `op in {0x20,0x28,0x30,0x38}` | 2 | `JR cc,e` |
| `0x40 ≤ op ≤ 0x7F` | 1 | `LD r,r'`; **`0x76` = HALT** |
| `op in {0x80..0x87,0x90..0x97,0xA0..0xA7,0xA8..0xAF,0xB0..0xB7,0xB8..0xBF}` | 1 | ALU with register/`(HL)` |
| `op in {0x04,0x0C,0x14,0x1C,0x24,0x2C,0x34,0x3C}` | 1 | `INC r` / `INC (HL)` |
| `op in {0x05,0x0D,0x15,0x1D,0x25,0x2D,0x35,0x3D}` | 1 | `DEC r` / `DEC (HL)` |
| `op in {0x03,0x13,0x23,0x33,0x0B,0x1B,0x2B,0x3B}` | 1 | `INC/DEC rp` |
| `op in {0xC5,0xD5,0xE5,0xF5}` | 1 | `PUSH rp` |
| `op in {0xC1,0xD1,0xE1,0xF1}` | 1 | `POP rp` |
| `op in {0xC0,0xC8,0xD0,0xD8}` | 1 | `RET cc` |
| `op == 0xC9` | 1 | `RET` |
| `op in {0x00,0x07,0x0F,0x17,0x1F,0x37,0x3F}` | 1 | `NOP`, rotates, `SCF`, `CCF` |
| all other `op` | — | **illegal** in this ISA |

### `(HL)` data access (during execute, not fetch)

| Access | Opcodes (pattern) | Instructions |
|--------|-------------------|--------------|
| **Read (HL)** | `LD r,(HL)` | dest ≠ (HL), src = (HL): `46,4E,56,5E,66,6E,7E` |
| **Write (HL)** | `LD (HL),r` | dest = (HL): `70–75, 77` |
| **Write (HL)** | `LD (HL),n` | `36` (+ immediate at PC+1) |
| **Read (HL)** | ALU `(HL)` | `86,96,A6,AE,B6,BE` |
| **Read+Write (HL)** | `INC (HL)`, `DEC (HL)` | `34`, `35` |

All other instructions do not access `(HL)` memory.

### Stack memory access

| Instruction | Stack action |
|-------------|--------------|
| `PUSH rp` | write 2 bytes at SP−1, SP−2 |
| `POP rp` | read 2 bytes at SP, SP+1 |
| `CALL` / `CALL cc` | push return address (2 bytes) |
| `RET` / `RET cc` | pop return address (2 bytes) |

### PC-relative operand note

For `JR e` and `JR cc,e`: effective target = `PC + 2 + sign_extend(e)` where PC is the opcode address.

For `DJNZ e`: if B≠0 after decrement, target = `PC + 2 + sign_extend(e)`.

### Full first-byte lookup table

One row per possible opcode byte. Use for fetch-unit ROM or assembler validation.

Legend: **Len** = instruction bytes from ROM; **HL rd/wr** = data memory via HL; **Stk** = stack access.

| Op | Len | Mnemonic class | HL rd | HL wr | Stk |
|----|-----|----------------|-------|-------|-----|
| `00` | 1 | NOP |  |  |  |
| `01` | 3 | LD BC,nn |  |  |  |
| `02` | — | *illegal* |  |  |  |
| `03` | 1 | INC BC |  |  |  |
| `04` | 1 | INC B |  |  |  |
| `05` | 1 | DEC B |  |  |  |
| `06` | 2 | LD B,n |  |  |  |
| `07` | 1 | RLCA |  |  |  |
| `08` | — | *illegal* |  |  |  |
| `09` | — | *illegal* |  |  |  |
| `0A` | — | *illegal* |  |  |  |
| `0B` | 1 | DEC BC |  |  |  |
| `0C` | 1 | INC C |  |  |  |
| `0D` | 1 | DEC C |  |  |  |
| `0E` | 2 | LD C,n |  |  |  |
| `0F` | 1 | RRCA |  |  |  |
| `10` | 2 | DJNZ e |  |  |  |
| `11` | 3 | LD DE,nn |  |  |  |
| `12` | — | *illegal* |  |  |  |
| `13` | 1 | INC DE |  |  |  |
| `14` | 1 | INC D |  |  |  |
| `15` | 1 | DEC D |  |  |  |
| `16` | 2 | LD D,n |  |  |  |
| `17` | 1 | RLA |  |  |  |
| `18` | 2 | JR e |  |  |  |
| `19` | — | *illegal* |  |  |  |
| `1A` | — | *illegal* |  |  |  |
| `1B` | 1 | DEC DE |  |  |  |
| `1C` | 1 | INC E |  |  |  |
| `1D` | 1 | DEC E |  |  |  |
| `1E` | 2 | LD E,n |  |  |  |
| `1F` | 1 | RRA |  |  |  |
| `20` | 2 | JR NZ,e |  |  |  |
| `21` | 3 | LD HL,nn |  |  |  |
| `22` | — | *illegal* |  |  |  |
| `23` | 1 | INC HL |  |  |  |
| `24` | 1 | INC H |  |  |  |
| `25` | 1 | DEC H |  |  |  |
| `26` | 2 | LD H,n |  |  |  |
| `27` | — | *illegal* |  |  |  |
| `28` | 2 | JR Z,e |  |  |  |
| `29` | — | *illegal* |  |  |  |
| `2A` | — | *illegal* |  |  |  |
| `2B` | 1 | DEC HL |  |  |  |
| `2C` | 1 | INC L |  |  |  |
| `2D` | 1 | DEC L |  |  |  |
| `2E` | 2 | LD L,n |  |  |  |
| `2F` | — | *illegal* |  |  |  |
| `30` | 2 | JR NC,e |  |  |  |
| `31` | 3 | LD SP,nn |  |  |  |
| `32` | — | *illegal* |  |  |  |
| `33` | 1 | INC SP |  |  |  |
| `34` | 1 | INC (HL) | · | · |  |
| `35` | 1 | DEC (HL) | · | · |  |
| `36` | 2 | LD (HL),n |  | · |  |
| `37` | 1 | SCF |  |  |  |
| `38` | 2 | JR C,e |  |  |  |
| `39` | — | *illegal* |  |  |  |
| `3A` | — | *illegal* |  |  |  |
| `3B` | 1 | DEC SP |  |  |  |
| `3C` | 1 | INC A |  |  |  |
| `3D` | 1 | DEC A |  |  |  |
| `3E` | 2 | LD A,n |  |  |  |
| `3F` | 1 | CCF |  |  |  |
| `40` | 1 | LD B,B |  |  |  |
| `41` | 1 | LD B,C |  |  |  |
| `42` | 1 | LD B,D |  |  |  |
| `43` | 1 | LD B,E |  |  |  |
| `44` | 1 | LD B,H |  |  |  |
| `45` | 1 | LD B,L |  |  |  |
| `46` | 1 | LD B,(HL) | · |  |  |
| `47` | 1 | LD B,A |  |  |  |
| `48` | 1 | LD C,B |  |  |  |
| `49` | 1 | LD C,C |  |  |  |
| `4A` | 1 | LD C,D |  |  |  |
| `4B` | 1 | LD C,E |  |  |  |
| `4C` | 1 | LD C,H |  |  |  |
| `4D` | 1 | LD C,L |  |  |  |
| `4E` | 1 | LD C,(HL) | · |  |  |
| `4F` | 1 | LD C,A |  |  |  |
| `50` | 1 | LD D,B |  |  |  |
| `51` | 1 | LD D,C |  |  |  |
| `52` | 1 | LD D,D |  |  |  |
| `53` | 1 | LD D,E |  |  |  |
| `54` | 1 | LD D,H |  |  |  |
| `55` | 1 | LD D,L |  |  |  |
| `56` | 1 | LD D,(HL) | · |  |  |
| `57` | 1 | LD D,A |  |  |  |
| `58` | 1 | LD E,B |  |  |  |
| `59` | 1 | LD E,C |  |  |  |
| `5A` | 1 | LD E,D |  |  |  |
| `5B` | 1 | LD E,E |  |  |  |
| `5C` | 1 | LD E,H |  |  |  |
| `5D` | 1 | LD E,L |  |  |  |
| `5E` | 1 | LD E,(HL) | · |  |  |
| `5F` | 1 | LD E,A |  |  |  |
| `60` | 1 | LD H,B |  |  |  |
| `61` | 1 | LD H,C |  |  |  |
| `62` | 1 | LD H,D |  |  |  |
| `63` | 1 | LD H,E |  |  |  |
| `64` | 1 | LD H,H |  |  |  |
| `65` | 1 | LD H,L |  |  |  |
| `66` | 1 | LD H,(HL) | · |  |  |
| `67` | 1 | LD H,A |  |  |  |
| `68` | 1 | LD L,B |  |  |  |
| `69` | 1 | LD L,C |  |  |  |
| `6A` | 1 | LD L,D |  |  |  |
| `6B` | 1 | LD L,E |  |  |  |
| `6C` | 1 | LD L,H |  |  |  |
| `6D` | 1 | LD L,L |  |  |  |
| `6E` | 1 | LD L,(HL) | · |  |  |
| `6F` | 1 | LD L,A |  |  |  |
| `70` | 1 | LD (HL),B |  | · |  |
| `71` | 1 | LD (HL),C |  | · |  |
| `72` | 1 | LD (HL),D |  | · |  |
| `73` | 1 | LD (HL),E |  | · |  |
| `74` | 1 | LD (HL),H |  | · |  |
| `75` | 1 | LD (HL),L |  | · |  |
| `76` | 1 | HALT |  |  |  |
| `77` | 1 | LD (HL),A |  | · |  |
| `78` | 1 | LD A,B |  |  |  |
| `79` | 1 | LD A,C |  |  |  |
| `7A` | 1 | LD A,D |  |  |  |
| `7B` | 1 | LD A,E |  |  |  |
| `7C` | 1 | LD A,H |  |  |  |
| `7D` | 1 | LD A,L |  |  |  |
| `7E` | 1 | LD A,(HL) | · |  |  |
| `7F` | 1 | LD A,A |  |  |  |
| `80` | 1 | ADD A,B |  |  |  |
| `81` | 1 | ADD A,C |  |  |  |
| `82` | 1 | ADD A,D |  |  |  |
| `83` | 1 | ADD A,E |  |  |  |
| `84` | 1 | ADD A,H |  |  |  |
| `85` | 1 | ADD A,L |  |  |  |
| `86` | 1 | ADD A,(HL) | · |  |  |
| `87` | 1 | ADD A,A |  |  |  |
| `88` | — | *illegal* |  |  |  |
| `89` | — | *illegal* |  |  |  |
| `8A` | — | *illegal* |  |  |  |
| `8B` | — | *illegal* |  |  |  |
| `8C` | — | *illegal* |  |  |  |
| `8D` | — | *illegal* |  |  |  |
| `8E` | — | *illegal* |  |  |  |
| `8F` | — | *illegal* |  |  |  |
| `90` | 1 | SUB B |  |  |  |
| `91` | 1 | SUB C |  |  |  |
| `92` | 1 | SUB D |  |  |  |
| `93` | 1 | SUB E |  |  |  |
| `94` | 1 | SUB H |  |  |  |
| `95` | 1 | SUB L |  |  |  |
| `96` | 1 | SUB (HL) | · |  |  |
| `97` | 1 | SUB A |  |  |  |
| `98` | — | *illegal* |  |  |  |
| `99` | — | *illegal* |  |  |  |
| `9A` | — | *illegal* |  |  |  |
| `9B` | — | *illegal* |  |  |  |
| `9C` | — | *illegal* |  |  |  |
| `9D` | — | *illegal* |  |  |  |
| `9E` | — | *illegal* |  |  |  |
| `9F` | — | *illegal* |  |  |  |
| `A0` | 1 | AND B |  |  |  |
| `A1` | 1 | AND C |  |  |  |
| `A2` | 1 | AND D |  |  |  |
| `A3` | 1 | AND E |  |  |  |
| `A4` | 1 | AND H |  |  |  |
| `A5` | 1 | AND L |  |  |  |
| `A6` | 1 | AND (HL) | · |  |  |
| `A7` | 1 | AND A |  |  |  |
| `A8` | 1 | XOR B |  |  |  |
| `A9` | 1 | XOR C |  |  |  |
| `AA` | 1 | XOR D |  |  |  |
| `AB` | 1 | XOR E |  |  |  |
| `AC` | 1 | XOR H |  |  |  |
| `AD` | 1 | XOR L |  |  |  |
| `AE` | 1 | XOR (HL) | · |  |  |
| `AF` | 1 | XOR A |  |  |  |
| `B0` | 1 | OR B |  |  |  |
| `B1` | 1 | OR C |  |  |  |
| `B2` | 1 | OR D |  |  |  |
| `B3` | 1 | OR E |  |  |  |
| `B4` | 1 | OR H |  |  |  |
| `B5` | 1 | OR L |  |  |  |
| `B6` | 1 | OR (HL) | · |  |  |
| `B7` | 1 | OR A |  |  |  |
| `B8` | 1 | CP B |  |  |  |
| `B9` | 1 | CP C |  |  |  |
| `BA` | 1 | CP D |  |  |  |
| `BB` | 1 | CP E |  |  |  |
| `BC` | 1 | CP H |  |  |  |
| `BD` | 1 | CP L |  |  |  |
| `BE` | 1 | CP (HL) | · |  |  |
| `BF` | 1 | CP A |  |  |  |
| `C0` | 1 | RET NZ |  |  | · |
| `C1` | 1 | POP BC |  |  | · |
| `C2` | — | *illegal* |  |  |  |
| `C3` | 3 | JP nn |  |  |  |
| `C4` | 3 | CALL NZ,nn |  |  | · |
| `C5` | 1 | PUSH BC |  |  | · |
| `C6` | 2 | ADD A,n |  |  |  |
| `C7` | — | *illegal* |  |  |  |
| `C8` | 1 | RET Z |  |  | · |
| `C9` | 1 | RET |  |  | · |
| `CA` | — | *illegal* |  |  |  |
| `CB` | — | *illegal* |  |  |  |
| `CC` | 3 | CALL Z,nn |  |  | · |
| `CD` | 3 | CALL nn |  |  | · |
| `CE` | — | *illegal* |  |  |  |
| `CF` | — | *illegal* |  |  |  |
| `D0` | 1 | RET NC |  |  | · |
| `D1` | 1 | POP DE |  |  | · |
| `D2` | — | *illegal* |  |  |  |
| `D3` | — | *illegal* |  |  |  |
| `D4` | 3 | CALL NC,nn |  |  | · |
| `D5` | 1 | PUSH DE |  |  | · |
| `D6` | 2 | SUB n |  |  |  |
| `D7` | — | *illegal* |  |  |  |
| `D8` | 1 | RET C |  |  | · |
| `D9` | — | *illegal* |  |  |  |
| `DA` | — | *illegal* |  |  |  |
| `DB` | — | *illegal* |  |  |  |
| `DC` | 3 | CALL C,nn |  |  | · |
| `DD` | — | *illegal* |  |  |  |
| `DE` | — | *illegal* |  |  |  |
| `DF` | — | *illegal* |  |  |  |
| `E0` | — | *illegal* |  |  |  |
| `E1` | 1 | POP HL |  |  | · |
| `E2` | — | *illegal* |  |  |  |
| `E3` | — | *illegal* |  |  |  |
| `E4` | — | *illegal* |  |  |  |
| `E5` | 1 | PUSH HL |  |  | · |
| `E6` | 2 | AND n |  |  |  |
| `E7` | — | *illegal* |  |  |  |
| `E8` | — | *illegal* |  |  |  |
| `E9` | — | *illegal* |  |  |  |
| `EA` | — | *illegal* |  |  |  |
| `EB` | — | *illegal* |  |  |  |
| `EC` | — | *illegal* |  |  |  |
| `ED` | — | *illegal* |  |  |  |
| `EE` | 2 | XOR n |  |  |  |
| `EF` | — | *illegal* |  |  |  |
| `F0` | — | *illegal* |  |  |  |
| `F1` | 1 | POP AF |  |  | · |
| `F2` | — | *illegal* |  |  |  |
| `F3` | — | *illegal* |  |  |  |
| `F4` | — | *illegal* |  |  |  |
| `F5` | 1 | PUSH AF |  |  | · |
| `F6` | 2 | OR n |  |  |  |
| `F7` | — | *illegal* |  |  |  |
| `F8` | — | *illegal* |  |  |  |
| `F9` | — | *illegal* |  |  |  |
| `FA` | — | *illegal* |  |  |  |
| `FB` | — | *illegal* |  |  |  |
| `FC` | — | *illegal* |  |  |  |
| `FD` | — | *illegal* |  |  |  |
| `FE` | 2 | CP n |  |  |  |
| `FF` | — | *illegal* |  |  |  |

---

## 1. Load (LD)

### LD r,r' — 63 encodings

Copy source register to destination register.

```
Opcode: 01 DDD SSS
```

| Dest \ Src | B    | C    | D    | E    | H    | L    | (HL) | A    |
|------------|------|------|------|------|------|------|------|------|
| B          | 40   | 41   | 42   | 43   | 44   | 45   | 46   | 47   |
| C          | 48   | 49   | 4A   | 4B   | 4C   | 4D   | 4E   | 4F   |
| D          | 50   | 51   | 52   | 53   | 54   | 55   | 56   | 57   |
| E          | 58   | 59   | 5A   | 5B   | 5C   | 5D   | 5E   | 5F   |
| H          | 60   | 61   | 62   | 63   | 64   | 65   | 66   | 67   |
| L          | 68   | 69   | 6A   | 6B   | 6C   | 6D   | 6E   | 6F   |
| (HL)       | 70   | 71   | 72   | 73   | 74   | 75   | —    | 77   |
| A          | 78   | 79   | 7A   | 7B   | 7C   | 7D   | 7E   | 7F   |

- `LD (HL),(HL)` (76) is **not** a load — opcode 76 is **HALT**.
- Flags: unaffected.

### LD r,n — 7 encodings (+ 1 for (HL))

Load 8-bit immediate into register.

| Mnemonic | Opcode | Bytes   |
|----------|--------|---------|
| LD B,n   | 06     | n       |
| LD C,n   | 0E     | n       |
| LD D,n   | 16     | n       |
| LD E,n   | 1E     | n       |
| LD H,n   | 26     | n       |
| LD L,n   | 2E     | n       |
| LD A,n   | 3E     | n       |
| LD (HL),n| 36     | n       |

- Flags: unaffected.

### LD rp,nn — 4 encodings

Load 16-bit immediate into register pair (little-endian: low byte first).

| Mnemonic | Opcode | Bytes   |
|----------|--------|---------|
| LD BC,nn | 01     | nn      |
| LD DE,nn | 11     | nn      |
| LD HL,nn | 21     | nn      |
| LD SP,nn | 31     | nn      |

- Flags: unaffected.

---

## 2. 8-bit arithmetic and logic

All operate on **A** as the primary operand. Result stored in **A** (except CP, which only sets flags).

### Register form — 48 encodings (6 ops × 8 sources)

```
Opcode: 10 000 SSS   (ADD)
        10 010 SSS   (SUB)
        10 100 SSS   (AND)
        101 010 SSS  (XOR)
        10 110 SSS   (OR)
        10 111 SSS   (CP)
```

| Op  | B    | C    | D    | E    | H    | L    | (HL) | A    |
|-----|------|------|------|------|------|------|------|------|
| ADD | 80   | 81   | 82   | 83   | 84   | 85   | 86   | 87   |
| SUB | 90   | 91   | 92   | 93   | 94   | 95   | 96   | 97   |
| AND | A0   | A1   | A2   | A3   | A4   | A5   | A6   | A7   |
| XOR | A8   | A9   | AA   | AB   | AC   | AD   | AE   | AF   |
| OR  | B0   | B1   | B2   | B3   | B4   | B5   | B6   | B7   |
| CP  | B8   | B9   | BA   | BB   | BC   | BD   | BE   | BF   |

### Immediate form — 6 encodings

| Mnemonic | Opcode | Bytes |
|----------|--------|-------|
| ADD A,n  | C6     | n     |
| SUB n    | D6     | n     |
| AND n    | E6     | n     |
| XOR n    | EE     | n     |
| OR n     | F6     | n     |
| CP n     | FE     | n     |

- Flags: updated per standard Z80 rules for each operation.

---

## 3. Increment / decrement

### 8-bit — 16 encodings

| Mnemonic | Opcode | Flags        |
|----------|--------|--------------|
| INC B    | 04     | S,Z,H updated; N=0; C preserved |
| INC C    | 0C     |              |
| INC D    | 14     |              |
| INC E    | 1C     |              |
| INC H    | 24     |              |
| INC L    | 2C     |              |
| INC (HL) | 34     |              |
| INC A    | 3C     |              |
| DEC B    | 05     | S,Z,H updated; N=1; C preserved |
| DEC C    | 0D     |              |
| DEC D    | 15     |              |
| DEC E    | 1D     |              |
| DEC H    | 25     |              |
| DEC L    | 2D     |              |
| DEC (HL) | 35     |              |
| DEC A    | 3D     |              |

### 16-bit — 8 encodings

| Mnemonic | Opcode | Flags     |
|----------|--------|-----------|
| INC BC   | 03     | Unaffected |
| INC DE   | 13     |            |
| INC HL   | 23     |            |
| INC SP   | 33     |            |
| DEC BC   | 0B     |            |
| DEC DE   | 1B     |            |
| DEC HL   | 2B     |            |
| DEC SP   | 3B     |            |

---

## 4. Stack

### PUSH rp — 4 encodings

Push register pair onto stack (SP decremented first). AF pushes A and F with lower 4 bits of F forced to 0.

| Mnemonic | Opcode |
|----------|--------|
| PUSH BC  | C5     |
| PUSH DE  | D5     |
| PUSH HL  | E5     |
| PUSH AF  | F5     |

### POP rp — 4 encodings

Pop register pair from stack into rp (SP incremented after read).

| Mnemonic | Opcode |
|----------|--------|
| POP BC   | C1     |
| POP DE   | D1     |
| POP HL   | E1     |
| POP AF   | F1     |

- Flags: unaffected (except POP AF loads F).

---

## 5. Jumps

### JP nn — 1 encoding

Unconditional jump to absolute address.

| Mnemonic | Opcode | Bytes |
|----------|--------|-------|
| JP nn    | C3     | nn    |

### JR e — 1 encoding

Relative jump: `PC ← PC + 2 + e` (e is signed 8-bit).

| Mnemonic | Opcode | Bytes |
|----------|--------|-------|
| JR e     | 18     | e       |

### JR cc,e — 4 encodings

Conditional relative jump (same displacement as JR).

| Mnemonic  | Condition   | Opcode | Bytes |
|-----------|-------------|--------|-------|
| JR NZ,e   | Z = 0       | 20     | e     |
| JR Z,e    | Z = 1       | 28     | e     |
| JR NC,e   | C = 0       | 30     | e     |
| JR C,e    | C = 1       | 38     | e     |

If condition false: `PC ← PC + 2` (skip displacement byte).

---

## 6. Subroutines

### CALL nn — 1 encoding

Push return address (PC), jump to nn.

| Mnemonic | Opcode | Bytes |
|----------|--------|-------|
| CALL nn  | CD     | nn    |

### CALL cc,nn — 4 encodings

| Mnemonic   | Condition | Opcode | Bytes |
|------------|-----------|--------|-------|
| CALL NZ,nn | Z = 0     | C4     | nn    |
| CALL Z,nn  | Z = 1     | CC     | nn    |
| CALL NC,nn | C = 0     | D4     | nn    |
| CALL C,nn  | C = 1     | DC     | nn    |

If condition false: `PC ← PC + 3`.

### RET — 1 encoding

Pop return address into PC.

| Mnemonic | Opcode |
|----------|--------|
| RET      | C9     |

### RET cc — 4 encodings

| Mnemonic | Condition | Opcode |
|----------|-----------|--------|
| RET NZ   | Z = 0     | C0     |
| RET Z    | Z = 1     | C8     |
| RET NC   | C = 0     | D0     |
| RET C    | C = 1     | DC     |

If condition false: no operation (PC unchanged).

---

## 7. Loop

| Mnemonic | Opcode | Bytes | Operation                          |
|----------|--------|-------|------------------------------------|
| DJNZ e   | 10     | e     | B ← B−1; if B≠0 then PC ← PC+2+e   |

- Flags: unaffected.
- If B = 0 after decrement: `PC ← PC + 2`.

---

## 8. Rotate accumulator

| Mnemonic | Opcode | Operation                              | Flags        |
|----------|--------|----------------------------------------|--------------|
| RLCA     | 07     | Rotate A left through C                | C=A7; H,N=0; S,Z,P/V=0 |
| RRCA     | 0F     | Rotate A right through C               | C=A0; H,N=0; S,Z,P/V=0 |
| RLA      | 17     | Rotate A left through C (incl. old C)  | C=A7; H,N=0; S,Z,P/V=0 |
| RRA      | 1F     | Rotate A right through C (incl. old C) | C=A0; H,N=0; S,Z,P/V=0 |

---

## 9. System / flags

| Mnemonic | Opcode | Operation                    | Flags              |
|----------|--------|------------------------------|--------------------|
| NOP      | 00     | No operation                 | Unaffected         |
| HALT     | 76     | Stop until interrupt / reset | Unaffected         |
| SCF      | 37     | Set carry flag               | C=1; H,N=0; others 0 |
| CCF      | 3F     | Complement carry flag        | C←¬C; H,N=0; others 0 |

---

## Excluded (not in this ISA)

The following standard Z80 features are **intentionally omitted**:

- Prefix instructions (CB, ED, DD, FD)
- Indexed addressing (IX, IY)
- Block transfer / search (LDIR, CPIR, …)
- Port I/O (IN, OUT)
- Absolute addressing LD (nn),A / LD A,(nn) and 16-bit variants
- LD r,(BC) / LD r,(DE) and stores to (BC)/(DE)
- ADD HL,rr; JP (HL); RST n; EX / EXX
- Interrupt control (EI, DI, IM n, RETI, RETN)
- Decimal / extended ops (DAA, CPL, NEG, …)

---

## Assembler notes

- Labels resolve to 16-bit addresses (for JP nn, CALL nn).
- JR / DJNZ displacements are computed relative to the byte **after** the displacement.
- `.org 0x0000` is the default ROM origin.
- Assembled images are written to `firmware/` (see `tools/assemble.py`).
- Unknown mnemonics or opcodes outside this table are errors.
- Instruction byte length and `(HL)`/stack side effects: see **Instruction fetch, length, and memory access** above.
