// Stage 4 : shifter + flags (previous: datapath with reg_file).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_stage04_shifter;
    reg       clk = 0;
    reg       rst = 1;
    reg [1:0] sh_op = 0;
    reg [7:0] a = 0;
    reg       carry_in = 0;
    reg       rotate_exec = 0;
    wire [7:0] sh_result;
    wire       sh_carry;
    wire [7:0] f_out;

    always #5 clk = ~clk;

    shifter u_shifter (
        .op(sh_op), .a(a), .carry_in(carry_in),
        .result(sh_result), .carry_out(sh_carry)
    );

    flags u_flags (
        .clk(clk), .rst(rst),
        .update(rotate_exec),
        .preserve_c(1'b0),
        .scf(1'b0), .ccf(1'b0), .f_load(1'b0), .f_wdata(8'h00),
        .flag_s(1'b0), .flag_z(1'b0), .flag_h(1'b0),
        .flag_pv(1'b0), .flag_n(1'b0), .flag_c(sh_carry),
        .f_out(f_out), .z(), .c()
    );

    initial begin
        #20 rst = 0;
        @(posedge clk);
        sh_op = 2'd0; a = 8'h81;
        rotate_exec = 1'b1;
        @(posedge clk);
        rotate_exec = 1'b0;
        @(negedge clk);
        `CHECK_EQ(sh_result, 8'h02, "stage04 RLCA result");
        `CHECK_EQ(f_out, 8'b0000_0001, "stage04 C only");
        `TB_PASS("tb_stage04_shifter");
    end
endmodule
