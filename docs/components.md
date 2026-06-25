# CPU Components

Hardware blocks required to implement the miniZ80 in Verilog. Instruction behaviour and fetch rules are defined in [isa.md](isa.md).

---

## Block diagram

```text
                    ┌─────────────┐
         clk/rst ──►│  Control    │◄── opcode, flags, insn_len
                    │  (FSM)      │
                    └──────┬──────┘
                           │ control signals
    ┌──────────────────────┼──────────────────────┐
    │                      │                      │
    ▼                      ▼                      ▼
┌────────┐          ┌───────────┐          ┌──────────┐
│ Reg    │◄────────►│ ALU +     │          │ PC / SP  │
│ file   │          │ shifter   │          │ mgmt     │
└────────┘          └───────────┘          └──────────┘
    │                      ▲                      │
    │                      │                      │
    └──────────┬───────────┴──────────┬───────────┘
               │                      │
               ▼                      ▼
        ┌─────────────┐        ┌─────────────┐
        │ Address mux │───────►│ Memory bus  │──► ROM / RAM
        └─────────────┘        └─────────────┘
```

---

## Module map (`rtl/cpu/`)

Each block lives in its **own file** so the datapath is easy to follow. See the full tree in [README.md](../README.md).

| Module | File | Role |
|--------|------|------|
| Top integration | `core.v` | Instantiates all blocks; external memory interface |
| Register file | `reg_file.v` | A, F, B, C, D, E, H, L |
| Program counter | `pc.v` | Fetch address, branches, return address |
| Stack pointer | `sp.v` | Stack push/pop addressing |
| Fetch unit | `fetch.v` | Read opcode + operands; instruction length |
| Decoder | `decode.v` | Opcode → control signals |
| ALU | `alu.v` | ADD, SUB, AND, OR, XOR, CP, INC, DEC |
| Shifter | `shifter.v` | RLCA, RRCA, RLA, RRA |
| Flags | `flags.v` | S, Z, H, P/V, N, C update and condition test |
| Control FSM | `control.v` | Multi-cycle instruction sequencing |
| Bus / mux | `bus.v` | Address and data path muxing |

System-level modules (sibling to `cpu/`):

| Module | File | Role |
|--------|------|------|
| System top | `rtl/system.v` | Wires CPU + ROM + RAM for simulation |
| ROM | `rtl/rom.v` | Program store at 0x0000 |
| RAM | `rtl/ram.v` | Stack and variables |

Testbench:

| File | Role |
|------|------|
| `tb/tb_cpu.v` | Clock, reset, instantiate `system`, run until `HALT` |

All RTL stubs exist; implement logic block-by-block following the build order below.

---

## 1. Register file

Holds all architected CPU state.

| Storage | Width | Used by |
|---------|-------|---------|
| A, F | 8 | ALU, flags, `PUSH/POP AF` |
| B, C, D, E, H, L | 8 | `LD`, `INC/DEC`, `DJNZ` (B) |
| PC | 16 | Fetch, branches, `CALL/RET` |
| SP | 16 | Stack operations |

**Requirements**

- Two read ports (e.g. source register + A, or HL for memory address)
- One write port for results and flag updates
- 16-bit pair read/write for `LD BC,nn`, `INC HL`, `PUSH BC`, etc.

PC and SP may live in dedicated modules (`pc.v`, `sp.v`) rather than inside `reg_file.v`.

---

## 2. Program counter (PC)

Points at the current instruction or operand byte in memory.

**Requirements**

- Increment by 1, 2, or 3 (from instruction length table in [isa.md](isa.md))
- Load absolute address `nn` (`JP nn`, `CALL nn`)
- Relative update for `JR` / `DJNZ`: `PC + 2 + sign_extend(e)`
- Load from stack on `RET`
- On `CALL`: save return address (`PC + insn_len`), then jump

Not required: `JP (HL)` (excluded from this ISA).

---

## 3. Stack pointer (SP)

Supports `PUSH`, `POP`, `CALL`, and `RET`.

**Requirements**

- Decrement by 2 before `PUSH` (high byte at SP−1, low byte at SP−2)
- Increment by 2 after `POP`
- `LD SP,nn` and 16-bit `INC/DEC SP`

Stack storage lives in RAM, not inside the CPU core.

---

## 4. Instruction fetch unit

Reads instruction bytes from memory. The **first byte fully identifies** the instruction; extra bytes are operands only (no prefix opcodes).

**Requirements**

- Drive address from PC during fetch
- Latch opcode (byte at PC+0)
- Length decode from opcode alone → 1, 2, or 3 bytes (see lookup table in [isa.md](isa.md))
- Latch operands: 8-bit `n`/`e` or 16-bit `nn` (little-endian)
- Export side-effect hints: `(HL)` read/write, stack access, illegal opcode

Suggested internal lookup (256-entry ROM or case table):

```text
opcode[7:0] → { len[1:0], hl_read, hl_write, stack, illegal }
```

---

## 5. Instruction decoder

Turns opcode + operands into control signals for the datapath and FSM.

**Requirements**

- Identify operation class: `LD`, `ADD`, `JP`, `CALL`, `HALT`, etc.
- Extract register fields `DDD` / `SSS` for `LD r,r'` and ALU register forms
- Select operand source: register, immediate, or `(HL)`
- Conditional control: test **Z** and **C** for `JR cc`, `CALL cc`, `RET cc`
- `HALT`: assert halt; stop fetching until reset
- `NOP`: no operation; advance PC only

