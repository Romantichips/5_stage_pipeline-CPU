`timescale 1ns/1ps

module rv_soc_top #(
    parameter IMEM_HEX = "sim/program_int_fp.hex",
    parameter IMEM_HEX_ALT = "../../../../sim/program_int_fp.hex",
    parameter DMEM_HEX = "sim/data_init.hex",
    parameter DMEM_HEX_ALT = "../../../../sim/data_init.hex"
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [31:0] dbg_x10,
    output wire        dbg_halted,
    output wire        dbg_illegal
);
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire [63:0] dmem_wdata;
    wire [7:0]  dmem_wstrb;
    wire        dmem_we;
    wire [63:0] dmem_rdata;

    rv_imem #(
        .ADDR_BITS(10),
        .INIT_HEX(IMEM_HEX),
        .ALT_INIT_HEX(IMEM_HEX_ALT)
    ) u_imem (
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    rv_dmem64 #(
        .ADDR_BITS(8),
        .INIT_HEX(DMEM_HEX),
        .ALT_INIT_HEX(DMEM_HEX_ALT)
    ) u_dmem (
        .clk(clk),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .wstrb(dmem_wstrb),
        .we(dmem_we),
        .rdata(dmem_rdata)
    );

    rv_pipeline_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_wstrb(dmem_wstrb),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_x10(dbg_x10),
        .dbg_halted(dbg_halted),
        .dbg_illegal(dbg_illegal)
    );
endmodule
