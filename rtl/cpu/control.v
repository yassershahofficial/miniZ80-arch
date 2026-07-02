// Control FSM : sequences fetch and execute cycles.

module control (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] mem_rdata,
    input  wire [15:0] pc,

    input  wire [1:0] insn_len,
    input  wire       illegal,
    input  wire       is_halt,
    input  wire       is_ld_a_n,
    input  wire       is_ld_rr,
    input  wire       is_ld_r_n,
    input  wire       is_ld_hl_n,
    input  wire       is_ld_rp_nn,
    input  wire [1:0] ld_pair_sel,
    input  wire       is_alu,
    input  wire       is_alu_imm,
    input  wire       is_alu_cp,
    input  wire [3:0] alu_op,
    input  wire       is_inc_dec_8,
    input  wire       is_inc_dec_rp,
    input  wire       is_inc,
    input  wire [1:0] inc_dec_pair_sel,
    input  wire       inc_dec_hl,
    input  wire [15:0] pair_r_data,
    input  wire       ld_src_hl,
    input  wire       ld_dst_hl,
    input  wire [2:0] reg_d,
    input  wire [2:0] reg_s,
    input  wire [7:0] rs_data,
    input  wire [7:0] alu_result,

    input  wire       is_push,
    input  wire       is_pop,
    input  wire [1:0] stack_pair_sel,
    input  wire       is_jp,
    input  wire       is_jr,
    input  wire       is_call,
    input  wire       is_ret,
    input  wire       is_djnz,
    input  wire       is_scf,
    input  wire       is_ccf,
    input  wire       is_rotate,
    input  wire [1:0] rotate_op,
    input  wire       branch_cond,
    input  wire [1:0] cond_sel,
    input  wire       flag_z,
    input  wire       flag_c,
    input  wire [7:0] dbg_a,
    input  wire [7:0] dbg_b,
    input  wire [7:0] f_out,
    input  wire [15:0] sp_out,
    input  wire [7:0] rotate_result,
    input  wire       rotate_carry,

    output reg        halted,
    output reg [3:0]  state,

    output wire [15:0] fetch_addr,
    output wire        fetch_read,

    output wire        use_hl_addr,
    output wire        use_stack_addr,
    output wire [15:0] stack_mem_addr,
    output wire        mem_write,

    output reg [7:0]  opcode,
    output reg [7:0]  imm8,
    output wire [15:0] imm16,

    output wire       pair_we,
    output wire [1:0] pair_w_sel,
    output wire [15:0] pair_w_data,
    output wire [1:0] pair_r_sel,
    output wire       sp_load,
    output wire [15:0] sp_w_data,
    output wire       sp_inc1,
    output wire       sp_dec1,

    output wire       flags_update,
    output wire       flags_preserve_c,
    output wire       flags_scf,
    output wire       flags_ccf,
    output wire       flags_f_load,
    output wire [7:0] flags_f_wdata,
    output wire       alu_flag_n,

    output wire [7:0] inc_hl_wdata,
    output wire [7:0] stack_wdata,

    output wire       reg_we,
    output wire [2:0] reg_w_addr,
    output wire [2:0] reg_rs_addr,
    output wire [7:0] reg_w_data,

    output wire       pc_en,
    output wire       pc_load,
    output wire [15:0] pc_in,
    output wire [1:0] pc_step,

    output wire       rotate_exec,

    output reg [1:0]  len_latched
);
    localparam ST_RESET   = 4'd0;
    localparam ST_FETCH   = 4'd1;
    localparam ST_FETCH2  = 4'd2;
    localparam ST_FETCH3  = 4'd3;
    localparam ST_EXEC    = 4'd4;
    localparam ST_MEM_RD  = 4'd5;
    localparam ST_MEM_WR  = 4'd6;
    localparam ST_HALT    = 4'd7;
    localparam ST_PUSH_HI = 4'd8;
    localparam ST_PUSH_LO = 4'd9;
    localparam ST_POP_LO  = 4'd10;
    localparam ST_POP_HI  = 4'd11;

    reg [1:0] fetch_offset;

    assign fetch_addr  = pc + {14'd0, fetch_offset};
    assign fetch_read  = (state == ST_FETCH) || (state == ST_FETCH2) || (state == ST_FETCH3);

    wire in_exec   = (state == ST_EXEC);
    wire in_mem_rd = (state == ST_MEM_RD);
    wire in_mem_wr = (state == ST_MEM_WR);
    wire in_push_hi = (state == ST_PUSH_HI);
    wire in_push_lo = (state == ST_PUSH_LO);
    wire in_pop_lo  = (state == ST_POP_LO);
    wire in_pop_hi  = (state == ST_POP_HI);

    assign use_hl_addr = (state == ST_MEM_RD) || (state == ST_MEM_WR);
    assign use_stack_addr = in_push_hi || in_push_lo || in_pop_lo || in_pop_hi;
    assign stack_mem_addr = (in_push_hi || in_push_lo) ? (sp_out - 16'd1) : sp_out;
    assign mem_write = in_mem_wr || in_push_hi || in_push_lo;

    reg [15:0] imm16_r;
    reg [7:0]  inc_hl_result_r;
    reg [15:0] stack_push_r;
    reg [7:0]  stack_pop_lo_r;
    reg [1:0]  stack_pair_r;
    reg        pop_is_ret_r;
    reg        call_push_r;
    reg [15:0] call_target_r;

    assign imm16 = imm16_r;
    assign inc_hl_wdata = inc_hl_result_r;

    wire cond_met =
        (cond_sel == 2'd0) ? !flag_z :
        (cond_sel == 2'd1) ?  flag_z :
        (cond_sel == 2'd2) ? !flag_c :
                             flag_c;

    wire jr_taken   = is_jr && (!branch_cond || cond_met);
    wire jr_skip    = is_jr && branch_cond && !cond_met;
    wire call_taken = is_call && (!branch_cond || cond_met);
    wire call_skip  = is_call && branch_cond && !cond_met;
    wire ret_taken  = is_ret && (!branch_cond || cond_met);
    wire ret_skip   = is_ret && branch_cond && !cond_met;

    wire [7:0] b_dec = dbg_b - 8'd1;
    wire djnz_taken = is_djnz && (b_dec != 8'd0);

    wire [15:0] rel_target = pc + 16'd2 + {{8{imm8[7]}}, imm8};
    wire [15:0] return_addr = pc + 16'd3;

    wire [15:0] push_pair_data =
        (stack_pair_sel == 2'd3) ? {dbg_a, f_out & 8'hF0} :
        pair_r_data;

    assign pair_we     = (in_exec && is_ld_rp_nn && (ld_pair_sel != 2'b11)) ||
                         (in_exec && is_inc_dec_rp && (inc_dec_pair_sel != 2'b11)) ||
                         (in_pop_hi && !pop_is_ret_r);
    assign pair_w_sel  = is_inc_dec_rp ? inc_dec_pair_sel :
                         (in_exec && is_ld_rp_nn) ? ld_pair_sel :
                         stack_pair_r;
    assign pair_w_data = is_inc_dec_rp ? inc_dec_pair_result :
                         in_pop_hi ? {mem_rdata, stack_pop_lo_r} :
                         imm16_r;
    assign pair_r_sel  = is_push ? stack_pair_sel :
                         is_inc_dec_rp ? inc_dec_pair_sel : 2'd2;
    assign sp_load     = in_exec && is_ld_rp_nn && (ld_pair_sel == 2'b11);
    assign sp_w_data   = imm16_r;
    assign sp_inc1     = in_pop_lo || in_pop_hi ||
                         (in_exec && is_inc_dec_rp && is_inc && (inc_dec_pair_sel == 2'b11));
    assign sp_dec1     = in_push_hi || in_push_lo ||
                         (in_exec && is_inc_dec_rp && !is_inc && (inc_dec_pair_sel == 2'b11));

    wire [15:0] inc_dec_pair_result =
        is_inc ? (pair_r_data + 16'd1) : (pair_r_data - 16'd1);

    wire ld_reg_reg = is_ld_rr && !ld_src_hl && !ld_dst_hl;
    wire ld_reg_imm = is_ld_r_n && !is_ld_hl_n;

    wire alu_src_hl = is_alu && !is_alu_imm && (reg_s == 3'b110);
    wire alu_exec_reg = in_exec && is_alu && !alu_src_hl;
    wire alu_exec_mem = in_mem_rd && is_alu;
    wire alu_exec     = alu_exec_reg || alu_exec_mem;

    wire inc_dec_exec_reg = in_exec && is_inc_dec_8 && !inc_dec_hl;
    wire inc_dec_mem_rd   = in_mem_rd && is_inc_dec_8 && inc_dec_hl;
    wire inc_dec_mem_wr   = in_mem_wr && is_inc_dec_8 && inc_dec_hl;
    wire inc_dec_exec     = inc_dec_exec_reg || inc_dec_mem_rd;

    assign rotate_exec = in_exec && is_rotate;

    wire needs_mem =
        (is_ld_rr && (ld_src_hl || ld_dst_hl)) || is_ld_hl_n || alu_src_hl || inc_dec_hl;

    wire insn_simple =
        !is_halt && !needs_mem && !is_push && !is_pop &&
        !is_jp && !is_jr && !is_call && !is_ret && !is_djnz;

    assign flags_update    = alu_exec || inc_dec_exec || rotate_exec;
    assign flags_preserve_c = is_inc_dec_8;
    assign flags_scf       = in_exec && is_scf;
    assign flags_ccf       = in_exec && is_ccf;
    assign flags_f_load    = in_pop_hi && (stack_pair_r == 2'd3) && !pop_is_ret_r;
    assign flags_f_wdata   = stack_pop_lo_r;
    assign alu_flag_n      = (alu_op == 4'd1) || (alu_op == 4'd5) || (alu_op == 4'd7);

    assign reg_rs_addr = is_inc_dec_8 ? reg_d : reg_s;
    assign reg_w_addr  =
        (alu_exec || rotate_exec) ? 3'b111 :
        is_inc_dec_8 ? reg_d :
        is_djnz ? 3'b000 :
        reg_d;
    assign reg_w_data  =
        (alu_exec && !is_alu_cp) ? alu_result :
        (inc_dec_mem_wr) ? inc_hl_result_r :
        (inc_dec_exec_reg) ? alu_result :
        (rotate_exec) ? rotate_result :
        (in_exec && is_djnz) ? b_dec :
        (in_mem_rd && is_ld_rr && ld_src_hl) ? mem_rdata :
        ld_reg_reg ? rs_data :
        imm8;

    assign reg_we =
        (in_exec && (ld_reg_reg || ld_reg_imm || is_ld_a_n)) ||
        (in_mem_rd && is_ld_rr && ld_src_hl) ||
        (alu_exec && !is_alu_cp) ||
        inc_dec_exec_reg ||
        inc_dec_mem_wr ||
        rotate_exec ||
        (in_exec && is_djnz);

    assign stack_wdata =
        in_push_hi ? stack_push_r[15:8] :
        in_push_lo ? stack_push_r[7:0] :
        8'h00;

    wire pc_branch =
        (in_exec && is_jp) ||
        (in_exec && jr_taken) ||
        (in_exec && djnz_taken) ||
        (in_push_lo && call_push_r) ||
        (in_pop_hi && pop_is_ret_r);

    assign pc_load = pc_branch;
    assign pc_in =
        (in_push_lo && call_push_r) ? call_target_r :
        (in_pop_hi && pop_is_ret_r) ? {mem_rdata, stack_pop_lo_r} :
        is_jp ? imm16_r :
        rel_target;

    assign pc_en =
        (in_exec && insn_simple) ||
        (in_exec && jr_skip) ||
        (in_exec && call_skip) ||
        (in_exec && ret_skip) ||
        (in_exec && is_djnz && !djnz_taken) ||
        (in_mem_rd && !(is_inc_dec_8 && inc_dec_hl)) ||
        in_mem_wr ||
        (in_pop_hi && !pop_is_ret_r) ||
        (in_push_lo && !call_push_r);

    assign pc_step =
        (in_exec && jr_skip) ? 2'd1 :
        (in_exec && call_skip) ? 2'd2 :
        (in_exec && ret_skip) ? 2'd0 :
        (in_exec && is_djnz && !djnz_taken) ? 2'd1 :
        (len_latched == 2'd3) ? 2'd2 :
        (len_latched == 2'd2) ? 2'd1 :
        2'd0;

    always @(posedge clk) begin
        if (rst) begin
            state           <= ST_RESET;
            halted          <= 1'b0;
            opcode          <= 8'h00;
            imm8            <= 8'h00;
            imm16_r         <= 16'h0000;
            inc_hl_result_r <= 8'h00;
            stack_push_r    <= 16'h0000;
            stack_pop_lo_r  <= 8'h00;
            stack_pair_r    <= 2'd0;
            pop_is_ret_r    <= 1'b0;
            call_push_r     <= 1'b0;
            call_target_r   <= 16'h0000;
            len_latched     <= 2'd1;
            fetch_offset    <= 2'd0;
        end else begin
            case (state)
                ST_RESET: begin
                    halted       <= 1'b0;
                    fetch_offset <= 2'd0;
                    state        <= ST_FETCH;
                end

                ST_FETCH: begin
                    opcode      <= mem_rdata;
                    len_latched <= insn_len;

                    if (illegal) begin
                        halted <= 1'b1;
                        state  <= ST_HALT;
                    end else if (insn_len == 2'd1) begin
                        fetch_offset <= 2'd0;
                        state        <= ST_EXEC;
                    end else begin
                        fetch_offset <= 2'd1;
                        state        <= ST_FETCH2;
                    end
                end

                ST_FETCH2: begin
                    imm8         <= mem_rdata;
                    imm16_r[7:0] <= mem_rdata;
                    if (len_latched == 2'd2) begin
                        fetch_offset <= 2'd0;
                        state        <= ST_EXEC;
                    end else begin
                        fetch_offset <= 2'd2;
                        state        <= ST_FETCH3;
                    end
                end

                ST_FETCH3: begin
                    imm16_r[15:8] <= mem_rdata;
                    fetch_offset  <= 2'd0;
                    state         <= ST_EXEC;
                end

                ST_EXEC: begin
                    if (is_halt) begin
                        halted <= 1'b1;
                        state  <= ST_HALT;
                    end else if (is_push) begin
                        stack_push_r <= push_pair_data;
                        state        <= ST_PUSH_HI;
                    end else if (call_taken) begin
                        stack_push_r  <= return_addr;
                        call_target_r <= imm16_r;
                        call_push_r   <= 1'b1;
                        state         <= ST_PUSH_HI;
                    end else if (ret_taken) begin
                        stack_pair_r <= stack_pair_sel;
                        pop_is_ret_r <= 1'b1;
                        state        <= ST_POP_LO;
                    end else if (is_pop) begin
                        stack_pair_r <= stack_pair_sel;
                        pop_is_ret_r <= 1'b0;
                        state        <= ST_POP_LO;
                    end else if (is_ld_rr && ld_src_hl)
                        state <= ST_MEM_RD;
                    else if (is_alu && alu_src_hl)
                        state <= ST_MEM_RD;
                    else if (inc_dec_hl)
                        state <= ST_MEM_RD;
                    else if ((is_ld_rr && ld_dst_hl) || is_ld_hl_n)
                        state <= ST_MEM_WR;
                    else begin
                        fetch_offset <= 2'd0;
                        if (call_push_r)
                            call_push_r <= 1'b0;
                        state <= ST_FETCH;
                    end
                end

                ST_MEM_RD: begin
                    if (inc_dec_hl)
                        inc_hl_result_r <= alu_result;
                    fetch_offset <= 2'd0;
                    if (inc_dec_hl)
                        state <= ST_MEM_WR;
                    else
                        state <= ST_FETCH;
                end

                ST_MEM_WR: begin
                    fetch_offset <= 2'd0;
                    state        <= ST_FETCH;
                end

                ST_PUSH_HI: begin
                    fetch_offset <= 2'd0;
                    state        <= ST_PUSH_LO;
                end

                ST_PUSH_LO: begin
                    fetch_offset <= 2'd0;
                    if (call_push_r)
                        call_push_r <= 1'b0;
                    state <= ST_FETCH;
                end

                ST_POP_LO: begin
                    stack_pop_lo_r <= mem_rdata;
                    fetch_offset <= 2'd0;
                    state        <= ST_POP_HI;
                end

                ST_POP_HI: begin
                    fetch_offset <= 2'd0;
                    pop_is_ret_r <= 1'b0;
                    state        <= ST_FETCH;
                end

                ST_HALT: ;
                default: state <= ST_RESET;
            endcase
        end
    end
endmodule
