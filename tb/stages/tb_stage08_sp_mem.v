// Stage 8 — SP + RAM (previous: fetch path).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage08_sp_mem;
    reg        clk = 0;
    reg        rst = 1;
    reg        sp_load = 0;
    reg [15:0] sp_in = 0;
    reg [15:0] mem_addr = 0;
    reg [7:0]  mem_wdata = 0;
    reg        mem_we = 0;
    wire [15:0] sp_out;
    wire [7:0]  mem_rdata;

    always #5 clk = ~clk;

    sp u_sp (
        .clk(clk), .rst(rst), .load(sp_load), .sp_in(sp_in),
        .dec2(1'b0), .inc2(1'b0), .inc1(1'b0), .dec1(1'b0),
        .sp_out(sp_out)
    );

    ram u_ram (
        .clk(clk), .addr(mem_addr), .wdata(mem_wdata),
        .we(mem_we), .rdata(mem_rdata)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);

        sp_load = 1'b1; sp_in = 16'h0410;
        @(posedge clk);
        sp_load = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(sp_out, 16'h0410, "stage08 SP load");

        @(posedge clk);
        mem_addr = 16'h0400; mem_wdata = 8'hAB; mem_we = 1'b1;
        @(posedge clk);
        mem_we = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(mem_rdata, 8'hAB, "stage08 RAM write/read");

        `TB_PASS("tb_stage08_sp_mem");
    end
endmodule
