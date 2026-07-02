// Unit test — control FSM (fetch / execute sequencing).

`timescale 1ns / 1ps
`include "tb_utils.vh"

module tb_control;
    `TB_DUMP_VCD(tb_control)

    localparam ST_FETCH  = 4'd1;
    localparam ST_FETCH2 = 4'd2;
    localparam ST_FETCH3 = 4'd3;
    localparam ST_EXEC   = 4'd4;
    localparam ST_HALT   = 4'd7;

    reg        clk = 0;
    reg        rst = 1;
    reg [15:0] pc = 16'h0000;

    reg [7:0] test_mem [0:255];

    wire [7:0] mem_rdata;
    wire [1:0] insn_len;
    wire       illegal;
    wire       hl_read, hl_write, stack_op;

    wire       is_ld, is_ld_a_n, is_ld_rr, is_ld_r_n, is_ld_hl_n, is_ld_rp_nn;
    wire [1:0] ld_pair_sel;
    wire       ld_src_hl, ld_dst_hl;
    wire       is_alu, is_alu_imm, is_alu_cp;
    wire       is_inc_dec, is_inc_dec_8, is_inc_dec_rp, is_inc;
    wire [1:0] inc_dec_pair_sel;
    wire       inc_dec_hl;
    wire       is_push_pop, is_branch, is_rotate, is_flag_op, is_halt, is_nop;
    wire [2:0] reg_d, reg_s;
    wire [3:0] alu_op;
    wire       branch_cond;
    wire [1:0] cond_sel;
    wire       is_push, is_pop;
    wire [1:0] stack_pair_sel;
    wire       is_jp, is_jr, is_call, is_ret, is_djnz, is_scf, is_ccf;
    wire [1:0] rotate_op;

    wire       halted;
    wire [3:0] state;
    wire [15:0] fetch_addr;
    wire        fetch_read;
    wire [7:0]  opcode;
    wire [7:0]  imm8;
    wire [15:0] imm16;
    wire        reg_we;
    wire [2:0]  reg_w_addr;
    wire [7:0]  reg_w_data;
    wire        pc_en;
    wire        pc_load;
    wire [15:0] pc_in;

    always #5 clk = ~clk;

    assign mem_rdata = test_mem[fetch_addr[7:0]];

    insn_meta u_meta (
        .opcode   (mem_rdata),
        .insn_len (insn_len),
        .illegal  (illegal),
        .hl_read  (hl_read),
        .hl_write (hl_write),
        .stack_op (stack_op)
    );

    decode u_decode (
        .opcode           (opcode),
        .is_ld            (is_ld),
        .is_ld_a_n        (is_ld_a_n),
        .is_ld_rr         (is_ld_rr),
        .is_ld_r_n        (is_ld_r_n),
        .is_ld_hl_n       (is_ld_hl_n),
        .is_ld_rp_nn      (is_ld_rp_nn),
        .ld_pair_sel      (ld_pair_sel),
        .ld_src_hl        (ld_src_hl),
        .ld_dst_hl        (ld_dst_hl),
        .is_alu           (is_alu),
        .is_alu_imm       (is_alu_imm),
        .is_alu_cp        (is_alu_cp),
        .is_inc_dec       (is_inc_dec),
        .is_inc_dec_8     (is_inc_dec_8),
        .is_inc_dec_rp    (is_inc_dec_rp),
        .is_inc           (is_inc),
        .inc_dec_pair_sel (inc_dec_pair_sel),
        .inc_dec_hl       (inc_dec_hl),
        .is_push_pop      (is_push_pop),
        .is_branch        (is_branch),
        .is_rotate        (is_rotate),
        .is_flag_op       (is_flag_op),
        .is_halt          (is_halt),
        .is_nop           (is_nop),
        .reg_d            (reg_d),
        .reg_s            (reg_s),
        .alu_op           (alu_op),
        .branch_cond      (branch_cond),
        .cond_sel         (cond_sel),
        .is_push          (is_push),
        .is_pop           (is_pop),
        .stack_pair_sel   (stack_pair_sel),
        .is_jp            (is_jp),
        .is_jr            (is_jr),
        .is_call          (is_call),
        .is_ret           (is_ret),
        .is_djnz          (is_djnz),
        .is_scf           (is_scf),
        .is_ccf           (is_ccf),
        .rotate_op        (rotate_op)
    );

    control u_dut (
        .clk              (clk),
        .rst              (rst),
        .mem_rdata        (mem_rdata),
        .pc               (pc),
        .insn_len         (insn_len),
        .illegal          (illegal),
        .is_halt          (is_halt),
        .is_ld_a_n        (is_ld_a_n),
        .is_ld_rr         (is_ld_rr),
        .is_ld_r_n        (is_ld_r_n),
        .is_ld_hl_n       (is_ld_hl_n),
        .is_ld_rp_nn      (is_ld_rp_nn),
        .ld_pair_sel      (ld_pair_sel),
        .is_alu           (is_alu),
        .is_alu_imm       (is_alu_imm),
        .is_alu_cp        (is_alu_cp),
        .alu_op           (alu_op),
        .is_inc_dec_8     (is_inc_dec_8),
        .is_inc_dec_rp    (is_inc_dec_rp),
        .is_inc           (is_inc),
        .inc_dec_pair_sel (inc_dec_pair_sel),
        .inc_dec_hl       (inc_dec_hl),
        .pair_r_data      (16'h0000),
        .ld_src_hl        (ld_src_hl),
        .ld_dst_hl        (ld_dst_hl),
        .reg_d            (reg_d),
        .reg_s            (reg_s),
        .rs_data          (8'h00),
        .alu_result       (8'h00),
        .is_push          (is_push),
        .is_pop           (is_pop),
        .stack_pair_sel   (stack_pair_sel),
        .is_jp            (is_jp),
        .is_jr            (is_jr),
        .is_call          (is_call),
        .is_ret           (is_ret),
        .is_djnz          (is_djnz),
        .is_scf           (is_scf),
        .is_ccf           (is_ccf),
        .is_rotate        (is_rotate),
        .rotate_op        (rotate_op),
        .branch_cond      (branch_cond),
        .cond_sel         (cond_sel),
        .flag_z           (1'b0),
        .flag_c           (1'b0),
        .dbg_a            (8'h00),
        .dbg_b            (8'h00),
        .f_out            (8'h00),
        .sp_out           (16'h0410),
        .rotate_result    (8'h00),
        .rotate_carry     (1'b0),
        .halted           (halted),
        .state            (state),
        .fetch_addr       (fetch_addr),
        .fetch_read       (fetch_read),
        .use_hl_addr      (),
        .use_stack_addr   (),
        .stack_mem_addr   (),
        .mem_write        (),
        .opcode           (opcode),
        .imm8             (imm8),
        .imm16            (imm16),
        .pair_we          (),
        .pair_w_sel       (),
        .pair_w_data      (),
        .pair_r_sel       (),
        .sp_load          (),
        .sp_w_data        (),
        .sp_inc1          (),
        .sp_dec1          (),
        .flags_update     (),
        .flags_preserve_c (),
        .flags_scf        (),
        .flags_ccf        (),
        .flags_f_load     (),
        .flags_f_wdata    (),
        .alu_flag_n       (),
        .inc_hl_wdata     (),
        .stack_wdata      (),
        .reg_we           (reg_we),
        .reg_w_addr       (reg_w_addr),
        .reg_rs_addr      (),
        .reg_w_data       (reg_w_data),
        .pc_en            (pc_en),
        .pc_load          (pc_load),
        .pc_in            (pc_in),
        .pc_step          (),
        .rotate_exec      (),
        .len_latched      ()
    );

    task automatic clear_mem;
        integer i;
        begin
            for (i = 0; i < 256; i = i + 1)
                test_mem[i] = 8'h00;
        end
    endtask

    task automatic release_reset;
        begin
            rst = 1'b1;
            #20;
            rst = 1'b0;
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    // Advance one full clock cycle and sample registered FSM state mid-cycle.
    task automatic tick;
        begin
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    initial begin
        clear_mem();
        release_reset();
        `CHECK_EQ(state, ST_FETCH, "reset enters fetch");
        `CHECK_FLAG(fetch_read, 1'b1, "enters fetch with fetch_read");

        // 1-byte NOP: FETCH -> EXEC
        test_mem[0] = 8'h00;
        tick();
        `CHECK_EQ(state, ST_EXEC, "NOP reaches exec");
        `CHECK_FLAG(pc_en, 1'b1, "NOP asserts pc_en");
        `CHECK_EQ(opcode, 8'h00, "NOP opcode latched");
        `CHECK_FLAG(is_nop, 1'b1, "NOP decoded");

        // 2-byte LD A,n: FETCH -> FETCH2 -> EXEC
        clear_mem();
        test_mem[0] = 8'h3E;
        test_mem[1] = 8'h42;
        release_reset();
        tick();
        `CHECK_EQ(state, ST_FETCH2, "LD A,n reaches fetch2");
        `CHECK_EQ(fetch_addr, 16'h0001, "2-byte insn fetch_addr offset 1");
        tick();
        `CHECK_EQ(state, ST_EXEC, "LD A,n reaches exec");
        `CHECK_EQ(imm8, 8'h42, "LD A,n imm8 latched");
        `CHECK_FLAG(reg_we, 1'b1, "LD A,n reg_we");
        `CHECK_EQ(reg_w_addr, 3'b111, "LD A,n writes A");
        `CHECK_EQ(reg_w_data, 8'h42, "LD A,n write data");

        // 3-byte JP nn: FETCH -> FETCH2 -> FETCH3 -> EXEC
        clear_mem();
        test_mem[0] = 8'hC3;
        test_mem[1] = 8'h34;
        test_mem[2] = 8'h12;
        release_reset();
        tick();
        `CHECK_EQ(state, ST_FETCH2, "JP nn reaches fetch2");
        tick();
        `CHECK_EQ(state, ST_FETCH3, "JP nn reaches fetch3");
        `CHECK_EQ(fetch_addr, 16'h0002, "3-byte insn fetch_addr offset 2");
        tick();
        `CHECK_EQ(state, ST_EXEC, "JP nn reaches exec");
        `CHECK_EQ(imm16, 16'h1234, "JP nn imm16 latched");
        `CHECK_FLAG(pc_load, 1'b1, "JP nn pc_load");
        `CHECK_EQ(pc_in, 16'h1234, "JP nn target");

        // HALT: FETCH -> EXEC -> ST_HALT
        clear_mem();
        test_mem[0] = 8'h76;
        release_reset();
        tick();
        `CHECK_EQ(state, ST_EXEC, "HALT reaches exec");
        tick();
        `CHECK_EQ(state, ST_HALT, "HALT reaches halt state");
        `CHECK_FLAG(halted, 1'b1, "HALT sets halted");

        // Illegal opcode halts in fetch
        clear_mem();
        test_mem[0] = 8'hFF;
        release_reset();
        tick();
        `CHECK_EQ(state, ST_HALT, "illegal opcode halts in fetch");
        `CHECK_FLAG(halted, 1'b1, "illegal opcode sets halted");

        `TB_PASS("tb_control");
    end
endmodule
