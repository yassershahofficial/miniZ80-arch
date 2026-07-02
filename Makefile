SIM  ?= iverilog
ASM  = python3 tools/assemble.py
FIRMWARE_DIR = firmware

EX  ?= examples/milestone
SRC = asm/$(EX).asm
BIN = $(FIRMWARE_DIR)/$(notdir $(EX)).bin
HEX = $(BIN:.bin=.hex)

RTL = \
	rtl/system.v \
	rtl/rom.v \
	rtl/ram.v \
	rtl/cpu/core.v \
	rtl/cpu/reg_file.v \
	rtl/cpu/pc.v \
	rtl/cpu/sp.v \
	rtl/cpu/insn_meta.v \
	rtl/cpu/fetch.v \
	rtl/cpu/decode.v \
	rtl/cpu/alu.v \
	rtl/cpu/shifter.v \
	rtl/cpu/flags.v \
	rtl/cpu/control.v \
	rtl/cpu/bus.v

TB = tb/tb_cpu.v

TB_INC = -I tb/components
WAVES_DIR = waves
WAVE_SIM = $(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) -DDUMP_VCD
CPU_RTL = rtl/cpu/alu.v rtl/cpu/flags.v rtl/cpu/reg_file.v rtl/cpu/pc.v \
	rtl/cpu/sp.v rtl/cpu/shifter.v rtl/cpu/insn_meta.v rtl/cpu/decode.v
DUT_RTL = tb/dut/stage_alu_flags.v tb/dut/stage_datapath.v tb/dut/stage_fetch.v

.PHONY: asm sim test test-components test-stages test-all clean \
	test-tb-alu test-tb-flags test-tb-reg-file test-tb-pc test-tb-sp \
	test-tb-shifter test-tb-insn-meta test-tb-decode test-tb-control \
	test-stage01-alu test-stage02-alu-flags test-stage03-datapath \
	test-stage04-shifter test-stage05-decode test-stage06-pc \
	test-stage07-fetch test-stage08-sp-mem \
	waves wave-alu wave-flags wave-reg-file wave-pc wave-sp \
	wave-shifter wave-insn-meta wave-decode wave-control wave-cpu

# $(1)=vcd basename, $(2)=tb file, $(3)=rtl sources
define WAVE_DUMP
	@mkdir -p $(WAVES_DIR)
	$(WAVE_SIM) -DVCD_FILE=\"$(WAVES_DIR)/$(1).vcd\" \
		tb/components/$(2) $(3)
	vvp sim.vvp
endef

define WAVE_VIEW
	$(call WAVE_DUMP,$(1),$(2),$(3))
	gtkwave $(WAVES_DIR)/$(1).vcd $(WAVES_DIR)/$(1).gtkw &
endef

waves: wave-alu-dump wave-flags-dump wave-reg-file-dump wave-pc-dump wave-sp-dump \
	wave-shifter-dump wave-insn-meta-dump wave-decode-dump wave-control-dump

wave-alu-dump:
	$(call WAVE_DUMP,alu,tb_alu.v,rtl/cpu/alu.v)

wave-flags-dump:
	$(call WAVE_DUMP,flags,tb_flags.v,rtl/cpu/flags.v)

wave-reg-file-dump:
	$(call WAVE_DUMP,reg_file,tb_reg_file.v,rtl/cpu/reg_file.v)

wave-pc-dump:
	$(call WAVE_DUMP,pc,tb_pc.v,rtl/cpu/pc.v)

wave-sp-dump:
	$(call WAVE_DUMP,sp,tb_sp.v,rtl/cpu/sp.v)

wave-shifter-dump:
	$(call WAVE_DUMP,shifter,tb_shifter.v,rtl/cpu/shifter.v)

wave-insn-meta-dump:
	$(call WAVE_DUMP,insn_meta,tb_insn_meta.v,rtl/cpu/insn_meta.v)

wave-decode-dump:
	$(call WAVE_DUMP,decode,tb_decode.v,rtl/cpu/decode.v)

wave-control-dump:
	$(call WAVE_DUMP,control,tb_control.v,rtl/cpu/control.v rtl/cpu/decode.v rtl/cpu/insn_meta.v)

wave-alu:
	$(call WAVE_VIEW,alu,tb_alu.v,rtl/cpu/alu.v)

wave-flags:
	$(call WAVE_VIEW,flags,tb_flags.v,rtl/cpu/flags.v)

wave-reg-file:
	$(call WAVE_VIEW,reg_file,tb_reg_file.v,rtl/cpu/reg_file.v)

