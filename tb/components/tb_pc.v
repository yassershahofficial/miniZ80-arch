// Unit test — program counter.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_pc;
    `TB_DUMP_VCD(tb_pc)

    reg        clk = 0;
    reg        rst = 1;
    reg        en = 0;
    reg        load = 0;
    reg [15:0] pc_in = 0;
    reg [1:0]  step = 0;
    wire [15:0] pc_out;

    always #5 clk = ~clk;

    pc u_dut (
        .clk(clk), .rst(rst), .en(en), .load(load),
        .pc_in(pc_in), .step(step), .pc_out(pc_out)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);
        `CHECK_EQ(pc_out, 16'h0000, "reset to 0");

        load = 1'b1; pc_in = 16'h1000;
        @(posedge clk);
        load = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(pc_out, 16'h1000, "load absolute");

        `TB_PASS("tb_pc");
    end
endmodule
