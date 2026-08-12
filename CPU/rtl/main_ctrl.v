
 `include "defines.v"

module main_ctrl(
    input  [6:0] inst_opcode    ,   //opcode 
    input  [2:0] func3          ,   //func3
    output [11:0] ctrl_bus_out      //以�?�线形式输出,8个控制信号，�?12bit
);
    reg       memtoreg       ; //mux7控制信号
    reg       regwrite       ; //寄存器堆写信�?
    reg       memread        ; //data memory读信�?
    reg       memwrite       ; //data memory写信�?
    reg [2:0] mem_op         ; //L、S型指令存读字节位�?
    reg [2:0] aluop          ; //ALU�?3位控制信�?
    reg       alusrc         ; //mux6控制信号，ALUSrc控制ALU第二个操作数来自寄存器堆的输出还是立即数扩展
    reg       pc_rs1_sel     ; //mux3控制信号，控制跳转地�?是pc+imm还是rs1+imm

    always@(inst_opcode) begin
        case(inst_opcode)
            `R_OP    : begin 
                memtoreg   = 1'b1     ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1     ; //有写回rd
                memread    = 1'b0     ; //不会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `R_ALUOp ; //指令R型指令操�?
                alusrc     = 1'b0     ; //mux6控制信号，ALU的rs2来自寄存器堆中取出的数�??
                pc_rs1_sel = 1'b0     ; //mux3控制信号，这里无�?谓，此处不跳�?        
            end
            `I_OP    : begin
                memtoreg   = 1'b1     ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1     ; //有写回rd
                memread    = 1'b0     ; //不会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `I_ALUOp ; //指令I型指令操�?
                alusrc     = 1'b1     ; //mux6控制信号，ALU的rs2来自立即数扩�?
                pc_rs1_sel = 1'b0     ; //mux3控制信号，这里无�?谓，此处不跳�?  
            end
            `S_OP    : begin
                memtoreg   = 1'b0     ; //mux7控制信号，这里无�?谓，不写�?
                regwrite   = 1'b0     ; //无写回rd
                memread    = 1'b0     ; //会从data memory读出
                memwrite   = 1'b1     ; //会写入data memory
                aluop      = `LS_ALUOp; //L、S型指令执行同样的操作   
                alusrc     = 1'b1     ; //mux6控制信号，ALU的rs2来自立即数扩�?
                pc_rs1_sel = 1'b0     ; //mux3控制信号，这里无�?谓，此处不跳�?  
            end   
            `LD_OP   : begin
                memtoreg   = 1'b0     ; //mux7控制信号，回写结果来自data memory
                regwrite   = 1'b1     ; //有写回rd
                memread    = 1'b1     ; //会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `LS_ALUOp; //L、S型指令执行同样的操作
                alusrc     = 1'b1     ; //mux6控制信号，ALU的rs2来自立即数扩�?
                pc_rs1_sel = 1'b0     ; //mux3控制信号，这里无�?谓，此处不跳�?  
            end
            `B_OP    : begin
                memtoreg   = 1'b0     ; //mux7控制信号，无�?谓，没有写回rd 
                regwrite   = 1'b0     ; //无写回rd
                memread    = 1'b0     ; //不会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `B_ALUOp ; //B型指令操�?
                alusrc     = 1'b0     ; //mux6控制信号，ALU的rs2来自寄存器堆中取出的数�??
                pc_rs1_sel = 1'b0     ; //mux3控制信号，控制跳转地�?是pc+imm  
            end
            `JAL_OP  : begin
                memtoreg   = 1'b1     ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1     ; //有写回rd
                memread    = 1'b0     ; //不会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `J_ALUOp ; //JAL、JALR指令rd执行同样的操�?
                alusrc     = 1'b1     ; //mux6控制信号，这里无�?谓，JAL指令没有rs1、rs2
                pc_rs1_sel = 1'b0     ; //mux3控制信号，控制跳转地�?是pc+imm   
            end   
            `JALR_OP : begin
                memtoreg   = 1'b1     ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1     ; //有写回rd
                memread    = 1'b0     ; //不会从data memory读出
                memwrite   = 1'b0     ; //不会写入data memory
                aluop      = `J_ALUOp ; //JAL、JALR指令rd执行同样的操�?
                alusrc     = 1'b0     ; //mux6控制信号，这里无�?谓，JALR指令没有rs2
                pc_rs1_sel = 1'b1     ; //mux3控制信号，控制跳转地�?是rs1+imm �? 
            end 
            `LUI_OP  : begin
                memtoreg   = 1'b1       ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1       ; //有写回rd
                memread    = 1'b0       ; //不会从data memory读出
                memwrite   = 1'b0       ; //不会写入data memory
                aluop      = `LUI_ALUOp ; //LUI指令操作
                alusrc     = 1'b1       ; //mux6控制信号，ALU的rs2来自立即数扩�?
                pc_rs1_sel = 1'b0       ; //mux3控制信号，这里无�?谓，此处不跳�?     
            end 
            `AUIPC_OP: begin
                memtoreg   = 1'b1         ; //mux7控制信号，回写结果来自ALU
                regwrite   = 1'b1         ; //有写回rd
                memread    = 1'b0         ; //不会从data memory读出
                memwrite   = 1'b0         ; //不会写入data memory
                aluop      = `AUIPC_ALUOp ; //AUIPC指令操作
                alusrc     = 1'b1         ; //mux6控制信号，ALU的rs2来自立即数扩�?
                pc_rs1_sel = 1'b0         ; //mux3控制信号，这里无�?谓，此处不跳�?   
            end  
            
	    default:begin
                memtoreg   = 1'b1     ;
                regwrite   = 1'b1     ;
                memread    = 1'b0     ;
                memwrite   = 1'b0     ;
                aluop      = 3'b0     ;
                alusrc     = 1'b1     ;
                pc_rs1_sel = 1'b0     ;
                end  
        endcase
    end

always @(*) begin
        case(inst_opcode)
                `S_OP,`I_OP,`LD_OP: mem_op = func3 ;
                default:   mem_op = 3'b000  ;
        endcase
end

assign ctrl_bus_out = {
        memtoreg  
        ,regwrite  
        ,memread   
        ,memwrite  
        ,mem_op    
        ,aluop     
        ,alusrc    
        ,pc_rs1_sel
                      };
endmodule
