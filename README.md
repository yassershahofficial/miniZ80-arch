# miniZ80

A reduced Z80-style CPU in Verilog, with a minimal Python assembler and fixed ROM at `0x0000`.

## Layout

```
miniZ80_arch/
├── docs/
│   ├── isa.md              # Instruction set + fetch/length tables
│   └── components.md       # CPU block diagram + module guide
├── rtl/
│   ├── system.v            # CPU + ROM + RAM (sim top)
│   ├── rom.v               # Program ROM at 0x0000
│   ├── ram.v               # Data RAM (stack, variables)
│   └── cpu/                # One module per component — see components.md
│       ├── core.v          # Top CPU; memory port
│       ├── reg_file.v      # A,F,B,C,D,E,H,L
│       ├── pc.v            # Program counter
│       ├── sp.v            # Stack pointer
│       ├── fetch.v         # Opcode + operand fetch
│       ├── decode.v        # Instruction decode
│       ├── alu.v           # Arithmetic / logic
│       ├── shifter.v       # RLCA, RRCA, RLA, RRA
│       ├── flags.v         # Condition flags
│       ├── control.v       # Multi-cycle FSM
│       └── bus.v           # Address / data mux
├── tb/
│   └── tb_cpu.v            # System testbench
├── asm/
│   └── examples/
│       └── milestone.asm   # NOP → LD A,n → HALT
├── tools/
│   └── assemble.py         # asm → firmware/*.bin + *.hex
├── firmware/               # Compiled program images (loaded by rtl/rom.v)
└── Makefile
```

### ROM: hardware vs program image

| Path | What it is |
|------|------------|
| `rtl/rom.v` | Verilog ROM **chip** — memory the CPU reads |
| `firmware/*.hex` | **Program bytes** — output of the assembler, loaded into the chip at sim time |

## Workflow

```text
asm/your_program.asm  →  tools/assemble.py  →  firmware/your_program.hex
                                                      ↓
                                            rtl/rom.v ($readmemh)
                                                      ↓
                                            tb/ + simulator
```

## Quick start

```bash
# Assemble milestone program → firmware/milestone.hex
make asm EX=examples/milestone
# or: python3 tools/assemble.py asm/examples/milestone.asm

# Run system testbench (requires iverilog)
make sim
```

Expected sim output: `HALT reached, A = 42` then `PASS`.

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` + `vvp`). The RTL uses Verilog-2001 (no SystemVerilog `inside` operator).
