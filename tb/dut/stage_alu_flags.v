// Test harness — ALU result and flags latched on execute pulse.

module stage_alu_flags (
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] op,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       carry_in,
    input  wire       preserve_c,
    input  wire       execute,

    output wire [7:0] result,
    output wire [7:0] f_out,
    output wire       z,
    output wire       c
);
    wire       alu_carry;
    wire       alu_half;
    wire       alu_overflow;
    wire       alu_zero;
    wire       alu_negative;

    alu u_alu (
        .op         (op),
        .a          (a),
        .b          (b),
        .carry_in   (carry_in),
        .result     (result),
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
        .flag_n     (op[0]),
        .flag_c     (alu_carry),
        .f_out      (f_out),
        .z          (z),
        .c          (c)
    );
endmodule
