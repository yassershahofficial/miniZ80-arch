// Test harness — PC fetches bytes from ROM; insn_meta reports length.

module stage_fetch #(
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE  = "firmware/stage07_fetch.hex"
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        pc_en,
    input  wire [1:0]  pc_step,

    output wire [15:0] pc_out,
    output wire [7:0]  opcode,
    output wire [1:0]  insn_len,
    output wire        illegal
);
    pc u_pc (
        .clk    (clk),
        .rst    (rst),
        .en     (pc_en),
        .load   (1'b0),
        .pc_in  (16'h0000),
        .step   (pc_step),
        .pc_out (pc_out)
    );

    wire [7:0] rom_data;

    rom #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .INIT_FILE  (INIT_FILE)
    ) u_rom (
        .addr (pc_out[ADDR_WIDTH-1:0]),
        .data (rom_data)
    );

    assign opcode = rom_data;

    insn_meta u_meta (
        .opcode    (opcode),
        .insn_len  (insn_len),
        .illegal   (illegal),
        .hl_read   (),
        .hl_write  (),
        .stack_op  ()
    );
endmodule
