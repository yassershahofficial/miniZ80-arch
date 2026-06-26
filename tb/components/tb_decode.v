// Unit test — instruction decoder.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_decode;
    reg  [7:0] opcode;
    wire       is_ld, is_ld_a_n, is_ld_rr, is_ld_r_n, is_ld_hl_n, is_ld_rp_nn;
    wire [1:0] ld_pair_sel;
    wire       ld_src_hl, ld_dst_hl;
    wire       is_alu, is_alu_imm, is_alu_cp;
    wire       is_inc_dec, is_inc_dec_8, is_inc_dec_rp, is_inc;
    wire [1:0] inc_dec_pair_sel;
    wire       inc_dec_hl;
    wire       is_push_pop, is_branch, is_rotate, is_flag_op, is_halt, is_nop;
    wire [2:0] reg_d, reg_s;
    wire [3:0] alu_op;
    wire       branch_cond;
    wire [1:0] cond_sel;
    wire       is_push, is_pop;
    wire [1:0] stack_pair_sel;
    wire       is_jp, is_jr, is_call, is_ret, is_djnz, is_scf, is_ccf;
    wire [1:0] rotate_op;

    decode u_dut (
        .opcode          (opcode),
        .is_ld           (is_ld),
        .is_ld_a_n       (is_ld_a_n),
        .is_ld_rr        (is_ld_rr),
        .is_ld_r_n       (is_ld_r_n),
        .is_ld_hl_n      (is_ld_hl_n),
        .is_ld_rp_nn     (is_ld_rp_nn),
        .ld_pair_sel     (ld_pair_sel),
        .ld_src_hl       (ld_src_hl),
        .ld_dst_hl       (ld_dst_hl),
        .is_alu          (is_alu),
        .is_alu_imm      (is_alu_imm),
        .is_alu_cp       (is_alu_cp),
        .is_inc_dec      (is_inc_dec),
        .is_inc_dec_8    (is_inc_dec_8),
        .is_inc_dec_rp   (is_inc_dec_rp),
        .is_inc          (is_inc),
        .inc_dec_pair_sel(inc_dec_pair_sel),
        .inc_dec_hl      (inc_dec_hl),
        .is_push_pop     (is_push_pop),
        .is_branch       (is_branch),
        .is_rotate       (is_rotate),
        .is_flag_op      (is_flag_op),
        .is_halt         (is_halt),
        .is_nop          (is_nop),
        .reg_d           (reg_d),
        .reg_s           (reg_s),
        .alu_op          (alu_op),
        .branch_cond     (branch_cond),
        .cond_sel        (cond_sel),
        .is_push         (is_push),
        .is_pop          (is_pop),
        .stack_pair_sel  (stack_pair_sel),
        .is_jp           (is_jp),
        .is_jr           (is_jr),
        .is_call         (is_call),
        .is_ret          (is_ret),
        .is_djnz         (is_djnz),
        .is_scf          (is_scf),
        .is_ccf          (is_ccf),
        .rotate_op       (rotate_op)
    );

    initial begin
        opcode = 8'h00;
        #1;
        `CHECK_FLAG(is_nop, 1'b1, "NOP");

        opcode = 8'h3E;
        #1;
        `CHECK_FLAG(is_ld_a_n, 1'b1, "LD A,n");
        `CHECK_FLAG(is_ld_r_n, 1'b1, "LD A,n is_ld_r_n");

        opcode = 8'h80;
        #1;
        `CHECK_FLAG(is_alu, 1'b1, "ADD B");
        `CHECK_EQ(alu_op, 4'd0, "ADD alu_op");
        `CHECK_EQ(reg_s, 3'b000, "ADD B reg_s");

        opcode = 8'h76;
        #1;
        `CHECK_FLAG(is_halt, 1'b1, "HALT");

        opcode = 8'hC3;
        #1;
        `CHECK_FLAG(is_jp, 1'b1, "JP nn");
        `CHECK_FLAG(is_branch, 1'b1, "JP is_branch");

        opcode = 8'h07;
        #1;
        `CHECK_FLAG(is_rotate, 1'b1, "RLCA");
        `CHECK_EQ(rotate_op, 2'd0, "RLCA rotate_op");

        `TB_PASS("tb_decode");
    end
endmodule
