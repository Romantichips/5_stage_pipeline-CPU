`timescale 1ns/1ps
`include "rv_defs.vh"

module rv_fpu (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [2:0]  fp_op,
    input  wire        fp_fmt,
    output reg  [63:0] y
);
    function [31:0] fp_addsub32;
        input [31:0] aa;
        input [31:0] bb;
        input        sub;
        reg          sa, sb_eff, s_big, s_small, s_res;
        reg  [7:0]   ea, eb;
        reg  [23:0]  ma, mb, m_big, m_small, mant_r;
        reg  [24:0]  mant_add;
        integer      e_big, e_small, exp_work;
        integer      shift;
        integer      i;
        begin : fp_addsub32_body
            sa     = aa[31];
            sb_eff = bb[31] ^ sub;
            ea     = aa[30:23];
            eb     = bb[30:23];

            if ((ea == 8'hFF) || (eb == 8'hFF)) begin
                fp_addsub32 = 32'h7FC00000;
                disable fp_addsub32_body;
            end

            if (ea == 8'd0) begin
                if (eb == 8'd0)
                    fp_addsub32 = 32'd0;
                else
                    fp_addsub32 = {sb_eff, eb, bb[22:0]};
                disable fp_addsub32_body;
            end

            if (eb == 8'd0) begin
                fp_addsub32 = {sa, ea, aa[22:0]};
                disable fp_addsub32_body;
            end

            ma = {1'b1, aa[22:0]};
            mb = {1'b1, bb[22:0]};

            if ((ea > eb) || ((ea == eb) && (ma >= mb))) begin
                e_big   = ea;
                e_small = eb;
                m_big   = ma;
                m_small = mb;
                s_big   = sa;
                s_small = sb_eff;
            end else begin
                e_big   = eb;
                e_small = ea;
                m_big   = mb;
                m_small = ma;
                s_big   = sb_eff;
                s_small = sa;
            end

            shift = e_big - e_small;
            if (shift > 24)
                m_small = 24'd0;
            else
                m_small = m_small >> shift;

            exp_work = e_big;

            if (s_big == s_small) begin
                mant_add = {1'b0, m_big} + {1'b0, m_small};
                s_res    = s_big;
                if (mant_add[24]) begin
                    mant_r   = mant_add[24:1];
                    exp_work = exp_work + 1;
                end else begin
                    mant_r   = mant_add[23:0];
                end
            end else begin
                mant_r = m_big - m_small;
                s_res  = s_big;
                if (mant_r == 24'd0) begin
                    fp_addsub32 = 32'd0;
                    disable fp_addsub32_body;
                end
                for (i = 0; i < 24; i = i + 1) begin
                    if ((mant_r[23] == 1'b0) && (exp_work > 0)) begin
                        mant_r   = mant_r << 1;
                        exp_work = exp_work - 1;
                    end
                end
            end

            if (exp_work >= 255)
                fp_addsub32 = {s_res, 8'hFF, 23'd0};
            else if (exp_work <= 0)
                fp_addsub32 = 32'd0;
            else
                fp_addsub32 = {s_res, exp_work[7:0], mant_r[22:0]};
        end
    endfunction

    function [31:0] fp_mul32;
        input [31:0] aa;
        input [31:0] bb;
        reg          sa, sb, s_res;
        reg  [7:0]   ea, eb;
        reg  [23:0]  ma, mb;
        reg  [23:0]  mant_r;
        reg  [47:0]  prod;
        integer      exp_work;
        begin
            sa = aa[31];
            sb = bb[31];
            ea = aa[30:23];
            eb = bb[30:23];

            if ((ea == 8'hFF) || (eb == 8'hFF)) begin
                fp_mul32 = 32'h7FC00000;
            end else if ((ea == 8'd0) || (eb == 8'd0)) begin
                fp_mul32 = 32'd0;
            end else begin
                ma       = {1'b1, aa[22:0]};
                mb       = {1'b1, bb[22:0]};
                prod     = ma * mb;
                exp_work = ea + eb - 127;
                s_res    = sa ^ sb;

                if (prod[47]) begin
                    mant_r   = prod[47:24];
                    exp_work = exp_work + 1;
                end else begin
                    mant_r   = prod[46:23];
                end

                if (exp_work >= 255)
                    fp_mul32 = {s_res, 8'hFF, 23'd0};
                else if (exp_work <= 0)
                    fp_mul32 = 32'd0;
                else
                    fp_mul32 = {s_res, exp_work[7:0], mant_r[22:0]};
            end
        end
    endfunction

    function [63:0] fp_addsub64;
        input [63:0] aa;
        input [63:0] bb;
        input        sub;
        reg          sa, sb_eff, s_big, s_small, s_res;
        reg  [10:0]  ea, eb;
        reg  [52:0]  ma, mb, m_big, m_small, mant_r;
        reg  [53:0]  mant_add;
        integer      e_big, e_small, exp_work;
        integer      shift;
        integer      i;
        begin : fp_addsub64_body
            sa     = aa[63];
            sb_eff = bb[63] ^ sub;
            ea     = aa[62:52];
            eb     = bb[62:52];

            if ((ea == 11'h7FF) || (eb == 11'h7FF)) begin
                fp_addsub64 = 64'h7FF8_0000_0000_0000;
                disable fp_addsub64_body;
            end

            if (ea == 11'd0) begin
                if (eb == 11'd0)
                    fp_addsub64 = 64'd0;
                else
                    fp_addsub64 = {sb_eff, eb, bb[51:0]};
                disable fp_addsub64_body;
            end

            if (eb == 11'd0) begin
                fp_addsub64 = {sa, ea, aa[51:0]};
                disable fp_addsub64_body;
            end

            ma = {1'b1, aa[51:0]};
            mb = {1'b1, bb[51:0]};

            if ((ea > eb) || ((ea == eb) && (ma >= mb))) begin
                e_big   = ea;
                e_small = eb;
                m_big   = ma;
                m_small = mb;
                s_big   = sa;
                s_small = sb_eff;
            end else begin
                e_big   = eb;
                e_small = ea;
                m_big   = mb;
                m_small = ma;
                s_big   = sb_eff;
                s_small = sa;
            end

            shift = e_big - e_small;
            if (shift > 53)
                m_small = 53'd0;
            else
                m_small = m_small >> shift;

            exp_work = e_big;

            if (s_big == s_small) begin
                mant_add = {1'b0, m_big} + {1'b0, m_small};
                s_res    = s_big;
                if (mant_add[53]) begin
                    mant_r   = mant_add[53:1];
                    exp_work = exp_work + 1;
                end else begin
                    mant_r   = mant_add[52:0];
                end
            end else begin
                mant_r = m_big - m_small;
                s_res  = s_big;
                if (mant_r == 53'd0) begin
                    fp_addsub64 = 64'd0;
                    disable fp_addsub64_body;
                end
                for (i = 0; i < 53; i = i + 1) begin
                    if ((mant_r[52] == 1'b0) && (exp_work > 0)) begin
                        mant_r   = mant_r << 1;
                        exp_work = exp_work - 1;
                    end
                end
            end

            if (exp_work >= 2047)
                fp_addsub64 = {s_res, 11'h7FF, 52'd0};
            else if (exp_work <= 0)
                fp_addsub64 = 64'd0;
            else
                fp_addsub64 = {s_res, exp_work[10:0], mant_r[51:0]};
        end
    endfunction

    function [63:0] fp_mul64;
        input [63:0] aa;
        input [63:0] bb;
        reg          sa, sb, s_res;
        reg  [10:0]  ea, eb;
        reg  [52:0]  ma, mb, mant_r;
        reg  [105:0] prod;
        integer      exp_work;
        begin
            sa = aa[63];
            sb = bb[63];
            ea = aa[62:52];
            eb = bb[62:52];

            if ((ea == 11'h7FF) || (eb == 11'h7FF)) begin
                fp_mul64 = 64'h7FF8_0000_0000_0000;
            end else if ((ea == 11'd0) || (eb == 11'd0)) begin
                fp_mul64 = 64'd0;
            end else begin
                ma       = {1'b1, aa[51:0]};
                mb       = {1'b1, bb[51:0]};
                prod     = ma * mb;
                exp_work = ea + eb - 1023;
                s_res    = sa ^ sb;

                if (prod[105]) begin
                    mant_r   = prod[105:53];
                    exp_work = exp_work + 1;
                end else begin
                    mant_r   = prod[104:52];
                end

                if (exp_work >= 2047)
                    fp_mul64 = {s_res, 11'h7FF, 52'd0};
                else if (exp_work <= 0)
                    fp_mul64 = 64'd0;
                else
                    fp_mul64 = {s_res, exp_work[10:0], mant_r[51:0]};
            end
        end
    endfunction

    always @(*) begin
        y = 64'd0;
        case (fp_op)
            `FP_OP_ADD: begin
                if (fp_fmt == `FP_FMT_S)
                    y = {32'hFFFF_FFFF, fp_addsub32(a[31:0], b[31:0], 1'b0)};
                else
                    y = fp_addsub64(a, b, 1'b0);
            end
            `FP_OP_SUB: begin
                if (fp_fmt == `FP_FMT_S)
                    y = {32'hFFFF_FFFF, fp_addsub32(a[31:0], b[31:0], 1'b1)};
                else
                    y = fp_addsub64(a, b, 1'b1);
            end
            `FP_OP_MUL: begin
                if (fp_fmt == `FP_FMT_S)
                    y = {32'hFFFF_FFFF, fp_mul32(a[31:0], b[31:0])};
                else
                    y = fp_mul64(a, b);
            end
            default: y = 64'd0;
        endcase
    end
endmodule
