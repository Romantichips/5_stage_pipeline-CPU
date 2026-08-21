
module pc(
    input             clk           ,
    input             rst_n         ,
    input             pc_hold       ,
    input      [31:0] inst_addr_i   ,
    output reg [31:0] inst_addr_o
);

always @(posedge clk) begin
    if(!rst_n)
        inst_addr_o <= 32'h8000_0000; //复位也可以是32'd0，为了波形上好区分，这是�?-32'd4
	//inst_addr_o <= 32'd0;
    else if(pc_hold == 1'b1)
            inst_addr_o <= inst_addr_o; //PC暂停
         else 
            inst_addr_o <= inst_addr_i;
end

endmodule
