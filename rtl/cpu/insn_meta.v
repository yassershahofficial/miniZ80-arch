// Combinational instruction metadata from the first opcode byte.
// See docs/isa.md — full first-byte lookup table.

module insn_meta (
    input  wire [7:0] opcode,

    output reg  [1:0] insn_len,   // 1, 2, or 3
    output reg        illegal,
    output reg        hl_read,
    output reg        hl_write,
    output reg        stack_op
);
    always @(*) begin
        insn_len  = 2'd1;
        illegal   = 1'b0;
        hl_read   = 1'b0;
        hl_write  = 1'b0;
        stack_op  = 1'b0;

        case (opcode)
            8'h01, 8'h11, 8'h21, 8'h31,
            8'hC3, 8'hCD, 8'hC4, 8'hCC, 8'hD4, 8'hDC:
                insn_len = 2'd3;

            8'h06, 8'h0E, 8'h16, 8'h1E, 8'h26, 8'h2E, 8'h36, 8'h3E,
            8'h10, 8'h18, 8'h20, 8'h28, 8'h30, 8'h38,
            8'hC6, 8'hD6, 8'hE6, 8'hEE, 8'hF6, 8'hFE:
                insn_len = 2'd2;

            default: insn_len = 2'd1;
        endcase

        // Legal single-byte opcodes not covered above
        if (insn_len == 2'd1) begin
            case (opcode)
                8'h00, 8'h03, 8'h04, 8'h05, 8'h07, 8'h0B, 8'h0C, 8'h0D, 8'h0F,
                8'h13, 8'h14, 8'h15, 8'h17, 8'h1B, 8'h1C, 8'h1D, 8'h1F,
                8'h23, 8'h24, 8'h25, 8'h2B, 8'h2C, 8'h2D, 8'h33, 8'h34, 8'h35,
                8'h37, 8'h3B, 8'h3C, 8'h3D, 8'h3F, 8'h76,
                8'hC0, 8'hC1, 8'hC5, 8'hC8, 8'hC9, 8'hD0, 8'hD1, 8'hD5,
                8'hD8, 8'hE1, 8'hE5, 8'hF1, 8'hF5:
                    illegal = 1'b0;
                default: begin
                    if ((opcode >= 8'h40 && opcode <= 8'h7F) ||
                        (opcode >= 8'h80 && opcode <= 8'h87) ||
                        (opcode >= 8'h90 && opcode <= 8'h97) ||
                        (opcode >= 8'hA0 && opcode <= 8'hA7) ||
                        (opcode >= 8'hA8 && opcode <= 8'hAF) ||
                        (opcode >= 8'hB0 && opcode <= 8'hB7) ||
                        (opcode >= 8'hB8 && opcode <= 8'hBF))
                        illegal = 1'b0;
                    else
                        illegal = 1'b1;
                end
            endcase
        end

        // (HL) access flags — used by future memory cycles
        if (opcode >= 8'h40 && opcode <= 8'h7F && opcode != 8'h76) begin
            if (opcode[2:0] == 3'b110 && opcode[5:3] != 3'b110)
                hl_read = 1'b1;
            if (opcode[5:3] == 3'b110 && opcode[2:0] != 3'b110)
                hl_write = 1'b1;
        end
        if ((opcode >= 8'h80 && opcode <= 8'h87) ||
            (opcode >= 8'h90 && opcode <= 8'h97) ||
            (opcode >= 8'hA0 && opcode <= 8'hA7) ||
            (opcode >= 8'hA8 && opcode <= 8'hAF) ||
            (opcode >= 8'hB0 && opcode <= 8'hB7) ||
            (opcode >= 8'hB8 && opcode <= 8'hBF)) begin
            if (opcode[2:0] == 3'b110)
                hl_read = 1'b1;
        end
        if (opcode == 8'h36)
            hl_write = 1'b1;
        if (opcode == 8'h34 || opcode == 8'h35) begin
            hl_read  = 1'b1;
            hl_write = 1'b1;
        end

        if (opcode == 8'hC1 || opcode == 8'hC5 || opcode == 8'hD1 || opcode == 8'hD5 ||
            opcode == 8'hE1 || opcode == 8'hE5 || opcode == 8'hF1 || opcode == 8'hF5 ||
            opcode == 8'hC0 || opcode == 8'hC8 || opcode == 8'hC9 || opcode == 8'hD0 ||
            opcode == 8'hD8 || opcode == 8'hCD || opcode == 8'hC4 || opcode == 8'hCC ||
            opcode == 8'hD4 || opcode == 8'hDC)
            stack_op = 1'b1;
    end
endmodule
