// Stack pointer — used by PUSH, POP, CALL, RET.

module sp (
    input  wire        clk,
    input  wire        rst,

    input  wire        load,       // LD SP,nn
    input  wire [15:0] sp_in,

    input  wire        dec2,       // before PUSH
    input  wire        inc2,       // after POP
    input  wire        inc1,       // INC SP
    input  wire        dec1,       // DEC SP

    output wire [15:0] sp_out
);
    reg [15:0] sp_reg;

    always @(posedge clk) begin
        if (rst)
            sp_reg <= 16'h0000;
        else if (load)
            sp_reg <= sp_in;
        else if (dec2)
            sp_reg <= sp_reg - 16'd2;
        else if (inc2)
            sp_reg <= sp_reg + 16'd2;
        else if (inc1)
            sp_reg <= sp_reg + 16'd1;
        else if (dec1)
            sp_reg <= sp_reg - 16'd1;
    end

    assign sp_out = sp_reg;

endmodule
