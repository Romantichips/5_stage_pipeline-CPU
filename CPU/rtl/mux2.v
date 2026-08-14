
module mux2 #(
    parameter DW = 32
)
(
    input sel                ,
    input  [DW-1:0] data_in1 ,
    input  [DW-1:0] data_in2 ,
    output [DW-1:0] data_out
);

assign data_out = (sel == 1'b1)? data_in2 : data_in1; 

endmodule