// Unit test — stack pointer.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_sp;
    `TB_DUMP_VCD(tb_sp)

    reg        clk = 0;
    reg        rst = 1;
    reg        load = 0;
    reg [15:0] sp_in = 0;
    reg        dec2 = 0;
    reg        inc2 = 0;
    reg        inc1 = 0;
    reg        dec1 = 0;
    wire [15:0] sp_out;

    always #5 clk = ~clk;

    sp u_dut (
        .clk(clk), .rst(rst), .load(load), .sp_in(sp_in),
        .dec2(dec2), .inc2(inc2), .inc1(inc1), .dec1(dec1),
        .sp_out(sp_out)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);

        load = 1'b1; sp_in = 16'h0410;
        @(posedge clk);
        load = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(sp_out, 16'h0410, "LD SP,nn");

        `TB_PASS("tb_sp");
    end
endmodule
