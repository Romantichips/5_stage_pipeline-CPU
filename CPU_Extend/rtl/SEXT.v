`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: SEXT
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
module SEXT(
    //din from IROM, 32位原始指令码中统一截取的25位原始立即数字段
    input wire [24:0] din,
    input wire [`Sext_OP_WDITH-1:0] sext_op,
    output reg [31:0] sext
    );
    
always @(*) begin
    case(sext_op)
        //I-type:12bit有效立即数，补符号位
        `Sext_I: sext = {{20{din[24]}}, din[24:13]};
        `Sext_S: sext = {{20{din[24]}}, din[24:18], din[4:0]};
        //B型分支指令偏移地址必须2字节对齐，∴1'b0
        `Sext_B: sext = {{20{din[24]}}, din[0], din[23:18], din[4:1], {1'b0}};
        //U型指令立即数高20位有效，低12位补0，主要看upper
        `Sext_U: sext = {din[24:5], 12'b0};
        //20bit有符号立即数，J型跳转指令偏移地址必须2字节对齐，∴1'b0
        `Sext_J: sext = {{12{din[24]}}, din[12:5], din[13], din[23:14], {1'b0}};
        default: sext = 0;
    endcase 
end

//1）B,J型 2字节对齐，偶数2进制最后一位都是0
//2）所有跳转 / 分支的偏移量，最低位固定为 0（2 字节对齐）
endmodule
