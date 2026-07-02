// Stage 5 : insn_meta + decode (previous: shifter path).
// Proves opcode maps to length/metadata and control signals (no clock).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage05_decode;
    reg [7:0] opcode;
    wire [1:0] insn_len;
    wire       illegal, hl_read, hl_write, stack_op;
    wire       is_nop, is_ld_a_n, is_alu, is_halt, is_jp;

    insn_meta u_meta (
        .opcode(opcode), .insn_len(insn_len), .illegal(illegal),
        .hl_read(hl_read), .hl_write(hl_write), .stack_op(stack_op)
    );

    decode u_decode (
        .opcode(opcode),
        .is_ld(), .is_ld_a_n(is_ld_a_n), .is_ld_rr(), .is_ld_r_n(),
        .is_ld_hl_n(), .is_ld_rp_nn(), .ld_pair_sel(),
        .ld_src_hl(), .ld_dst_hl(),
        .is_alu(is_alu), .is_alu_imm(), .is_alu_cp(),
        .is_inc_dec(), .is_inc_dec_8(), .is_inc_dec_rp(), .is_inc(),
        .inc_dec_pair_sel(), .inc_dec_hl(),
        .is_push_pop(), .is_branch(), .is_rotate(), .is_flag_op(),
        .is_halt(is_halt), .is_nop(is_nop),
        .reg_d(), .reg_s(), .alu_op(), .branch_cond(), .cond_sel(),
        .is_push(), .is_pop(), .stack_pair_sel(),
        .is_jp(is_jp), .is_jr(), .is_call(), .is_ret(), .is_djnz(),
        .is_scf(), .is_ccf(), .rotate_op()
    );

    initial begin
        opcode = 8'h3E;
        #1;
        `CHECK_EQ(insn_len, 2'd2, "stage05 LD A,n len");
        `CHECK_FLAG(is_ld_a_n, 1'b1, "stage05 LD A,n decode");

        opcode = 8'hC3;
        #1;
        `CHECK_EQ(insn_len, 2'd3, "stage05 JP len");
        `CHECK_FLAG(is_jp, 1'b1, "stage05 JP decode");

        `TB_PASS("tb_stage05_decode");
    end
endmodule
