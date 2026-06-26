// Test harness — reg_file + ALU + flags for manual LD/ADD sequences.

module stage_datapath (
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] alu_op,
    input  wire [2:0] rs_addr,
    input  wire [2:0] rd_addr,
    input  wire [2:0] w_addr,
    input  wire       preserve_c,
    input  wire       execute,

    input  wire       reg_we,
    input  wire [2:0] reg_w_addr,
    input  wire [7:0] reg_wdata,

    output wire [7:0] alu_result,
    output wire [7:0] f_out,
    output wire [7:0] dbg_a,
    output wire [7:0] dbg_b
);
    wire [7:0] rs_data;
    wire [7:0] rd_data;
    wire       alu_carry;
    wire       alu_half;
    wire       alu_overflow;
    wire       alu_zero;
    wire       alu_negative;

    reg_file u_regs (
        .clk         (clk),
        .rst         (rst),
        .rs_addr     (rs_addr),
        .rd_addr     (rd_addr),
        .rs_data     (rs_data),
        .rd_data     (rd_data),
        .we          (reg_we || execute),
        .w_addr      (execute ? w_addr : reg_w_addr),
        .w_data      (execute ? alu_result : reg_wdata),
        .pair_we     (1'b0),
        .pair_w_sel  (2'd0),
        .pair_w_data (16'h0000),
        .pair_r_sel  (2'd0),
        .pair_r_data (),
        .f_in        (f_out),
        .dbg_a       (dbg_a),
        .dbg_b       (dbg_b),
        .dbg_c       (),
        .dbg_h       (),
        .dbg_l       ()
    );

    alu u_alu (
        .op         (alu_op),
        .a          (rs_data),
        .b          (rd_data),
        .carry_in   (1'b0),
        .result     (alu_result),
        .carry_out  (alu_carry),
        .half_carry (alu_half),
        .overflow   (alu_overflow),
        .zero       (alu_zero),
        .negative   (alu_negative)
    );

    flags u_flags (
        .clk        (clk),
        .rst        (rst),
        .update     (execute),
        .preserve_c (preserve_c),
        .scf        (1'b0),
        .ccf        (1'b0),
        .f_load     (1'b0),
        .f_wdata    (8'h00),
        .flag_s     (alu_negative),
        .flag_z     (alu_zero),
        .flag_h     (alu_half),
        .flag_pv    (alu_overflow),
        .flag_n     (alu_op[0]),
        .flag_c     (alu_carry),
        .f_out      (f_out),
        .z          (),
        .c          ()
    );
endmodule
