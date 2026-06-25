`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: IF_ID
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


module IF_ID(
    input               clk,
    input               rst,
    //Hazaed Detection
    input               stall,
    input               flush,
    //PC
    input [31:0]        if_pc,
    //NPC
    input [31:0]        if_pc4,
    input [31:0]        if_inst,
    output reg [31:0]   id_pc,
    output reg [31:0]   id_pc4,
    output reg [31:0]   id_inst
    
    );

always @(posedge clk or posedge rst) begin
    if(rst == `RstEnable || flush) begin
        id_pc <= 0;
        id_pc4 <= 0;
        id_inst <= 0;
//    end else if(flush) begin
//        id_pc <= 0;
//        id_pc4 <= 0;
//        id_inst <= 0;
    end else if(stall) begin
        id_pc <= id_pc;
        id_pc4 <= id_pc4;
        id_inst <= id_inst;
    end else begin
        id_pc <= if_pc;
        id_pc4 <= if_pc4;
        id_inst <= if_inst;
    end
end 

endmodule
