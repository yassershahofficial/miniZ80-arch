# Staged integration testbenches

These testbenches wire CPU blocks together in the order you would build the CPU. Run them bottom-up to see where the design starts and what each layer adds.

## Ladder

| Stage | Testbench | Blocks wired | What it proves |
|-------|-----------|--------------|----------------|
| 1 | `tb_stage01_alu.v` | `alu` | Datapath arithmetic before any registers |
| 2 | `tb_stage02_alu_flags.v` | `alu` + `flags` | ALU flag outputs stored in F |
| 3 | `tb_stage03_datapath.v` | `alu` + `flags` + `reg_file` | Register load path via `stage_datapath` harness |
| 4 | `tb_stage04_shifter.v` | `shifter` + `flags` | Rotate path updates C only |
| 5 | `tb_stage05_decode.v` | `insn_meta` + `decode` | Opcode → length and control signals |
| 6 | `tb_stage06_pc.v` | `pc` | PC load from absolute address |
| 7 | `tb_stage07_fetch.v` | `pc` + `insn_meta` + `rom` | First ROM byte at PC=0; metadata for next opcode |
| 8 | `tb_stage08_sp_mem.v` | `sp` + `ram` | SP load and RAM write/read in stack region |
| — | `tb/tb_cpu.v` | `system` → `cpu_core` | Full CPU with firmware until HALT |

## Run

```bash
make test-stages          # all stage tests
make test-stage07-fetch   # one stage
make test-all             # components + stages + firmware integration
```

Component-level unit tests live in [`../components/`](../components/). See `make test-components`.

Harness modules used by stages 2, 3, and 7 are in [`../dut/`](../dut/).
