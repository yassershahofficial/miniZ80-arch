// Stage 3 — alu + flags + reg_file (previous: alu + flags).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage03_datapath;
    reg       clk = 0;
    reg       rst = 1;
    reg [3:0] alu_op = 0;
    reg [2:0] rs_addr = 0;
    reg [2:0] rd_addr = 0;
    reg [2:0] w_addr = 0;
    reg       preserve_c = 0;
    reg       execute = 0;
    reg       reg_we = 0;
    reg [2:0] reg_w_addr = 0;
    reg [7:0] reg_wdata = 0;
    wire [7:0] alu_result, f_out, dbg_a, dbg_b;

    always #5 clk = ~clk;

    stage_datapath u_dut (
        .clk(clk), .rst(rst),
        .alu_op(alu_op), .rs_addr(rs_addr), .rd_addr(rd_addr), .w_addr(w_addr),
        .preserve_c(preserve_c), .execute(execute),
        .reg_we(reg_we), .reg_w_addr(reg_w_addr), .reg_wdata(reg_wdata),
        .alu_result(alu_result), .f_out(f_out), .dbg_a(dbg_a), .dbg_b(dbg_b)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);

        reg_we = 1'b1; reg_w_addr = 3'b000; reg_wdata = 8'h10;
        @(posedge clk);
        reg_we = 1'b1; reg_w_addr = 3'b111; reg_wdata = 8'h20;
        @(posedge clk);
        reg_we = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(dbg_a, 8'h20, "stage03 LD A");
        `CHECK_EQ(dbg_b, 8'h10, "stage03 LD B");

        `TB_PASS("tb_stage03_datapath");
    end
endmodule
