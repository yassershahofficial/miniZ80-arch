// Unit test — flag register F.

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_flags;
    reg       clk = 0;
    reg       rst = 1;
    reg       update = 0;
    reg       preserve_c = 0;
    reg       scf = 0;
    reg       ccf = 0;
    reg       f_load = 0;
    reg [7:0] f_wdata = 0;
    reg       flag_s = 0;
    reg       flag_z = 0;
    reg       flag_h = 0;
    reg       flag_pv = 0;
    reg       flag_n = 0;
    reg       flag_c = 0;
    wire [7:0] f_out;
    wire       z;
    wire       c;

    always #5 clk = ~clk;

    flags u_dut (
        .clk(clk), .rst(rst), .update(update), .preserve_c(preserve_c),
        .scf(scf), .ccf(ccf), .f_load(f_load), .f_wdata(f_wdata),
        .flag_s(flag_s), .flag_z(flag_z), .flag_h(flag_h),
        .flag_pv(flag_pv), .flag_n(flag_n), .flag_c(flag_c),
        .f_out(f_out), .z(z), .c(c)
    );

    initial begin
        // --- update from ALU ---
        #20 rst = 0;
        @(posedge clk);
        flag_s = 1'b1; flag_z = 1'b0; flag_h = 1'b1;
        flag_pv = 1'b0; flag_n = 1'b0; flag_c = 1'b1;
        update = 1'b1;
        @(posedge clk);
        update = 1'b0;
        @(negedge clk);
        `CHECK_EQ(f_out, 8'b1001_0001, "update from ALU");

        // --- SCF ---
        update = 1'b0;
        scf = 1'b0;
        ccf = 1'b0;
        f_load = 1'b0;
        preserve_c = 1'b0;
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        scf = 1'b1;
        @(posedge clk);
        scf = 1'b0;
        @(negedge clk);
        `CHECK_EQ(f_out, 8'b0001_0001, "SCF");

        // --- preserve_c ---
        update = 1'b0;
        scf = 1'b0;
        ccf = 1'b0;
        f_load = 1'b0;
        preserve_c = 1'b0;
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        scf = 1'b1;
        @(posedge clk);
        scf = 1'b0;
        @(posedge clk);
        update = 1'b1;
        preserve_c = 1'b1;
        flag_z = 1'b1;
        flag_c = 1'b0;
        @(posedge clk);
        update = 1'b0;
        preserve_c = 1'b0;
        @(negedge clk);
        `CHECK_FLAG(c, 1'b1, "preserve_c keeps C");

        // --- f_load (POP AF upper nibble) ---
        update = 1'b0;
        scf = 1'b0;
        ccf = 1'b0;
        f_load = 1'b0;
        preserve_c = 1'b0;
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        f_load = 1'b1;
        f_wdata = 8'hA5;
        @(posedge clk);
        f_load = 1'b0;
        @(negedge clk);
        `CHECK_EQ(f_out, 8'hA0, "f_load upper nibble only");

        `TB_PASS("tb_flags");
    end
endmodule
