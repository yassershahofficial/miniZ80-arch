// miniZ80 CPU core : integrates all datapath and control blocks.

module cpu_core (
    input  wire        clk,
    input  wire        rst,

    output wire        halt,
    output wire [7:0]  dbg_a,
    output wire [7:0]  dbg_b,
    output wire [7:0]  dbg_c,
    output wire [7:0]  dbg_h,
    output wire [7:0]  dbg_l,
    output wire [15:0] dbg_sp,

    output wire [15:0] mem_addr,
    input  wire [7:0]  mem_rdata,
    output wire [7:0]  mem_wdata,
    output wire        mem_read,
    output wire        mem_write
);
    wire [15:0] pc_out;
    wire [15:0] sp_out;

    wire [1:0]  insn_len;
    wire        illegal;
    wire        hl_read;
    wire        hl_write;
    wire        stack_op;

    wire        is_halt;
    wire        is_ld_a_n;
    wire        is_ld_rr;
    wire        is_ld_r_n;
    wire        is_ld_hl_n;
    wire        is_ld_rp_nn;
    wire [1:0]  ld_pair_sel;
    wire        is_alu;
    wire        is_alu_imm;
    wire        is_alu_cp;
    wire [3:0]  alu_op;
    wire        is_inc_dec_8;
    wire        is_inc_dec_rp;
    wire        is_inc;
    wire [1:0]  inc_dec_pair_sel;
    wire        inc_dec_hl;
    wire        ld_src_hl;
    wire        ld_dst_hl;
    wire [2:0]  reg_d;
    wire [2:0]  reg_s;

    wire        is_push;
    wire        is_pop;
    wire [1:0]  stack_pair_sel;
    wire        is_jp;
    wire        is_jr;
    wire        is_call;
    wire        is_ret;
    wire        is_djnz;
    wire        is_scf;
    wire        is_ccf;
    wire        is_rotate;
    wire [1:0]  rotate_op;
    wire        branch_cond;
    wire [1:0]  cond_sel;

    wire        reg_we;
    wire [2:0]  reg_w_addr;
    wire [2:0]  reg_rs_addr;
    wire [7:0]  reg_w_data;
    wire        pc_en;
    wire        pc_load;
    wire [15:0] pc_in;
    wire [1:0]  pc_step;
    wire [1:0]  len_latched;

    wire [7:0]  opcode;
    wire [7:0]  imm8;
    wire [15:0] imm16;

    wire        pair_we;
    wire [1:0]  pair_w_sel;
    wire [15:0] pair_w_data;
    wire [1:0]  pair_r_sel;
    wire        sp_load;
    wire [15:0] sp_w_data;
    wire        sp_inc1;
    wire        sp_dec1;

    wire        flags_update;
    wire        flags_preserve_c;
    wire        flags_scf;
    wire        flags_ccf;
    wire        flags_f_load;
    wire [7:0]  flags_f_wdata;
    wire        alu_flag_n;
    wire [7:0]  inc_hl_wdata;
    wire [7:0]  stack_wdata;

    wire        use_hl_addr;
    wire        use_stack_addr;
    wire [15:0] stack_mem_addr;

    wire [15:0] fetch_addr;
    wire        fetch_read;

    wire [7:0]  rs_data;
    wire [15:0] pair_r_data;
    wire [7:0]  f_out;
    wire        flag_z;
    wire        flag_c;

    wire        inc_dec_mem_rd;
    wire [7:0]  alu_a;
    wire [7:0]  alu_b;
    wire [7:0]  alu_result;
    wire        alu_carry;
    wire        alu_half;
    wire        alu_overflow;
    wire        alu_zero;
    wire        alu_negative;

    wire [7:0]  rotate_result;
    wire        rotate_carry;
    wire        rotate_exec;

    wire [7:0] decode_op = opcode;

    insn_meta u_meta (
        .opcode    (mem_rdata),
        .insn_len  (insn_len),
        .illegal   (illegal),
        .hl_read   (hl_read),
        .hl_write  (hl_write),
        .stack_op  (stack_op)
    );

    decode u_decode (
        .opcode           (decode_op),
        .is_ld            (),
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
        .is_inc_dec       (),
        .is_inc_dec_8     (is_inc_dec_8),
        .is_inc_dec_rp    (is_inc_dec_rp),
        .is_inc           (is_inc),
        .inc_dec_pair_sel (inc_dec_pair_sel),
        .inc_dec_hl       (inc_dec_hl),
        .is_push_pop      (),
        .is_branch        (),
        .is_rotate        (is_rotate),
        .is_flag_op       (),
        .is_halt          (is_halt),
        .is_nop           (),
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

    assign inc_dec_mem_rd = use_hl_addr && is_inc_dec_8 && inc_dec_hl && !mem_write;

    assign alu_a = is_inc_dec_8 ? (inc_dec_mem_rd ? mem_rdata : rs_data) : dbg_a;
    assign alu_b = is_alu_imm ? imm8 :
                   (use_hl_addr && is_alu) ? mem_rdata :
                   rs_data;

    alu u_alu (
        .op         (alu_op),
        .a          (alu_a),
        .b          (alu_b),
        .carry_in   (1'b0),
        .result     (alu_result),
        .carry_out  (alu_carry),
        .half_carry (alu_half),
        .overflow   (alu_overflow),
        .zero       (alu_zero),
        .negative   (alu_negative)
    );

    shifter u_shifter (
        .op        (rotate_op),
        .a         (dbg_a),
        .carry_in  (flag_c),
        .result    (rotate_result),
        .carry_out (rotate_carry)
    );

    flags u_flags (
        .clk        (clk),
        .rst        (rst),
        .update     (flags_update),
        .preserve_c (flags_preserve_c),
        .scf        (flags_scf),
        .ccf        (flags_ccf),
        .f_load     (flags_f_load),
        .f_wdata    (flags_f_wdata),
        .flag_s     (rotate_exec ? 1'b0 : alu_negative),
        .flag_z     (rotate_exec ? 1'b0 : alu_zero),
        .flag_h     (rotate_exec ? 1'b0 : alu_half),
        .flag_pv    (rotate_exec ? 1'b0 : alu_overflow),
        .flag_n     (rotate_exec ? 1'b0 : alu_flag_n),
        .flag_c     (rotate_exec ? rotate_carry : alu_carry),
        .f_out      (f_out),
        .z          (flag_z),
        .c          (flag_c)
    );

    pc u_pc (
        .clk     (clk),
        .rst     (rst),
        .en      (pc_en),
        .load    (pc_load),
        .pc_in   (pc_in),
        .step    (pc_step),
        .pc_out  (pc_out)
    );

    sp u_sp (
        .clk    (clk),
        .rst    (rst),
        .load   (sp_load),
        .sp_in  (sp_w_data),
        .dec2   (1'b0),
        .inc2   (1'b0),
        .inc1   (sp_inc1),
        .dec1   (sp_dec1),
        .sp_out (sp_out)
    );

    reg_file u_regs (
        .clk         (clk),
        .rst         (rst),
        .rs_addr     (reg_rs_addr),
        .rd_addr     (3'b000),
        .rs_data     (rs_data),
        .rd_data     (),
        .we          (reg_we),
        .w_addr      (reg_w_addr),
        .w_data      (reg_w_data),
        .pair_we     (pair_we),
        .pair_w_sel  (pair_w_sel),
        .pair_w_data (pair_w_data),
        .pair_r_sel  (pair_r_sel),
        .pair_r_data (pair_r_data),
        .f_in        (f_out),
        .dbg_a       (dbg_a),
        .dbg_b       (dbg_b),
        .dbg_c       (dbg_c),
        .dbg_h       (dbg_h),
        .dbg_l       (dbg_l)
    );

    control u_control (
        .clk              (clk),
        .rst              (rst),
        .mem_rdata        (mem_rdata),
        .pc               (pc_out),
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
        .pair_r_data      (pair_r_data),
        .ld_src_hl        (ld_src_hl),
        .ld_dst_hl        (ld_dst_hl),
        .reg_d            (reg_d),
        .reg_s            (reg_s),
        .rs_data          (rs_data),
        .alu_result       (alu_result),
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
        .flag_z           (flag_z),
        .flag_c           (flag_c),
        .dbg_a            (dbg_a),
        .dbg_b            (dbg_b),
        .f_out            (f_out),
        .sp_out           (sp_out),
        .rotate_result    (rotate_result),
        .rotate_carry     (rotate_carry),
        .halted           (halt),
        .state            (),
        .fetch_addr       (fetch_addr),
        .fetch_read       (fetch_read),
        .use_hl_addr      (use_hl_addr),
        .use_stack_addr   (use_stack_addr),
        .stack_mem_addr   (stack_mem_addr),
        .mem_write        (mem_write),
        .opcode           (opcode),
        .imm8             (imm8),
        .imm16            (imm16),
        .pair_we          (pair_we),
        .pair_w_sel       (pair_w_sel),
        .pair_w_data      (pair_w_data),
        .pair_r_sel       (pair_r_sel),
        .sp_load          (sp_load),
        .sp_w_data        (sp_w_data),
        .sp_inc1          (sp_inc1),
        .sp_dec1          (sp_dec1),
        .flags_update     (flags_update),
        .flags_preserve_c (flags_preserve_c),
        .flags_scf        (flags_scf),
        .flags_ccf        (flags_ccf),
        .flags_f_load     (flags_f_load),
        .flags_f_wdata    (flags_f_wdata),
        .alu_flag_n       (alu_flag_n),
        .inc_hl_wdata     (inc_hl_wdata),
        .stack_wdata      (stack_wdata),
        .reg_we           (reg_we),
        .reg_w_addr       (reg_w_addr),
        .reg_rs_addr      (reg_rs_addr),
        .reg_w_data       (reg_w_data),
        .pc_en            (pc_en),
        .pc_load          (pc_load),
        .pc_in            (pc_in),
        .pc_step          (pc_step),
        .len_latched      (len_latched),
        .rotate_exec      (rotate_exec)
    );

    assign dbg_sp    = sp_out;
    assign mem_addr  = use_stack_addr ? stack_mem_addr :
                       use_hl_addr ? pair_r_data : fetch_addr;
    assign mem_read  = fetch_read || (use_hl_addr && !mem_write) ||
                       (use_stack_addr && !mem_write);
    assign mem_wdata = mem_write ? (
                         use_stack_addr ? stack_wdata :
                         is_ld_hl_n ? imm8 :
                         (is_inc_dec_8 && inc_dec_hl) ? inc_hl_wdata :
                         rs_data
                       ) : 8'h00;

endmodule
