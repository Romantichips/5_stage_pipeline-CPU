`ifndef RV_PIPE_DEFS_VH
`define RV_PIPE_DEFS_VH

`define ALU_ADD   4'd0
`define ALU_SUB   4'd1
`define ALU_SLL   4'd2
`define ALU_SLT   4'd3
`define ALU_SLTU  4'd4
`define ALU_XOR   4'd5
`define ALU_SRL   4'd6
`define ALU_SRA   4'd7
`define ALU_OR    4'd8
`define ALU_AND   4'd9
`define ALU_MIN   4'd10
`define ALU_MAX   4'd11
`define ALU_ROL   4'd12

`define IMM_I     3'd0
`define IMM_S     3'd1
`define IMM_B     3'd2
`define IMM_U     3'd3
`define IMM_J     3'd4

`define WB_ALU       4'd0
`define WB_LOAD_INT  4'd1
`define WB_PC4       4'd2
`define WB_IMM       4'd3
`define WB_FP_RES    4'd4
`define WB_LOAD_FP   4'd5

`define BR_NONE   3'd0
`define BR_BEQ    3'd1
`define BR_BNE    3'd2
`define BR_BLT    3'd3
`define BR_BGE    3'd4
`define BR_BLTU   3'd5
`define BR_BGEU   3'd6

`define J_NONE    2'd0
`define J_JAL     2'd1
`define J_JALR    2'd2

`define FP_OP_NONE 3'd0
`define FP_OP_ADD  3'd1
`define FP_OP_SUB  3'd2
`define FP_OP_MUL  3'd3

`define FP_FMT_S   1'b0
`define FP_FMT_D   1'b1

`define MEM_B      2'd0
`define MEM_H      2'd1
`define MEM_W      2'd2
`define MEM_D      2'd3

`endif
