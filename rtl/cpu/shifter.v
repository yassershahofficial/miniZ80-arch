// Accumulator rotates — RLCA, RRCA, RLA, RRA.

module shifter (
    input  wire [1:0]  op,       // 0=RLCA, 1=RRCA, 2=RLA, 3=RRA
    input  wire [7:0]  a,
    input  wire        carry_in,

    output wire [7:0]  result,
    output wire        carry_out
);
    wire [7:0] rlca = {a[6:0], 1'b0};
    wire [7:0] rrca = {1'b0, a[7:1]};
    wire [7:0] rla  = {a[6:0], carry_in};
    wire [7:0] rra  = {carry_in, a[7:1]};

    assign result =
        (op == 2'd0) ? rlca :
        (op == 2'd1) ? rrca :
        (op == 2'd2) ? rla :
        rra;

    assign carry_out =
        (op == 2'd0) ? a[7] :
        (op == 2'd1) ? a[0] :
        (op == 2'd2) ? a[7] :
        a[0];

endmodule
