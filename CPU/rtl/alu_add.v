module alu_add(
    input [31:0] data1,
    input [31:0] data2 ,
    output [31:0] data_out
);

assign data_out = data1 + data2;

endmodule
