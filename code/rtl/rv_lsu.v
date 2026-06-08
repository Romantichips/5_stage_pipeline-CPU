`timescale 1ns/1ps
`include "rv_defs.vh"

module rv_lsu (
    input  wire [31:0] addr,
    input  wire [31:0] store_data_int,
    input  wire [63:0] store_data_fp,
    input  wire [63:0] mem_rdata,
    input  wire [1:0]  mem_size,
    input  wire        mem_unsigned,
    input  wire        mem_dest_fp,
    input  wire        store_src_fp,
    output reg  [31:0] load_data_int,
    output reg  [63:0] load_data_fp,
    output reg  [63:0] store_wdata,
    output reg  [7:0]  store_wstrb,
    output reg         misaligned
);
    integer shift_bits;
    reg [63:0] shifted;
    reg [63:0] int_store_tmp;
    reg [63:0] fp_store_tmp;

    always @(*) begin
        shift_bits    = {addr[2:0], 3'b000};
        shifted       = mem_rdata >> shift_bits;
        load_data_int = 32'd0;
        load_data_fp  = 64'd0;
        store_wdata   = 64'd0;
        store_wstrb   = 8'd0;
        misaligned    = 1'b0;
        int_store_tmp = 64'd0;
        fp_store_tmp  = 64'd0;

        case (mem_size)
            `MEM_B: begin
                load_data_int = mem_unsigned ? {24'd0, shifted[7:0]} : {{24{shifted[7]}}, shifted[7:0]};
                int_store_tmp = {{56{1'b0}}, store_data_int[7:0]} << shift_bits;
                store_wdata   = store_src_fp ? (store_data_fp << shift_bits) : int_store_tmp;
                store_wstrb   = (8'b0000_0001 << addr[2:0]);
            end
            `MEM_H: begin
                misaligned    = addr[0];
                load_data_int = mem_unsigned ? {16'd0, shifted[15:0]} : {{16{shifted[15]}}, shifted[15:0]};
                int_store_tmp = {{48{1'b0}}, store_data_int[15:0]} << shift_bits;
                store_wdata   = store_src_fp ? (store_data_fp << shift_bits) : int_store_tmp;
                store_wstrb   = (8'b0000_0011 << addr[2:0]);
            end
            `MEM_W: begin
                misaligned    = |addr[1:0];
                load_data_int = shifted[31:0];
                load_data_fp  = mem_dest_fp ? {32'hFFFF_FFFF, shifted[31:0]} : 64'd0;
                int_store_tmp = {{32{1'b0}}, store_data_int} << shift_bits;
                fp_store_tmp  = {{32{1'b0}}, store_data_fp[31:0]} << shift_bits;
                store_wdata   = store_src_fp ? fp_store_tmp : int_store_tmp;
                store_wstrb   = (8'b0000_1111 << addr[2:0]);
            end
            `MEM_D: begin
                misaligned    = |addr[2:0];
                load_data_fp  = shifted;
                store_wdata   = store_src_fp ? store_data_fp : store_data_fp;
                store_wstrb   = 8'hFF;
            end
            default: begin
                load_data_int = 32'd0;
                load_data_fp  = 64'd0;
                store_wdata   = 64'd0;
                store_wstrb   = 8'd0;
                misaligned    = 1'b1;
            end
        endcase
    end
endmodule
