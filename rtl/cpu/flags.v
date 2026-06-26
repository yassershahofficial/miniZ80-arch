// Flag register F : S, Z, H, P/V, N, C.
//  7   6   5   4   3   2   1   0
//  S   Z   0   H   0   PV  N   C 

module flags (
    input  wire       clk,
    input  wire       rst,

    input  wire       update,
    input  wire       preserve_c,
    input  wire       scf,
    input  wire       ccf,
    input  wire       f_load,
    input  wire [7:0] f_wdata,

    input  wire       flag_s,
    input  wire       flag_z,
    input  wire       flag_h,
    input  wire       flag_pv,
    input  wire       flag_n,
    input  wire       flag_c,

    output wire [7:0] f_out,
    output wire       z,
    output wire       c
);
    reg [7:0] F;

    wire next_c =
        scf ? 1'b1 :
        ccf ? ~F[0] :
        preserve_c ? F[0] :
        flag_c;

    always @(posedge clk) begin
        if (rst)
            F <= 8'h00;
        else if (scf)
            F <= 8'b0001_0001; // C=1, others cleared per ISA
        else if (ccf)
            F <= {7'b0000000, ~F[0]};
        else if (f_load)
            F <= {f_wdata[7:4], 4'b0000};
        else if (update)
            F <= {flag_s, flag_z, 1'b0, flag_h, 1'b0, flag_pv, flag_n, next_c};
    end

    assign f_out = F;
    assign z = F[6];
    assign c = F[0];

endmodule