wave-pc:
	$(call WAVE_VIEW,pc,tb_pc.v,rtl/cpu/pc.v)

wave-sp:
	$(call WAVE_VIEW,sp,tb_sp.v,rtl/cpu/sp.v)

wave-shifter:
	$(call WAVE_VIEW,shifter,tb_shifter.v,rtl/cpu/shifter.v)

wave-insn-meta:
	$(call WAVE_VIEW,insn_meta,tb_insn_meta.v,rtl/cpu/insn_meta.v)

wave-decode:
	$(call WAVE_VIEW,decode,tb_decode.v,rtl/cpu/decode.v)

wave-control:
	$(call WAVE_VIEW,control,tb_control.v,rtl/cpu/control.v rtl/cpu/decode.v rtl/cpu/insn_meta.v)

test-components: test-tb-alu test-tb-flags test-tb-reg-file test-tb-pc \
	test-tb-sp test-tb-shifter test-tb-insn-meta test-tb-decode test-tb-control

test-stages: test-stage01-alu test-stage02-alu-flags test-stage03-datapath \
	test-stage04-shifter test-stage05-decode test-stage06-pc \
	test-stage07-fetch test-stage08-sp-mem

test-all: test-components test-stages test

test-tb-alu:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_alu.v rtl/cpu/alu.v
	vvp sim.vvp

test-tb-flags:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_flags.v rtl/cpu/flags.v
	vvp sim.vvp

test-tb-reg-file:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_reg_file.v rtl/cpu/reg_file.v
	vvp sim.vvp

test-tb-pc:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_pc.v rtl/cpu/pc.v
	vvp sim.vvp

test-tb-sp:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_sp.v rtl/cpu/sp.v
	vvp sim.vvp

test-tb-shifter:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_shifter.v rtl/cpu/shifter.v
	vvp sim.vvp

test-tb-insn-meta:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_insn_meta.v rtl/cpu/insn_meta.v
	vvp sim.vvp

test-tb-decode:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_decode.v rtl/cpu/decode.v
	vvp sim.vvp

test-tb-control:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/components/tb_control.v rtl/cpu/control.v rtl/cpu/decode.v rtl/cpu/insn_meta.v
	vvp sim.vvp

test-stage01-alu:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/stages/tb_stage01_alu.v rtl/cpu/alu.v
	vvp sim.vvp

test-stage02-alu-flags:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu -y tb/dut $(TB_INC) \
		tb/stages/tb_stage02_alu_flags.v tb/dut/stage_alu_flags.v \
		rtl/cpu/alu.v rtl/cpu/flags.v
	vvp sim.vvp

test-stage03-datapath:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu -y tb/dut $(TB_INC) \
		tb/stages/tb_stage03_datapath.v tb/dut/stage_datapath.v \
		rtl/cpu/alu.v rtl/cpu/flags.v rtl/cpu/reg_file.v
	vvp sim.vvp

test-stage04-shifter:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/stages/tb_stage04_shifter.v rtl/cpu/shifter.v rtl/cpu/flags.v
	vvp sim.vvp

test-stage05-decode:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/stages/tb_stage05_decode.v rtl/cpu/insn_meta.v rtl/cpu/decode.v
	vvp sim.vvp

test-stage06-pc:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/stages/tb_stage06_pc.v rtl/cpu/pc.v
	vvp sim.vvp

test-stage07-fetch:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu -y tb/dut $(TB_INC) \
		tb/stages/tb_stage07_fetch.v tb/dut/stage_fetch.v \
		rtl/cpu/pc.v rtl/cpu/insn_meta.v rtl/rom.v
	vvp sim.vvp

test-stage08-sp-mem:
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu $(TB_INC) \
		tb/stages/tb_stage08_sp_mem.v rtl/cpu/sp.v rtl/ram.v
	vvp sim.vvp

asm:
	$(ASM) $(SRC) -o $(BIN)

sim: asm $(RTL) $(TB)
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DEXPECT_A=8\'h42 -DEXPECT_B=8\'h00 -DEXPECT_C=8\'h00 \
		-DFIRMWARE=\"$(HEX)\" \
		$(TB) $(RTL)
	vvp sim.vvp

wave-cpu: asm
	@mkdir -p $(WAVES_DIR)
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DDUMP_VCD -DSKIP_CHECK \
		-DVCD_FILE=\"$(WAVES_DIR)/$(notdir $(EX)).vcd\" \
		-DFIRMWARE=\"$(HEX)\" \
		$(TB) $(RTL)
	vvp sim.vvp
	gtkwave $(WAVES_DIR)/$(notdir $(EX)).vcd $(WAVES_DIR)/cpu.gtkw &

