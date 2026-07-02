// CPU system testbench — drives clock/reset, runs program until HALT.

`timescale 1ns / 1ps

`ifndef FIRMWARE
`define FIRMWARE "firmware/milestone.hex"
`endif

`ifndef EXPECT_A
`define EXPECT_A 8'h42
`endif

`ifndef EXPECT_B
`define EXPECT_B 8'h00
`endif

`ifndef EXPECT_C
`define EXPECT_C 8'h00
`endif

`ifndef EXPECT_H
`define EXPECT_H 8'h00
`endif

`ifndef EXPECT_L
`define EXPECT_L 8'h00
`endif

`ifndef EXPECT_SP
`define EXPECT_SP 16'h0000
`endif

module tb_cpu;
    `ifdef DUMP_VCD
    initial begin
        $dumpfile(`VCD_FILE);
        $dumpvars(0, tb_cpu);
    end
    `endif

    reg clk = 0;
    reg rst = 1;
    wire halt;
    wire [7:0] dbg_a;
    wire [7:0] dbg_b;
    wire [7:0] dbg_c;
    wire [7:0] dbg_h;
    wire [7:0] dbg_l;
    wire [15:0] dbg_sp;

    always #10 clk = ~clk;

    system #(
        .INIT_FILE (`FIRMWARE)
    ) u_dut (
        .clk    (clk),
        .rst    (rst),
        .halt   (halt),
        .dbg_a  (dbg_a),
        .dbg_b  (dbg_b),
        .dbg_c  (dbg_c),
        .dbg_h  (dbg_h),
        .dbg_l  (dbg_l),
        .dbg_sp (dbg_sp)
    );

    initial begin
        $display("tb_cpu: firmware=%s", `FIRMWARE);
        #25 rst = 0;

        wait (halt);
        $display("tb_cpu: HALT  A=%02X B=%02X C=%02X H=%02X L=%02X SP=%04X",
                 dbg_a, dbg_b, dbg_c, dbg_h, dbg_l, dbg_sp);

        `ifndef SKIP_CHECK
        if (dbg_a !== `EXPECT_A) begin
            $display("tb_cpu: FAIL — expected A=%02X", `EXPECT_A);
            $fatal(1);
        end
        if (dbg_b !== `EXPECT_B) begin
            $display("tb_cpu: FAIL — expected B=%02X", `EXPECT_B);
            $fatal(1);
        end
        if (dbg_c !== `EXPECT_C) begin
            $display("tb_cpu: FAIL — expected C=%02X", `EXPECT_C);
            $fatal(1);
        end
        if (dbg_h !== `EXPECT_H) begin
            $display("tb_cpu: FAIL — expected H=%02X", `EXPECT_H);
            $fatal(1);
        end
        if (dbg_l !== `EXPECT_L) begin
            $display("tb_cpu: FAIL — expected L=%02X", `EXPECT_L);
            $fatal(1);
        end
        if (dbg_sp !== `EXPECT_SP) begin
            $display("tb_cpu: FAIL — expected SP=%04X", `EXPECT_SP);
            $fatal(1);
        end
        `endif

        $display("tb_cpu: PASS");
        $finish;
    end

    initial begin
        #1000000;
        $display("tb_cpu: FAIL — timeout");
        $fatal(1);
    end
endmodule
