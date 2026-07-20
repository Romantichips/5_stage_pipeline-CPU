`timescale 1ns / 1ps

`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: RegFile
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
module RegFile(
    input rst,
    input clk,
    //rs1,rs2地址
    input wire [`RegAddrBus] rR1,
    input wire [`RegAddrBus] rR2,
    //rd地址
    input wire [`RegAddrBus] wR,
    //we=1, wR对应的reg会被写入值
    input wire we,
    //WB写回的最终32bit值（指令最终运算结果）
    input wire [`RegBus] wD,
    //读出2路寄存器的值
    output reg [`RegBus] rD1,
    output reg [`RegBus] rD2
    );
    
//寄存器堆，[`RegBus]=每个reg的位宽；[0:`RegNum-1]=堆中总reg数量
 reg [`RegBus] regs [0:`RegNum-1];
//读出寄存器值，组合逻辑
 always @(*) begin
    if(rst==`RstEnable) begin
        rD1 = 0;
        rD2 = 0;
    end else begin
        rD1 = regs[rR1];
        rD2 = regs[rR2];
    end
 end
//写入寄存器值，时序逻辑
 always @(posedge clk) begin
    //复位无效
    if(rst==`RstDisable) begin
        //x0=0，禁止写入
        if(wR==0) begin
            regs[wR] <= 0;
        end else if (we) begin
            regs[wR] <= wD;
        end else begin
            regs[wR] <= regs[wR];
        end
    //复位有效    
    end else begin
        regs[0] <= 0;
        regs[1] <= 0;
        regs[2] <= 0;
        regs[3] <= 0;
        regs[4] <= 0;
        regs[5] <= 0;
        regs[6] <= 0;
        regs[7] <= 0;
        regs[8] <= 0;
        regs[9] <= 0;
        regs[10] <= 0;
        regs[11] <= 0;
        regs[12] <= 0;
        regs[13] <= 0;
        regs[14] <= 0;
        regs[15] <= 0;
        regs[16] <= 0;
        regs[17] <= 0;
        regs[18] <= 0;
        regs[19] <= 0;
        regs[20] <= 0;
        regs[21] <= 0;
        regs[22] <= 0;
        regs[23] <= 0;
        regs[24] <= 0;
        regs[25] <= 0;
        regs[26] <= 0;
        regs[27] <= 0;
        regs[28] <= 0;
        regs[29] <= 0;
        regs[30] <= 0;
        regs[31] <= 0;
    end
 end

endmodule