No prefix decoder needed (no CB / ED / DD / FD instructions).

---

## 6. ALU

Arithmetic and logic for 8-bit operations.

| Operation | Notes |
|-----------|-------|
| ADD / SUB | 8-bit result; carry/borrow for flags |
| AND / OR / XOR | Bitwise |
| CP | Subtract without write-back; flags only |
| INC / DEC (8-bit) | Special flag rules; carry preserved |
| INC / DEC (16-bit) | BC, DE, HL, SP; flags unaffected |

**Not required:** `ADC`/`SBC`, `DAA`, `ADD HL,rr`.

---

## 7. Shifter

Handles accumulator rotates only.

| Instruction | Effect |
|-------------|--------|
| RLCA / RRCA | Rotate A; carry = bit shifted out |
| RLA / RRA | Rotate A through existing carry |

Updates **C** only; clears H, N, S, Z, P/V per ISA. Can be merged into `alu.v` if preferred.

---

## 8. Flags register (F)

Stores condition flags and drives conditional branches.

| Bit | Name | Role |
|-----|------|------|
| 7 | S | Sign |
| 6 | Z | Zero |
| 4 | H | Half-carry |
| 2 | P/V | Parity or overflow (per operation) |
| 1 | N | Subtract flag |
| 0 | C | Carry |

**Requirements**

- Compute flags from ALU/shifter results per Z80 rules
- Preserve carry on 8-bit `INC`/`DEC`
- Leave flags unchanged on `LD`, 16-bit `INC`/`DEC`, most data moves
- `SCF` / `CCF` direct carry manipulation
- Condition mux: **Z** and **C** for `JR cc`, `CALL cc`, `RET cc`

---

## 9. Memory interface / bus

Connects the CPU to ROM and RAM.

**Requirements**

- **Address mux** selects:
  - PC — instruction fetch
  - HL — `(HL)` data access
  - SP (and SP−1) — stack read/write
- **Data direction:** read for fetch, `LD`, `POP`, `RET`; write for stores, `PUSH`, `CALL`
- 8-bit data, 16-bit address (width fixed when memory map is finalised)

Simple unified bus is sufficient for simulation; split ROM/RAM decode can come later.

---

## 10. Control FSM

Sequences multi-cycle instructions. Most opcodes need more than one clock cycle.

| Activity | Examples |
|----------|----------|
| Fetch only | `NOP`, `LD r,r'`, register-form ALU |
| Fetch + operand | `LD r,n`, `JR e`, `DJNZ e` |
| Fetch + 16-bit operand | `LD HL,nn`, `JP nn`, `CALL nn` |
| Memory read | `LD A,(HL)`, `ADD A,(HL)` |
| Memory write | `LD (HL),A`, `LD (HL),n` |
| Read-modify-write | `INC (HL)`, `DEC (HL)` |
| Stack (2 byte transfers) | `PUSH`, `POP`, `CALL`, `RET` |

**Suggested states:** `RESET`, `FETCH`, `FETCH2`, `FETCH3`, `EXEC`, `MEM_RD`, `MEM_WR`, `STACK_PUSH`, `STACK_POP`, `HALT`.

The FSM consumes decoder outputs plus `len`, `hl_read`, `hl_write`, and `stack` from the fetch unit.

---

## 11. Top-level CPU (`core.v`)

Ties all blocks together and exposes the memory port.

**External interface (minimum)**

| Signal | Dir | Description |
|--------|-----|-------------|
| `clk` | in | System clock |
| `rst` | in | Synchronous reset |
| `halt` | out | CPU halted (`HALT` instruction) |
| `addr[15:0]` | out | Memory address |
| `data_in[7:0]` | in | Read data |
| `data_out[7:0]` | out | Write data |
| `mem_read` | out | Assert during memory read |
| `mem_write` | out | Assert during memory write |

---

## System components (outside CPU core)

| Component | Purpose |
|-----------|---------|
| ROM | Program code at 0x0000 (`rtl/rom.v`) |
| RAM | Stack and program variables (TBD) |
| Clock / reset | Drives `clk` and `rst` in testbench |
| Testbench (`tb/`) | Load ROM, run until `HALT`, check registers/memory |

No I/O ports, interrupt controller, or index registers are required for this ISA.

---

## Build order

Recommended implementation sequence:

1. **Reg file + PC + ROM fetch** — read bytes; advance PC by instruction length
2. **Fetch lookup + decoder** — 256-row table from [isa.md](isa.md)
3. **ALU + flags** — start with `NOP`, `LD A,n`, `ADD A,n`, `CP n`
4. **`(HL)` memory path** — `LD A,(HL)`, `LD (HL),A`
5. **Stack** — `PUSH`/`POP`, then `CALL`/`RET`
6. **Branches** — `JP nn`, `JR`, conditionals, `DJNZ`
7. **Shifter + HALT + illegal opcode** handling

**First milestone test program:** `NOP` → `LD A,n` → `HALT` in ROM, verified in `tb/tb_cpu.v`.

---

## Design notes

| Choice | Recommendation |
|--------|----------------|
| Shifter | Separate `shifter.v` or fold into `alu.v` |
| Fetch + decode | May start combined; split when FSM grows |
| Illegal opcode | Trap to `HALT`, jump to fixed vector, or treat as `NOP` — pick one policy and document it |
| Flag P/V | Follow Z80 tables for accuracy; acceptable to simplify early and refine later |
