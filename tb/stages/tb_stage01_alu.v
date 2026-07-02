// Stage 1 : ALU only (combinational datapath arithmetic).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage01_alu;
    reg  [3:0] op;
    reg  [7:0] a;
    reg  [7:0] b;
    reg        carry_in;
    wire [7:0] result;
    wire       carry_out, half_carry, overflow, zero, negative;

    alu u_dut (
        .op(op), .a(a), .b(b), .carry_in(carry_in),
        .result(result), .carry_out(carry_out), .half_carry(half_carry),
        .overflow(overflow), .zero(zero), .negative(negative)
    );

    initial begin
        op = 4'd0; a = 8'h0A; b = 8'h05; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h0F, "stage01 ADD");
        `TB_PASS("tb_stage01_alu");
    end
endmodule
