// Unit test — register file A,B,C,D,E,H,L.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_reg_file;
    `TB_DUMP_VCD(tb_reg_file)

    reg        clk = 0;
    reg        rst = 1;
    reg  [2:0] rs_addr = 0;
    reg  [2:0] rd_addr = 0;
    wire [7:0] rs_data;
    wire [7:0] rd_data;
    reg        we = 0;
    reg  [2:0] w_addr = 0;
    reg  [7:0] w_data = 0;
    reg        pair_we = 0;
    reg  [1:0] pair_w_sel = 0;
    reg  [15:0] pair_w_data = 0;
    reg  [1:0] pair_r_sel = 0;
    wire [15:0] pair_r_data;
    reg  [7:0] f_in = 0;
    wire [7:0] dbg_a, dbg_b, dbg_c, dbg_h, dbg_l;

    always #5 clk = ~clk;

    reg_file u_dut (
        .clk(clk), .rst(rst),
        .rs_addr(rs_addr), .rd_addr(rd_addr),
        .rs_data(rs_data), .rd_data(rd_data),
        .we(we), .w_addr(w_addr), .w_data(w_data),
        .pair_we(pair_we), .pair_w_sel(pair_w_sel), .pair_w_data(pair_w_data),
        .pair_r_sel(pair_r_sel), .pair_r_data(pair_r_data),
        .f_in(f_in),
        .dbg_a(dbg_a), .dbg_b(dbg_b), .dbg_c(dbg_c),
        .dbg_h(dbg_h), .dbg_l(dbg_l)
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);

        w_addr = 3'b111; w_data = 8'h42; we = 1'b1;
        @(posedge clk);
        we = 1'b0;
        @(posedge clk);

        w_addr = 3'b000; w_data = 8'h12; we = 1'b1;
        @(posedge clk);
        we = 1'b0;
        @(posedge clk);

        w_addr = 3'b001; w_data = 8'h34; we = 1'b1;
        @(posedge clk);
        we = 1'b0;
        @(negedge clk);

        `CHECK_EQ(dbg_a, 8'h42, "read A");
        `CHECK_EQ(dbg_b, 8'h12, "read B");
        `CHECK_EQ(dbg_c, 8'h34, "read C");

        rs_addr = 3'b110;
        @(negedge clk);
        `CHECK_EQ(rs_data, 8'h00, "(HL) addr reads 0");

        @(posedge clk);
        pair_we = 1'b1; pair_w_sel = 2'd0; pair_w_data = 16'hABCD;
        @(posedge clk);
        pair_we = 1'b0;
        @(posedge clk);
        @(negedge clk);
        `CHECK_EQ(dbg_b, 8'hAB, "pair write B");
        `CHECK_EQ(dbg_c, 8'hCD, "pair write C");

        pair_r_sel = 2'd0;
        @(negedge clk);
        `CHECK_EQ(pair_r_data, 16'hABCD, "pair read BC");

        f_in = 8'hF0;
        pair_r_sel = 2'd3;
        @(negedge clk);
        `CHECK_EQ(pair_r_data, {8'h42, 8'hF0}, "pair read AF");

        `TB_PASS("tb_reg_file");
    end
endmodule
