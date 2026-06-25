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

.PHONY: asm sim test clean

asm:
	$(ASM) $(SRC) -o $(BIN)

sim: asm $(RTL) $(TB)
	$(SIM) -g2012 -o sim.vvp -I rtl -y rtl/cpu \
		-DEXPECT_A=8\'h42 -DEXPECT_B=8\'h00 -DEXPECT_C=8\'h00 \
		-DFIRMWARE=\"$(HEX)\" \
		$(TB) $(RTL)
	vvp sim.vvp

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
