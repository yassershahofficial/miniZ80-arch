// Unit test — instruction metadata lookup.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_insn_meta;
    reg  [7:0] opcode;
    wire [1:0] insn_len;
    wire       illegal;
    wire       hl_read;
    wire       hl_write;
    wire       stack_op;

    insn_meta u_dut (
        .opcode    (opcode),
        .insn_len  (insn_len),
        .illegal   (illegal),
        .hl_read   (hl_read),
        .hl_write  (hl_write),
        .stack_op  (stack_op)
    );

    initial begin
        opcode = 8'h00;
        #1;
        `CHECK_EQ(insn_len, 2'd1, "NOP len=1");
        `CHECK_FLAG(illegal, 1'b0, "NOP legal");

        opcode = 8'h3E;
        #1;
        `CHECK_EQ(insn_len, 2'd2, "LD A,n len=2");

        opcode = 8'hC3;
        #1;
        `CHECK_EQ(insn_len, 2'd3, "JP nn len=3");

        opcode = 8'h7E;
        #1;
        `CHECK_FLAG(hl_read, 1'b1, "LD A,(HL) hl_read");

        opcode = 8'h77;
        #1;
        `CHECK_FLAG(hl_write, 1'b1, "LD (HL),A hl_write");

        opcode = 8'hC5;
        #1;
        `CHECK_FLAG(stack_op, 1'b1, "PUSH BC stack_op");

        opcode = 8'hCB;
        #1;
        `CHECK_FLAG(illegal, 1'b1, "prefix CB illegal");

        `TB_PASS("tb_insn_meta");
    end
endmodule
