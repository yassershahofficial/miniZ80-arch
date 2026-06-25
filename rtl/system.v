// System top — connects CPU, ROM, and RAM.

module system #(
    parameter INIT_FILE = "firmware/milestone.hex"
) (
    input  wire       clk,
    input  wire       rst,

    output wire       halt,
    output wire [7:0] dbg_a,
    output wire [7:0] dbg_b,
    output wire [7:0] dbg_c,
    output wire [7:0] dbg_h,
    output wire [7:0] dbg_l,
    output wire [15:0] dbg_sp
);
    wire [15:0] mem_addr;
    wire [7:0]  mem_rdata;
    wire [7:0]  mem_wdata;
    wire        mem_read;
    wire        mem_write;

    wire rom_sel = (mem_addr < 16'h0400);
    wire ram_sel = !rom_sel;

    wire [7:0] rom_data;
    wire [7:0] ram_data;

    cpu_core u_cpu (
        .clk       (clk),
        .rst       (rst),
        .halt      (halt),
        .dbg_a     (dbg_a),
        .dbg_b     (dbg_b),
        .dbg_c     (dbg_c),
        .dbg_h     (dbg_h),
        .dbg_l     (dbg_l),
        .dbg_sp    (dbg_sp),
        .mem_addr  (mem_addr),
        .mem_rdata (mem_rdata),
        .mem_wdata (mem_wdata),
        .mem_read  (mem_read),
        .mem_write (mem_write)
    );

    rom #(
        .ADDR_WIDTH (10),
        .INIT_FILE  (INIT_FILE)
    ) u_rom (
        .addr (mem_addr[9:0]),
        .data (rom_data)
    );

    ram u_ram (
        .clk   (clk),
        .addr  (mem_addr),
        .wdata (mem_wdata),
        .we    (mem_write && ram_sel),
        .rdata (ram_data)
    );

    assign mem_rdata = rom_sel ? rom_data : ram_data;

endmodule
