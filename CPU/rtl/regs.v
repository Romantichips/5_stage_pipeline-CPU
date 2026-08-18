
module regs(
    input clk,
    input rst_n,
    
    //from id
    input [4:0] rs1_addr_i  ,
    input [4:0] rs2_addr_i  ,

    //to id
    output reg[31:0] rs1_data_o ,
    output reg[31:0] rs2_data_o ,

    //from ex
    input [4:0] rd_addr_i   ,
    input [31:0] rd_data_i  ,
    input regwrite
);

reg [31:0] regs[0:31];

//写入rd
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        regs[rd_addr_i] <= 'd0;
    else if (regwrite && rd_addr_i != 5'b0)
            regs[rd_addr_i] <= rd_data_i;
end

// 读rs1
always @(*) begin
    if (rs1_addr_i == 5'b0)
        rs1_data_o = 32'b0;
    else if (regwrite && (rs1_addr_i == rd_addr_i)) // forward/bypass
        rs1_data_o = rd_data_i;
    else
        rs1_data_o = regs[rs1_addr_i];
end

// 读rs2
always @(*) begin
    if (rs2_addr_i == 5'b0)
        rs2_data_o = 32'b0;
    else if (regwrite && (rs2_addr_i == rd_addr_i))
        rs2_data_o = rd_data_i;
    else
        rs2_data_o = regs[rs2_addr_i];
end


endmodule
