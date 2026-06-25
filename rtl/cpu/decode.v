// Instruction decoder — opcode to datapath control signals.

module decode (
    input  wire [7:0] opcode,

    output wire       is_ld,
    output wire       is_ld_a_n,
    output wire       is_ld_rr,
    output wire       is_ld_r_n,
    output wire       is_ld_hl_n,
    output wire       is_ld_rp_nn,
    output wire [1:0] ld_pair_sel,
    output wire       ld_src_hl,
    output wire       ld_dst_hl,
    output wire       is_alu,
    output wire       is_alu_imm,
    output wire       is_alu_cp,
    output wire       is_inc_dec,
    output wire       is_inc_dec_8,
    output wire       is_inc_dec_rp,
    output wire       is_inc,
    output wire [1:0] inc_dec_pair_sel,
    output wire       inc_dec_hl,
    output wire       is_push_pop,
    output wire       is_branch,
    output wire       is_rotate,
    output wire       is_flag_op,
    output wire       is_halt,
    output wire       is_nop,

    output wire [2:0] reg_d,
    output wire [2:0] reg_s,
    output wire [3:0] alu_op,
    output wire       branch_cond,
    output wire [1:0] cond_sel,

    output wire       is_push,
    output wire       is_pop,
    output wire [1:0] stack_pair_sel,
    output wire       is_jp,
    output wire       is_jr,
    output wire       is_call,
    output wire       is_ret,
    output wire       is_djnz,
    output wire       is_scf,
    output wire       is_ccf,
    output wire [1:0] rotate_op
);
    assign reg_d = opcode[5:3];
    assign reg_s = opcode[2:0];

    assign is_nop    = (opcode == 8'h00);
    assign is_halt   = (opcode == 8'h76);
    assign is_ld_a_n = (opcode == 8'h3E);
    assign is_ld_hl_n = (opcode == 8'h36);

    // LD BC/DE/HL/SP,nn — opcode pattern 00PP0001
    assign is_ld_rp_nn = (opcode[3:0] == 4'h1) && (opcode[7:6] == 2'b00);
    assign ld_pair_sel = opcode[5:4];

    assign is_ld = (opcode[7:6] == 2'b01) && !is_halt;

    // LD r,r' (includes (HL) forms) — opcode 40–7F except HALT
    assign is_ld_rr = (opcode >= 8'h40) && (opcode <= 8'h7F) && (opcode != 8'h76);

    // LD r,n and LD (HL),n — opcode pattern 00DDD110
    assign is_ld_r_n =
        (opcode == 8'h06) || (opcode == 8'h0E) || (opcode == 8'h16) ||
        (opcode == 8'h1E) || (opcode == 8'h26) || (opcode == 8'h2E) ||
        is_ld_a_n || is_ld_hl_n;

    assign ld_src_hl = (reg_s == 3'b110);
    assign ld_dst_hl = (reg_d == 3'b110);

    wire is_alu_imm_w =
        (opcode == 8'hC6) || (opcode == 8'hD6) || (opcode == 8'hE6) ||
        (opcode == 8'hEE) || (opcode == 8'hF6) || (opcode == 8'hFE);

    assign is_alu_imm = is_alu_imm_w;

    assign is_alu =
        (opcode >= 8'h80 && opcode <= 8'h87) ||
        (opcode >= 8'h90 && opcode <= 8'h97) ||
        (opcode >= 8'hA0 && opcode <= 8'hA7) ||
        (opcode >= 8'hA8 && opcode <= 8'hAF) ||
        (opcode >= 8'hB0 && opcode <= 8'hB7) ||
        (opcode >= 8'hB8 && opcode <= 8'hBF) ||
        is_alu_imm_w;

    assign is_alu_cp = (alu_op == 4'd5);

    assign is_inc_dec =
        (opcode == 8'h04) || (opcode == 8'h0C) || (opcode == 8'h14) ||
        (opcode == 8'h1C) || (opcode == 8'h24) || (opcode == 8'h2C) ||
        (opcode == 8'h34) || (opcode == 8'h3C) || (opcode == 8'h05) ||
        (opcode == 8'h0D) || (opcode == 8'h15) || (opcode == 8'h1D) ||
        (opcode == 8'h25) || (opcode == 8'h2D) || (opcode == 8'h35) ||
        (opcode == 8'h3D) || (opcode == 8'h03) || (opcode == 8'h13) ||
        (opcode == 8'h23) || (opcode == 8'h33) || (opcode == 8'h0B) ||
        (opcode == 8'h1B) || (opcode == 8'h2B) || (opcode == 8'h3B);

    assign is_inc_dec_8 = is_inc_dec && (opcode[2:0] == 3'b100 || opcode[2:0] == 3'b101);
    assign is_inc_dec_rp = is_inc_dec && (opcode[2:0] == 3'b011);
    assign is_inc = is_inc_dec_rp ? ~opcode[3] : ~opcode[0];
    assign inc_dec_pair_sel = opcode[5:4];
    assign inc_dec_hl = is_inc_dec_8 && (reg_d == 3'b110);

    assign is_push =
        (opcode == 8'hC5) || (opcode == 8'hD5) ||
        (opcode == 8'hE5) || (opcode == 8'hF5);

    assign is_pop =
        (opcode == 8'hC1) || (opcode == 8'hD1) ||
        (opcode == 8'hE1) || (opcode == 8'hF1);

    assign is_push_pop = is_push || is_pop;

    assign stack_pair_sel = opcode[5:4];

    assign is_jp   = (opcode == 8'hC3);
    assign is_jr   =
        (opcode == 8'h18) || (opcode == 8'h20) || (opcode == 8'h28) ||
        (opcode == 8'h30) || (opcode == 8'h38);
    assign is_call =
        (opcode == 8'hCD) || (opcode == 8'hC4) || (opcode == 8'hCC) ||
        (opcode == 8'hD4) || (opcode == 8'hDC);
    assign is_ret  =
        (opcode == 8'hC9) || (opcode == 8'hC0) || (opcode == 8'hC8) ||
        (opcode == 8'hD0) || (opcode == 8'hD8);
    assign is_djnz = (opcode == 8'h10);
    assign is_scf  = (opcode == 8'h37);
    assign is_ccf  = (opcode == 8'h3F);

    assign rotate_op =
        (opcode == 8'h07) ? 2'd0 :
        (opcode == 8'h0F) ? 2'd1 :
        (opcode == 8'h17) ? 2'd2 :
        2'd3;

    assign is_branch =
        (opcode == 8'hC3) || (opcode == 8'h18) || (opcode == 8'h20) ||
        (opcode == 8'h28) || (opcode == 8'h30) || (opcode == 8'h38) ||
        (opcode == 8'hCD) || (opcode == 8'hC4) || (opcode == 8'hCC) ||
        (opcode == 8'hD4) || (opcode == 8'hDC) || (opcode == 8'hC0) ||
        (opcode == 8'hC8) || (opcode == 8'hC9) || (opcode == 8'hD0) ||
        (opcode == 8'hD8) || (opcode == 8'h10);

    assign is_rotate =
        (opcode == 8'h07) || (opcode == 8'h0F) ||
        (opcode == 8'h17) || (opcode == 8'h1F);

    assign is_flag_op = (opcode == 8'h37) || (opcode == 8'h3F);

    reg [3:0] alu_op_r;
    always @(*) begin
        alu_op_r = 4'h0;
        if (opcode >= 8'h80 && opcode <= 8'h87) alu_op_r = 4'd0;
        else if (opcode >= 8'h90 && opcode <= 8'h97) alu_op_r = 4'd1;
        else if (opcode >= 8'hA0 && opcode <= 8'hA7) alu_op_r = 4'd2;
        else if (opcode >= 8'hA8 && opcode <= 8'hAF) alu_op_r = 4'd3;
        else if (opcode >= 8'hB0 && opcode <= 8'hB7) alu_op_r = 4'd4;
        else if (opcode >= 8'hB8 && opcode <= 8'hBF) alu_op_r = 4'd5;
        else if (opcode == 8'hC6) alu_op_r = 4'd0;
        else if (opcode == 8'hD6) alu_op_r = 4'd1;
        else if (opcode == 8'hE6) alu_op_r = 4'd2;
        else if (opcode == 8'hEE) alu_op_r = 4'd3;
        else if (opcode == 8'hF6) alu_op_r = 4'd4;
        else if (opcode == 8'hFE) alu_op_r = 4'd5;
        else if (is_inc_dec_8 || is_inc_dec_rp)
            alu_op_r = is_inc ? 4'd6 : 4'd7;
    end
    assign alu_op = alu_op_r;

    assign branch_cond =
        (opcode == 8'h20) || (opcode == 8'h28) || (opcode == 8'h30) ||
        (opcode == 8'h38) || (opcode == 8'hC4) || (opcode == 8'hCC) ||
        (opcode == 8'hD4) || (opcode == 8'hDC) || (opcode == 8'hC0) ||
        (opcode == 8'hC8) || (opcode == 8'hD0) || (opcode == 8'hD8);

    assign cond_sel =
        ((opcode == 8'h20) || (opcode == 8'hC4) || (opcode == 8'hC0)) ? 2'd0 :
        ((opcode == 8'h28) || (opcode == 8'hCC) || (opcode == 8'hC8)) ? 2'd1 :
        ((opcode == 8'h30) || (opcode == 8'hD4) || (opcode == 8'hD0)) ? 2'd2 :
        2'd3;
endmodule
