// Instruction fetch — reads opcode and operands from memory.
// The first byte alone identifies the instruction (see docs/isa.md).

module fetch (
    input  wire        clk,
    input  wire        rst,

    input  wire [15:0] pc,
    input  wire [7:0]  mem_data,
    input  wire        advance,    // pulse to consume next byte

    output reg  [7:0]  opcode,
    output reg  [7:0]  imm8,       // n or e
    output reg  [15:0] imm16,      // nn (little-endian)
    output reg  [1:0]  insn_len,   // 1, 2, or 3 bytes total
    output reg         hl_read,
    output reg         hl_write,
    output reg         stack_op,
    output reg         illegal
);
    // TODO: implement byte latch sequence and 256-entry length lookup from isa.md

endmodule
