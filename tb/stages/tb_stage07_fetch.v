// Stage 7 "" PC + insn_meta + ROM (previous: PC).
// Proves PC=0 reads first ROM byte; full PC advance is covered in tb_cpu.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage07_fetch;
    reg       clk = 0;
    reg       rst = 1;
    reg       pc_en = 0;
    reg [1:0] pc_step = 0;
    wire [15:0] pc_out;
    wire [7:0]  opcode;
    wire [1:0]  insn_len;
    wire        illegal;

    always #5 clk = ~clk;

    stage_fetch u_dut (
        .clk(clk), .rst(rst),
        .pc_en(pc_en), .pc_step(pc_step),
        .pc_out(pc_out), .opcode(opcode),
        .insn_len(insn_len), .illegal(illegal)
    );

    wire [1:0] len_ld_a_n;
    wire       illegal_ld_a_n;

    insn_meta u_meta_ld (
        .opcode   (8'h3E),
        .insn_len (len_ld_a_n),
        .illegal  (illegal_ld_a_n),
        .hl_read  (), .hl_write (), .stack_op ()
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);
        `CHECK_EQ(pc_out, 16'h0000, "stage07 PC starts at 0");
        `CHECK_EQ(opcode, 8'h00, "stage07 fetch NOP from ROM");
        `CHECK_EQ(insn_len, 2'd1, "stage07 NOP len");
        `CHECK_EQ(len_ld_a_n, 2'd2, "stage07 LD A,n len from meta");

        `TB_PASS("tb_stage07_fetch");
    end
endmodule
