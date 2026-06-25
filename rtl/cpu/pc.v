// Program counter — points at current instruction/operand in memory.

module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire        load,
    input  wire [15:0] pc_in,
    input  wire [1:0]  step,       // 0:+1  1:+2  2:+3
    output wire [15:0] pc_out
);
    reg [15:0] pc_reg;

    always @(posedge clk) begin
        if (rst)
            pc_reg <= 16'h0000;
        else if (load)
            pc_reg <= pc_in;
        else if (en) begin
            case (step)
                2'd0: pc_reg <= pc_reg + 16'd1;
                2'd1: pc_reg <= pc_reg + 16'd2;
                2'd2: pc_reg <= pc_reg + 16'd3;
                default: pc_reg <= pc_reg + 16'd1;
            endcase
        end
    end

    assign pc_out = pc_reg;
endmodule
