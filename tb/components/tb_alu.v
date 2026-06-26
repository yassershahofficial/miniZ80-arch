// Unit test for ALU combinational operations.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_alu;
    reg  [3:0] op;
    reg  [7:0] a;
    reg  [7:0] b;
    reg        carry_in;
    wire [7:0] result;
    wire       carry_out;
    wire       half_carry;
    wire       overflow;
    wire       zero;
    wire       negative;

    alu u_dut (
        .op         (op),
        .a          (a),
        .b          (b),
        .carry_in   (carry_in),
        .result     (result),
        .carry_out  (carry_out),
        .half_carry (half_carry),
        .overflow   (overflow),
        .zero       (zero),
        .negative   (negative)
    );

    initial begin
        // ADD 10h, 20h
        op = 4'd0; a = 8'h10; b = 8'h20; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h30, "ADD basic");
        `CHECK_FLAG(carry_out, 1'b0, "ADD no carry");
        `CHECK_FLAG(zero, 1'b0, "ADD not zero");

        // ADD FFh, 01h
        a = 8'hFF; b = 8'h01;
        #1;
        `CHECK_EQ(result, 8'h00, "ADD wrap");
        `CHECK_FLAG(carry_out, 1'b1, "ADD carry");
        `CHECK_FLAG(zero, 1'b1, "ADD zero flag");

        // ADD 7Fh, 01h
        a = 8'h7F; b = 8'h01;
        #1;
        `CHECK_FLAG(overflow, 1'b1, "ADD overflow 7F+1");

        // SUB / CP — carry_out = sub_diff[8]
        // SUB 50h, 30h
        op = 4'd1; a = 8'h50; b = 8'h30; carry_in = 0;
        #1;
        `CHECK_EQ(result, 8'h20, "SUB basic");
        `CHECK_FLAG(carry_out, 1'b0, "SUB no underflow");

        // SUB 10h, 20h
        a = 8'h10; b = 8'h20;
        #1;
        `CHECK_FLAG(carry_out, 1'b1, "SUB underflow");

        // CP 42h, 42h
        op = 4'd5; a = 8'h42; b = 8'h42;
        #1;
        `CHECK_FLAG(zero, 1'b1, "CP equal");

        // AND / XOR / OR
        // AND F0, 0F
        op = 4'd2; a = 8'hF0; b = 8'h0F;
        #1;
        `CHECK_EQ(result, 8'h00, "AND");
        `CHECK_FLAG(zero, 1'b1, "AND zero");

        // XOR AAh, 55h
        op = 4'd3; a = 8'hAA; b = 8'h55;
        #1;
        `CHECK_EQ(result, 8'hFF, "XOR");

        // OR F0h, 0Fh
        op = 4'd4; a = 8'hF0; b = 8'h0F;
        #1;
        `CHECK_EQ(result, 8'hFF, "OR");

        // INC / DEC
        op = 4'd6; a = 8'hFF;
        #1;
        `CHECK_EQ(result, 8'h00, "INC FF");
        `CHECK_FLAG(carry_out, 1'b1, "INC carry");

        op = 4'd7; a = 8'h01;
        #1;
        `CHECK_EQ(result, 8'h00, "DEC 01");
        `CHECK_FLAG(zero, 1'b1, "DEC zero");

        `TB_PASS("tb_alu");
    end
endmodule
