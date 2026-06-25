// RAM — stack and program variables.
// Parameterize depth once the memory map is fixed.

module ram #(
    parameter ADDR_WIDTH = 10,   // 1 KiB — adjust with ROM map
    parameter BASE_ADDR  = 16'h0400  // TBD — place RAM above ROM region
) (
    input  wire                    clk,
    input  wire [15:0]             addr,
    input  wire [7:0]              wdata,
    input  wire                    we,
    output wire [7:0]              rdata
);
    reg [7:0] mem [0:(1<<ADDR_WIDTH)-1];

    wire [ADDR_WIDTH-1:0] local_addr = addr[ADDR_WIDTH-1:0] - BASE_ADDR[ADDR_WIDTH-1:0];
    wire in_range = (addr >= BASE_ADDR) && (addr < BASE_ADDR + (1 << ADDR_WIDTH));

    assign rdata = in_range ? mem[local_addr] : 8'h00;

    always @(posedge clk) begin
        if (we && in_range)
            mem[local_addr] <= wdata;
    end

endmodule
