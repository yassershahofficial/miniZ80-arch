// Address and data bus mux — selects PC, HL, or SP as memory address.

module bus (
    input  wire [15:0] pc,
    input  wire [15:0] hl,
    input  wire [15:0] sp,

    input  wire [1:0]  addr_sel,   // 0=PC, 1=HL, 2=SP, 3=SP-1 (stack high byte)

    input  wire [7:0]  alu_result,
    input  wire [7:0]  reg_wdata,

    input  wire        mem_write,

    output wire [15:0] mem_addr,
    output wire [7:0]  mem_wdata
);
    // TODO: implement address mux and write-data mux

    assign mem_addr  = pc;
    assign mem_wdata = reg_wdata;

endmodule
