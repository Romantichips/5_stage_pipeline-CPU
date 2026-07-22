`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: MEM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module MEM(
    input clk,
    input we_in,
    input [31:0] addr_in,
    //外界输入MEM，将写入DRAM
    input [31:0] wdin,
    input [`DRAM_SEL_WIDTH-1:0] dram_sel,
    //DRAM提供，读出到WB
    input wire [31:0] DRAM_rdata_in,
    output wire [31:0] addr_out,
    output wire we_out,
    //写入DRAM
    output reg [31:0] wdata_out,
    //写入WB
    output reg [31:0] rdo
);

assign we_out = we_in;
assign addr_out = addr_in;

// 读取为组合逻辑
always @(*) begin
    wdata_out = 32'b0;  // 预设默认值防止 latch
    rdo = 32'b0;

    case (dram_sel)
        `DRAM_SEL_LW: begin
            rdo = DRAM_rdata_in;
        end
        `DRAM_SEL_LB: begin
            case (addr_in[1:0])
                2'd0: rdo = {{24{DRAM_rdata_in[7]}}, DRAM_rdata_in[7:0]};
                2'd1: rdo = {{24{DRAM_rdata_in[15]}}, DRAM_rdata_in[15:8]};
                2'd2: rdo = {{24{DRAM_rdata_in[23]}}, DRAM_rdata_in[23:16]};
                2'd3: rdo = {{24{DRAM_rdata_in[31]}}, DRAM_rdata_in[31:24]};
            endcase
        end
        `DRAM_SEL_LBU: begin
            case (addr_in[1:0])
                2'd0: rdo = {{24{1'b0}}, DRAM_rdata_in[7:0]};
                2'd1: rdo = {{24{1'b0}}, DRAM_rdata_in[15:8]};
                2'd2: rdo = {{24{1'b0}}, DRAM_rdata_in[23:16]};
                2'd3: rdo = {{24{1'b0}}, DRAM_rdata_in[31:24]};
            endcase
        end
        `DRAM_SEL_LH: begin
            case (addr_in[1:0])
                2'd0: rdo = {{16{DRAM_rdata_in[15]}}, DRAM_rdata_in[15:0]};
                2'd1: rdo = {{16{DRAM_rdata_in[23]}}, DRAM_rdata_in[23:8]};
                2'd2: rdo = {{16{DRAM_rdata_in[31]}}, DRAM_rdata_in[31:16]};
            endcase
        end
        `DRAM_SEL_LHU: begin
            case (addr_in[1:0])
                2'd0: rdo = {{16{1'b0}}, DRAM_rdata_in[15:0]};
                2'd1: rdo = {{16{1'b0}}, DRAM_rdata_in[23:8]};
                2'd2: rdo = {{16{1'b0}}, DRAM_rdata_in[31:16]};
            endcase
        end
        default: rdo = 32'b0;
    endcase
end

// 写入为时序逻辑
always @(posedge clk) begin
    case (dram_sel)
        `DRAM_SEL_SW: begin
            wdata_out <= wdin;
        end
        `DRAM_SEL_SB: begin
            case (addr_in[1:0])
                2'd0: wdata_out <= {DRAM_rdata_in[31:8], wdin[7:0]};
                2'd1: wdata_out <= {DRAM_rdata_in[31:16], wdin[7:0], DRAM_rdata_in[7:0]};
                2'd2: wdata_out <= {DRAM_rdata_in[31:24], wdin[7:0], DRAM_rdata_in[15:0]};
                2'd3: wdata_out <= {wdin[7:0], DRAM_rdata_in[23:0]};
                default: wdata_out <= 32'b0;
            endcase
        end
        `DRAM_SEL_SH: begin
            case (addr_in[1:0])
                2'd0: wdata_out <= {DRAM_rdata_in[31:16], wdin[15:0]};
                2'd1: wdata_out <= {DRAM_rdata_in[31:24], wdin[15:0], DRAM_rdata_in[7:0]};
                2'd2: wdata_out <= {wdin[15:0], DRAM_rdata_in[15:0]};
                default: wdata_out <= 32'b0;
            endcase
        end
        default: wdata_out <= wdin;
    endcase
end

endmodule