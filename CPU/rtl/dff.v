
module dff #(
    parameter DW = 32
)
(
    input             clk        ,
    input             rst_n      ,
    input             clear      ,  
    input             stall      ,
    input      [DW-1:0] data_in  ,
    output reg [DW-1:0] data_out 
);

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0 | clear == 1'b1)
        data_out <= {DW{1'b0}};  //DW位0
    else if(!stall)begin
        data_out <= data_in;
    end
end
endmodule
