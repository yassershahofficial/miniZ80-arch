// ALU — 8-bit ADD, SUB, AND, OR, XOR, CP.

module alu (
    input  wire [3:0]  op,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire        carry_in,

    output reg  [7:0]  result,
    output reg         carry_out,
    output reg         half_carry,
    output reg         overflow,
    output reg         zero,
    output reg         negative
);
    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_AND = 4'd2;
    localparam OP_XOR = 4'd3;
    localparam OP_OR  = 4'd4;
    localparam OP_CP  = 4'd5;
    localparam OP_INC = 4'd6;
    localparam OP_DEC = 4'd7;

    wire [8:0] inc_sum = {1'b0, a} + 9'd1;
    wire [8:0] dec_diff = {1'b0, a} - 9'd1;
    wire [8:0] add_sum = {1'b0, a} + {1'b0, b};
    wire [8:0] sub_diff = {1'b0, a} - {1'b0, b};

    function parity_even;
        input [7:0] v;
        begin
            parity_even = ~(^v);
        end
    endfunction

    always @(*) begin
        result      = 8'h00;
        carry_out   = 1'b0;
        half_carry  = 1'b0;
        overflow    = 1'b0;
        zero        = 1'b0;
        negative    = 1'b0;

        case (op)
            OP_ADD, OP_SUB, OP_CP: begin
                if (op == OP_ADD) begin
                    result     = add_sum[7:0];
                    carry_out  = add_sum[8];
                    half_carry = ((a[3:0] + b[3:0]) > 4'hF);
                    overflow   = (a[7] == b[7]) && (result[7] != a[7]);
                end else begin
                    result     = sub_diff[7:0];
                    carry_out  = sub_diff[8];
                    half_carry = (a[3:0] < b[3:0]);
                    overflow   = (a[7] != b[7]) && (result[7] != a[7]);
                end
                zero     = (result == 8'h00);
                negative = result[7];
            end

            OP_AND: begin
                result     = a & b;
                half_carry = 1'b1;
                zero       = (result == 8'h00);
                negative   = result[7];
                overflow   = parity_even(result);
            end

            OP_XOR: begin
                result     = a ^ b;
                half_carry = 1'b0;
                zero       = (result == 8'h00);
                negative   = result[7];
                overflow   = parity_even(result);
            end

            OP_OR: begin
                result     = a | b;
                half_carry = 1'b0;
                zero       = (result == 8'h00);
                negative   = result[7];
                overflow   = parity_even(result);
            end

            OP_INC: begin
                result     = inc_sum[7:0];
                carry_out  = inc_sum[8];
                half_carry = (a[3:0] == 4'hF);
                overflow   = (a == 8'h7F);
                zero       = (result == 8'h00);
                negative   = result[7];
            end

            OP_DEC: begin
                result     = dec_diff[7:0];
                carry_out  = dec_diff[8];
                half_carry = (a[3:0] == 4'h0);
                overflow   = (a == 8'h80);
                zero       = (result == 8'h00);
                negative   = result[7];
            end

            default: ;
        endcase
    end

endmodule
