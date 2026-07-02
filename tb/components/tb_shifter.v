// Unit test — accumulator rotates (RLCA, RRCA, RLA, RRA).
// Matches rtl/cpu/shifter.v: bit 7/0 wrap into the opposite end.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_shifter;
    `TB_DUMP_VCD(tb_shifter)

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
        // RLCA — 81h = 1000_0001 → 0000_0011, C=1
        op = 2'd0; a = 8'h81; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h03, "RLCA");
        `CHECK_FLAG(carry_out, 1'b1, "RLCA carry");

        // RRCA — 81h = 1000_0001 → 1100_0000, C=1
        op = 2'd1; a = 8'h81; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'hC0, "RRCA");
        `CHECK_FLAG(carry_out, 1'b1, "RRCA carry");

        // RLA — shift left, C in at bit 0: 81h + C=1 → 0000_0011, C=1
        op = 2'd2; a = 8'h81; carry_in = 1;
        #1;
        `CHECK_EQ(result, 8'h03, "RLA");
        `CHECK_FLAG(carry_out, 1'b1, "RLA carry");

        // RRA — shift right, C in at bit 7: 81h + C=1 → 1100_0000, C=1
        op = 2'd3; a = 8'h81; carry_in = 1;
        #1;
        `CHECK_EQ(result, 8'hC0, "RRA");
        `CHECK_FLAG(carry_out, 1'b1, "RRA carry");

        // RLCA — 80h = 1000_0000 → 0000_0001, C=1
        op = 2'd0; a = 8'h80; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h01, "RLCA MSB only");
        `CHECK_FLAG(carry_out, 1'b1, "RLCA MSB carry");

        // RRCA — 01h = 0000_0001 → 1000_0000, C=1
        op = 2'd1; a = 8'h01; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h80, "RRCA LSB only");
        `CHECK_FLAG(carry_out, 1'b1, "RRCA LSB carry");

        `TB_PASS("tb_shifter");
    end
endmodule