test: test-milestone test-ld-reg test-ld-hl test-ld-rp test-alu test-alu-hl test-inc test-inc-hl test-stack test-stack-af test-branch test-branch-cond test-rotate

test-milestone:
	$(MAKE) asm EX=examples/milestone
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/milestone.hex\" \
		-DEXPECT_A=8\'h42 -DEXPECT_B=8\'h00 -DEXPECT_C=8\'h00 \
		$(TB) $(RTL)
	vvp sim.vvp

test-ld-reg:
	$(MAKE) asm EX=examples/ld_reg
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/ld_reg.hex\" \
		-DEXPECT_A=8\'h42 -DEXPECT_B=8\'h42 -DEXPECT_C=8\'h42 \
		$(TB) $(RTL)
	vvp sim.vvp

test-ld-hl:
	$(MAKE) asm EX=examples/ld_hl
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/ld_hl.hex\" \
		-DEXPECT_A=8\'h42 -DEXPECT_B=8\'h00 -DEXPECT_C=8\'h00 \
		-DEXPECT_H=8\'h00 -DEXPECT_L=8\'h08 \
		$(TB) $(RTL)
	vvp sim.vvp

test-ld-rp:
	$(MAKE) asm EX=examples/ld_rp
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/ld_rp.hex\" \
		-DEXPECT_A=8\'h00 -DEXPECT_B=8\'h12 -DEXPECT_C=8\'h34 \
		-DEXPECT_H=8\'h00 -DEXPECT_L=8\'hEF -DEXPECT_SP=16\'h00FE \
		$(TB) $(RTL)
	vvp sim.vvp

test-alu:
	$(MAKE) asm EX=examples/alu
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/alu.hex\" \
		-DEXPECT_A=8\'h00 -DEXPECT_B=8\'h03 \
		$(TB) $(RTL)
	vvp sim.vvp

test-alu-hl:
	$(MAKE) asm EX=examples/alu_hl
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/alu_hl.hex\" \
		-DEXPECT_A=8\'h52 -DEXPECT_H=8\'h00 -DEXPECT_L=8\'h08 \
		$(TB) $(RTL)
	vvp sim.vvp

test-inc:
	$(MAKE) asm EX=examples/inc
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/inc.hex\" \
		-DEXPECT_A=8\'h10 -DEXPECT_B=8\'h00 -DEXPECT_C=8\'h01 \
		$(TB) $(RTL)
	vvp sim.vvp

test-inc-hl:
	$(MAKE) asm EX=examples/inc_hl
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/inc_hl.hex\" \
		-DEXPECT_A=8\'h06 -DEXPECT_B=8\'h05 \
		-DEXPECT_H=8\'h04 -DEXPECT_L=8\'h00 \
		$(TB) $(RTL)
	vvp sim.vvp

test-stack:
	$(MAKE) asm EX=examples/stack
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/stack.hex\" \
		-DEXPECT_A=8\'h00 -DEXPECT_B=8\'h12 -DEXPECT_C=8\'h34 \
		-DEXPECT_SP=16\'h0410 \
		$(TB) $(RTL)
	vvp sim.vvp

test-stack-af:
	$(MAKE) asm EX=examples/stack_af
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/stack_af.hex\" \
		-DEXPECT_A=8\'h55 \
		-DEXPECT_SP=16\'h0410 \
		$(TB) $(RTL)
	vvp sim.vvp

test-branch-cond:
	$(MAKE) asm EX=examples/branch_cond
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/branch_cond.hex\" \
		-DEXPECT_A=8\'hFD \
		-DEXPECT_SP=16\'h0410 \
		$(TB) $(RTL)
	vvp sim.vvp

test-branch:
	$(MAKE) asm EX=examples/branch
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/branch.hex\" \
		-DEXPECT_A=8\'h01 -DEXPECT_B=8\'h00 \
		-DEXPECT_SP=16\'h0410 \
		$(TB) $(RTL)
	vvp sim.vvp

test-rotate:
	$(MAKE) asm EX=examples/rotate
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DFIRMWARE=\"firmware/rotate.hex\" \
		-DEXPECT_A=8\'h82 \
		$(TB) $(RTL)
	vvp sim.vvp

clean:
	rm -f sim.vvp
	rm -f $(WAVES_DIR)/*.vcd
