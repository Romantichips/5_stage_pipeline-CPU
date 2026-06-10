`timescale 1ns/1ps

module rv_regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] dbg_x10
);
    reg [31:0] regs[0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we && (rd_addr != 5'd0))
            regs[rd_addr] <= rd_data;
        regs[0] <= 32'd0;
    end

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 :
                      ((we && (rd_addr == rs1_addr) && (rd_addr != 5'd0)) ? rd_data : regs[rs1_addr]);
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 :
                      ((we && (rd_addr == rs2_addr) && (rd_addr != 5'd0)) ? rd_data : regs[rs2_addr]);
    assign dbg_x10  = regs[10];
endmodule
