// Shared testbench macros for component and stage tests.

`define CHECK_EQ(actual, expected, msg) \
    if ((actual) !== (expected)) begin \
        $display("FAIL: %s — got %h, expected %h", (msg), (actual), (expected)); \
        $fatal(1); \
    end

`define CHECK_FLAG(actual, expected, msg) \
    if ((actual) !== (expected)) begin \
        $display("FAIL: %s — got %b, expected %b", (msg), (actual), (expected)); \
        $fatal(1); \
    end

`define TB_PASS(name) \
    $display("%s: PASS", (name)); \
    $finish

`define TB_FAIL(name, msg) \
    $display("%s: FAIL — %s", (name), (msg)); \
    $fatal(1)

`define tick @(posedge clk);
