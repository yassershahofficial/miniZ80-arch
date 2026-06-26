// Stage 2 — ALU + flags (previous: alu only).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage02_alu_flags;
    reg       clk = 0;
    reg       rst = 1;
    reg [3:0] op = 0;
    reg [7:0] a = 0;
    reg [7:0] b = 0;
    reg       carry_in = 0;
    reg       preserve_c = 0;
    reg       execute = 0;
    wire [7:0] result, f_out;
    wire       z, c;

    always #5 clk = ~clk;

    stage_alu_flags u_dut (
        .clk(clk), .rst(rst), .op(op), .a(a), .b(b),
        .carry_in(carry_in), .preserve_c(preserve_c), .execute(execute),
        .result(result), .f_out(f_out), .z(z), .c(c)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);
        op = 4'd0; a = 8'hFF; b = 8'h01;
        execute = 1'b1;
        @(posedge clk);
        execute = 1'b0;
        @(negedge clk);
        `CHECK_FLAG(z, 1'b1, "stage02 zero flag latched");
        `CHECK_FLAG(c, 1'b1, "stage02 carry latched");
        `TB_PASS("tb_stage02_alu_flags");
    end
endmodule
