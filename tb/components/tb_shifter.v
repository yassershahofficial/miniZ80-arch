// Unit test — accumulator rotates.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_shifter;
    reg  [1:0] op;
    reg  [7:0] a;
    reg        carry_in;
    wire [7:0] result;
    wire       carry_out;

    shifter u_dut (
        .op        (op),
        .a         (a),
        .carry_in  (carry_in),
        .result    (result),
        .carry_out (carry_out)
    );

    initial begin
        // RLCA
        op = 2'd0; a = 8'h81; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h02, "RLCA");
        `CHECK_FLAG(carry_out, 1'b1, "RLCA carry");

        // RRCA
        op = 2'd1; a = 8'h81;
        #1;
        `CHECK_EQ(result, 8'h40, "RRCA");
        `CHECK_FLAG(carry_out, 1'b1, "RRCA carry");

        // RLA
        op = 2'd2; a = 8'h81; carry_in = 1;
        #1;
        `CHECK_EQ(result, 8'h03, "RLA");
        `CHECK_FLAG(carry_out, 1'b1, "RLA carry");

        // RRA
        op = 2'd3; a = 8'h81; carry_in = 1;
        #1;
        `CHECK_EQ(result, 8'hC0, "RRA");
        `CHECK_FLAG(carry_out, 1'b1, "RRA carry");

        `TB_PASS("tb_shifter");
    end
endmodule
