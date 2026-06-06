`timescale 1ns/1ps
`include "rv_defs.vh"

module rv_int_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] y
);
    wire [4:0] shamt;
    assign shamt = b[4:0];

    always @(*) begin
        case (alu_op)
            `ALU_ADD : y = a + b;
            `ALU_SUB : y = a - b;
            `ALU_SLL : y = a << shamt;
            `ALU_SLT : y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU: y = (a < b) ? 32'd1 : 32'd0;
            `ALU_XOR : y = a ^ b;
            `ALU_SRL : y = a >> shamt;
            `ALU_SRA : y = $signed(a) >>> shamt;
            `ALU_OR  : y = a | b;
            `ALU_AND : y = a & b;
            `ALU_MIN : y = ($signed(a) < $signed(b)) ? a : b;
            `ALU_MAX : y = ($signed(a) > $signed(b)) ? a : b;
            `ALU_ROL : y = (shamt == 0) ? a : ((a << shamt) | (a >> (5'd32 - shamt)));
            default  : y = 32'd0;
        endcase
    end
endmodule
