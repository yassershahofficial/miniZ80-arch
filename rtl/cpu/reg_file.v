// Register file: A, F, B, C, D, E, H, L

module reg_file (
    input  wire       clk,
    input  wire       rst,

    input  wire [2:0] rs_addr,
    input  wire [2:0] rd_addr,
    output wire [7:0] rs_data,
    output wire [7:0] rd_data,

    input  wire       we,
    input  wire [2:0] w_addr,
    input  wire [7:0] w_data,

    input  wire       pair_we,
    input  wire [1:0] pair_w_sel,
    input  wire [15:0] pair_w_data,

    input  wire [1:0] pair_r_sel,
    output wire [15:0] pair_r_data,

    input  wire [7:0] f_in,

    output wire [7:0] dbg_a,
    output wire [7:0] dbg_b,
    output wire [7:0] dbg_c,
    output wire [7:0] dbg_h,
    output wire [7:0] dbg_l
);
    reg [7:0] B, C, D, E, H, L, A;

    function [7:0] read_reg;
        input [2:0] addr;
        begin
            case (addr)
                3'b000: read_reg = B;
                3'b001: read_reg = C;
                3'b010: read_reg = D;
                3'b011: read_reg = E;
                3'b100: read_reg = H;
                3'b101: read_reg = L;
                3'b110: read_reg = 8'h00; // (HL) not stored here
                3'b111: read_reg = A;
                default: read_reg = 8'h00;
            endcase
        end
    endfunction

    assign rs_data = read_reg(rs_addr);
    assign rd_data = read_reg(rd_addr);

    assign pair_r_data =
        (pair_r_sel == 2'd0) ? {B, C} :
        (pair_r_sel == 2'd1) ? {D, E} :
        (pair_r_sel == 2'd2) ? {H, L} :
                               {A, f_in};

    assign dbg_a = A;
    assign dbg_b = B;
    assign dbg_c = C;
    assign dbg_h = H;
    assign dbg_l = L;

    always @(posedge clk) begin
        if (rst) begin
            B <= 8'h00;
            C <= 8'h00;
            D <= 8'h00;
            E <= 8'h00;
            H <= 8'h00;
            L <= 8'h00;
            A <= 8'h00;
        end else begin
            if (we) begin
                case (w_addr)
                    3'b000: B <= w_data;
                    3'b001: C <= w_data;
                    3'b010: D <= w_data;
                    3'b011: E <= w_data;
                    3'b100: H <= w_data;
                    3'b101: L <= w_data;
                    3'b111: A <= w_data;
                    default: ;
                endcase
            end
            if (pair_we) begin
                case (pair_w_sel)
                    2'd0: {B, C} <= pair_w_data;
                    2'd1: {D, E} <= pair_w_data;
                    2'd2: {H, L} <= pair_w_data;
                    2'd3: A <= pair_w_data[15:8];
                    default: ;
                endcase
            end
        end
    end
endmodule
