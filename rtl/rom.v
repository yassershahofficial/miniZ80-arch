// ROM hardware module — loads a program image from firmware/ at simulation time.
// Parameterize depth once final ROM size is chosen.

module rom #(
    parameter ADDR_WIDTH = 10,  // 1 KiB — adjust later
    parameter INIT_FILE  = "firmware/milestone.hex"
) (
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [7:0]            data
);
    reg [7:0] mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    assign data = mem[addr];
endmodule
