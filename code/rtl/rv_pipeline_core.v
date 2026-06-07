`timescale 1ns/1ps
`include "rv_defs.vh"

module rv_pipeline_core #(
    parameter RESET_PC = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    output wire [7:0]  dmem_wstrb,
    output wire        dmem_we,
    input  wire [63:0] dmem_rdata,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [31:0] dbg_x10,
    output wire        dbg_halted,
    output wire        dbg_illegal
);
    reg         halted;
    reg         illegal_latched;
    reg  [31:0] pc_reg;

//Stage1：IF（Instruction Fetch），取指阶段
//Stage2：ID（Instruction Decode），译码阶段
//Stage3：EX（Execute），执行阶段
//Stage4：MEM（Memory Access），访存阶段
//Stage5：WB（Write Back），写回阶段

//reg1
    reg         if_id_valid;
    reg  [31:0] if_id_pc;
    reg  [31:0] if_id_instr;
//reg2
    reg         id_ex_valid;
    reg  [31:0] id_ex_pc;
    reg  [31:0] id_ex_instr;
    reg  [31:0] id_ex_imm;
    reg  [4:0]  id_ex_rs1;
    reg  [4:0]  id_ex_rs2;
    reg  [4:0]  id_ex_rd;
    reg  [31:0] id_ex_rs1_val;
    reg  [31:0] id_ex_rs2_val;
    reg  [63:0] id_ex_frs1_val;
    reg  [63:0] id_ex_frs2_val;
    reg         id_ex_reg_write_int;
    reg         id_ex_reg_write_fp;
    reg         id_ex_use_rs1_int;
    reg         id_ex_use_rs2_int;
    reg         id_ex_alu_src_a_pc;
    reg         id_ex_alu_src_b_imm;
    reg  [3:0]  id_ex_alu_op;
    reg  [3:0]  id_ex_wb_sel;
    reg         id_ex_mem_read;
    reg         id_ex_mem_write;
    reg  [1:0]  id_ex_mem_size;
    reg         id_ex_mem_unsigned;
    reg         id_ex_mem_dest_fp;
    reg         id_ex_store_src_fp;
    reg  [2:0]  id_ex_branch_type;
    reg  [1:0]  id_ex_jump_type;
    reg  [2:0]  id_ex_fp_op;
    reg         id_ex_fp_fmt;
//reg3
    reg         ex_mem_valid;
    reg  [31:0] ex_mem_pc;
    reg  [31:0] ex_mem_instr;
    //ALU-int；FPU-fp（计算结果）
    reg  [31:0] ex_mem_int_result;
    reg  [63:0] ex_mem_fp_result;
    //写入内存的int/fp data
    reg  [31:0] ex_mem_store_int_data;
    reg  [63:0] ex_mem_store_fp_data;

    reg  [31:0] ex_mem_pc4;
    reg  [31:0] ex_mem_imm;
    reg  [4:0]  ex_mem_rd;
    reg         ex_mem_reg_write_int;
    reg         ex_mem_reg_write_fp;
    reg  [3:0]  ex_mem_wb_sel;
    reg         ex_mem_mem_read;
    reg         ex_mem_mem_write;
    reg  [1:0]  ex_mem_mem_size;
    reg         ex_mem_mem_unsigned;
    reg         ex_mem_mem_dest_fp;
    reg         ex_mem_store_src_fp;
//reg4
    reg         mem_wb_valid;
    reg  [31:0] mem_wb_pc;
    reg  [31:0] mem_wb_instr;
    //执行阶段int/fp结果
    reg  [31:0] mem_wb_int_result;
    reg  [63:0] mem_wb_fp_result;
    //内存读出的int/fp data
    reg  [31:0] mem_wb_load_data_int;
    reg  [63:0] mem_wb_load_data_fp;
    reg  [31:0] mem_wb_pc4;
    reg  [31:0] mem_wb_imm;
    reg  [4:0]  mem_wb_rd;
    reg         mem_wb_reg_write_int;
    reg         mem_wb_reg_write_fp;
    reg  [3:0]  mem_wb_wb_sel;
//------------------------------------------------------------

    //instruct fetch: instruct now(instr_f) and next instruct addr(PC+4) 
    wire [31:0] instr_f;
    wire [31:0] pc_plus4_f;
    //
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [63:0] id_frs1_data;
    wire [63:0] id_frs2_data;
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;
    wire [31:0] imm_u;
    wire [31:0] imm_j;
    reg  [31:0] id_imm_selected;

    wire        id_reg_write_int;
    wire        id_reg_write_fp;
    wire        id_use_rs1_int;
    wire        id_use_rs2_int;
    wire        id_use_rs1_fp;
    wire        id_use_rs2_fp;
    wire        id_alu_src_a_pc;
    wire        id_alu_src_b_imm;
    wire [3:0]  id_alu_op;
    wire [2:0]  id_imm_type;
    wire [3:0]  id_wb_sel;
    wire        id_mem_read;
    wire        id_mem_write;
    wire [1:0]  id_mem_size;
    wire        id_mem_unsigned;
    wire        id_mem_dest_fp;
    wire        id_store_src_fp;
    wire [2:0]  id_branch_type;
    wire [1:0]  id_jump_type;
    wire [2:0]  id_fp_op;
    wire        id_fp_fmt;
    wire        id_illegal;
    wire        id_illegal_fire;

    wire        stall_if;
    wire        stall_id;
    wire        bubble_ex;
    wire        stall_load_use;
    wire        stall_fp_raw;

    wire [1:0]  fwd_a_sel;
    wire [1:0]  fwd_b_sel;
    reg  [31:0] ex_rs1_forward;
    reg  [31:0] ex_rs2_forward;
    wire [31:0] ex_alu_a;
    wire [31:0] ex_alu_b;
    wire [31:0] ex_alu_y;
    wire [63:0] ex_fp_y;
    wire        ex_eq;
    wire        ex_lt_signed;
    wire        ex_lt_unsigned;
    reg         ex_branch_taken;
    wire        ex_jump_taken;
    wire        ex_redirect;
    reg  [31:0] ex_target_pc;
    wire [31:0] ex_pc4;

    wire [31:0] lsu_load_int;
    wire [63:0] lsu_load_fp;
    wire [63:0] lsu_store_wdata;
    wire [7:0]  lsu_store_wstrb;
    wire        lsu_misaligned;
    wire        mem_fault;

    reg  [31:0] ex_mem_fwd_int_data;
    reg  [31:0] mem_wb_gpr_wdata;
    reg  [63:0] mem_wb_fpr_wdata;
    wire        wb_gpr_we;
    wire        wb_fpr_we;

    assign instr_f    = imem_rdata;
    assign imem_addr  = pc_reg;
    assign pc_plus4_f = pc_reg + 32'd4;

    assign id_rs1 = if_id_instr[19:15];
    assign id_rs2 = if_id_instr[24:20];
    assign id_rd  = if_id_instr[11:7];

    assign id_illegal_fire = if_id_valid && id_illegal;

    rv_decoder u_decoder (
        .instr(if_id_instr),
        .reg_write_int(id_reg_write_int),
        .reg_write_fp(id_reg_write_fp),
        .use_rs1_int(id_use_rs1_int),
        .use_rs2_int(id_use_rs2_int),
        .use_rs1_fp(id_use_rs1_fp),
        .use_rs2_fp(id_use_rs2_fp),
        .alu_src_a_pc(id_alu_src_a_pc),
        .alu_src_b_imm(id_alu_src_b_imm),
        .alu_op(id_alu_op),
        .imm_type(id_imm_type),
        .wb_sel(id_wb_sel),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_size(id_mem_size),
        .mem_unsigned(id_mem_unsigned),
        .mem_dest_fp(id_mem_dest_fp),
        .store_src_fp(id_store_src_fp),
        .branch_type(id_branch_type),
        .jump_type(id_jump_type),
        .fp_op(id_fp_op),
        .fp_fmt(id_fp_fmt),
        .illegal_instr(id_illegal)
    );

    rv_imm_gen u_imm_gen (
        .instr(if_id_instr),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j)
    );

    rv_regfile u_regfile (
        .clk(clk),
        .we(wb_gpr_we),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rd_addr(mem_wb_rd),
        .rd_data(mem_wb_gpr_wdata),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data),
        .dbg_x10(dbg_x10)
    );

    rv_fregfile u_fregfile (
        .clk(clk),
        .we(wb_fpr_we),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rd_addr(mem_wb_rd),
        .rd_data(mem_wb_fpr_wdata),
        .rs1_data(id_frs1_data),
        .rs2_data(id_frs2_data)
    );

    rv_hazard_unit u_hazard (
        .id_valid(if_id_valid),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_use_rs1_int(id_use_rs1_int),
        .id_use_rs2_int(id_use_rs2_int),
        .id_use_rs1_fp(id_use_rs1_fp),
        .id_use_rs2_fp(id_use_rs2_fp),
        .id_ex_valid(id_ex_valid),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_reg_write_int(id_ex_reg_write_int),
        .id_ex_reg_write_fp(id_ex_reg_write_fp),
        .id_ex_rd(id_ex_rd),
        .ex_mem_valid(ex_mem_valid),
        .ex_mem_reg_write_fp(ex_mem_reg_write_fp),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_valid(mem_wb_valid),
        .mem_wb_reg_write_fp(mem_wb_reg_write_fp),
        .mem_wb_rd(mem_wb_rd),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .bubble_ex(bubble_ex),
        .stall_load_use(stall_load_use),
        .stall_fp_raw(stall_fp_raw)
    );

    rv_forward_unit u_forward (
        .ex_rs1(id_ex_rs1),
        .ex_rs2(id_ex_rs2),
        .ex_use_rs1(id_ex_use_rs1_int),
        .ex_use_rs2(id_ex_use_rs2_int),
        .ex_mem_valid(ex_mem_valid),
        .ex_mem_reg_write_int(ex_mem_reg_write_int),
        .ex_mem_is_load(ex_mem_mem_read),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_valid(mem_wb_valid),
        .mem_wb_reg_write_int(mem_wb_reg_write_int),
        .mem_wb_rd(mem_wb_rd),
        .forward_a(fwd_a_sel),
        .forward_b(fwd_b_sel)
    );

    always @(*) begin
        case (id_imm_type)
            `IMM_I: id_imm_selected = imm_i;
            `IMM_S: id_imm_selected = imm_s;
            `IMM_B: id_imm_selected = imm_b;
            `IMM_U: id_imm_selected = imm_u;
            `IMM_J: id_imm_selected = imm_j;
            default: id_imm_selected = 32'd0;
        endcase
    end

    always @(*) begin
        case (ex_mem_wb_sel)
            `WB_ALU: ex_mem_fwd_int_data = ex_mem_int_result;
            `WB_PC4: ex_mem_fwd_int_data = ex_mem_pc4;
            `WB_IMM: ex_mem_fwd_int_data = ex_mem_imm;
            default: ex_mem_fwd_int_data = ex_mem_int_result;
        endcase
    end

    always @(*) begin
        case (mem_wb_wb_sel)
            `WB_ALU     : mem_wb_gpr_wdata = mem_wb_int_result;
            `WB_LOAD_INT: mem_wb_gpr_wdata = mem_wb_load_data_int;
            `WB_PC4     : mem_wb_gpr_wdata = mem_wb_pc4;
            `WB_IMM     : mem_wb_gpr_wdata = mem_wb_imm;
            default     : mem_wb_gpr_wdata = mem_wb_int_result;
        endcase
    end

    always @(*) begin
        case (mem_wb_wb_sel)
            `WB_FP_RES : mem_wb_fpr_wdata = mem_wb_fp_result;
            `WB_LOAD_FP: mem_wb_fpr_wdata = mem_wb_load_data_fp;
            default    : mem_wb_fpr_wdata = 64'd0;
        endcase
    end

    assign wb_gpr_we = mem_wb_valid && mem_wb_reg_write_int && !halted;
    assign wb_fpr_we = mem_wb_valid && mem_wb_reg_write_fp && !halted;

    always @(*) begin
        case (fwd_a_sel)
            2'b10: ex_rs1_forward = ex_mem_fwd_int_data;
            2'b01: ex_rs1_forward = mem_wb_gpr_wdata;
            default: ex_rs1_forward = id_ex_rs1_val;
        endcase
    end

    always @(*) begin
        case (fwd_b_sel)
            2'b10: ex_rs2_forward = ex_mem_fwd_int_data;
            2'b01: ex_rs2_forward = mem_wb_gpr_wdata;
            default: ex_rs2_forward = id_ex_rs2_val;
        endcase
    end

    assign ex_alu_a = id_ex_alu_src_a_pc ? id_ex_pc : ex_rs1_forward;
    assign ex_alu_b = id_ex_alu_src_b_imm ? id_ex_imm : ex_rs2_forward;
    assign ex_pc4   = id_ex_pc + 32'd4;

    rv_int_alu u_int_alu (
        .a(ex_alu_a),
        .b(ex_alu_b),
        .alu_op(id_ex_alu_op),
        .y(ex_alu_y)
    );

    rv_branch_comp u_branch_comp (
        .a(ex_rs1_forward),
        .b(ex_rs2_forward),
        .eq(ex_eq),
        .lt_signed(ex_lt_signed),
        .lt_unsigned(ex_lt_unsigned)
    );

    rv_fpu u_fpu (
        .a(id_ex_frs1_val),
        .b(id_ex_frs2_val),
        .fp_op(id_ex_fp_op),
        .fp_fmt(id_ex_fp_fmt),
        .y(ex_fp_y)
    );

    always @(*) begin
        case (id_ex_branch_type)
            `BR_BEQ : ex_branch_taken = ex_eq;
            `BR_BNE : ex_branch_taken = ~ex_eq;
            `BR_BLT : ex_branch_taken = ex_lt_signed;
            `BR_BGE : ex_branch_taken = ~ex_lt_signed;
            `BR_BLTU: ex_branch_taken = ex_lt_unsigned;
            `BR_BGEU: ex_branch_taken = ~ex_lt_unsigned;
            default : ex_branch_taken = 1'b0;
        endcase
    end

    assign ex_jump_taken = (id_ex_jump_type != `J_NONE);
    assign ex_redirect   = id_ex_valid && (ex_jump_taken || ex_branch_taken);

    always @(*) begin
        if (id_ex_jump_type == `J_JAL)
            ex_target_pc = id_ex_pc + id_ex_imm;
        else if (id_ex_jump_type == `J_JALR)
            ex_target_pc = (ex_rs1_forward + id_ex_imm) & 32'hFFFF_FFFE;
        else
            ex_target_pc = id_ex_pc + id_ex_imm;
    end

    rv_lsu u_lsu (
        .addr(ex_mem_int_result),
        .store_data_int(ex_mem_store_int_data),
        .store_data_fp(ex_mem_store_fp_data),
        .mem_rdata(dmem_rdata),
        .mem_size(ex_mem_mem_size),
        .mem_unsigned(ex_mem_mem_unsigned),
        .mem_dest_fp(ex_mem_mem_dest_fp),
        .store_src_fp(ex_mem_store_src_fp),
        .load_data_int(lsu_load_int),
        .load_data_fp(lsu_load_fp),
        .store_wdata(lsu_store_wdata),
        .store_wstrb(lsu_store_wstrb),
        .misaligned(lsu_misaligned)
    );

    assign mem_fault = ex_mem_valid && (ex_mem_mem_read || ex_mem_mem_write) && lsu_misaligned;

    assign dmem_addr  = ex_mem_int_result;
    assign dmem_wdata = (ex_mem_valid && ex_mem_mem_write && !lsu_misaligned && !halted) ? lsu_store_wdata : 64'd0;
    assign dmem_wstrb = (ex_mem_valid && ex_mem_mem_write && !lsu_misaligned && !halted) ? lsu_store_wstrb : 8'd0;
    assign dmem_we    = (ex_mem_valid && ex_mem_mem_write && !lsu_misaligned && !halted);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halted              <= 1'b0;
            illegal_latched     <= 1'b0;
            pc_reg              <= RESET_PC;
            if_id_valid         <= 1'b0;
            if_id_pc            <= 32'd0;
            if_id_instr         <= 32'h00000013;
            id_ex_valid         <= 1'b0;
            id_ex_pc            <= 32'd0;
            id_ex_instr         <= 32'h00000013;
            id_ex_imm           <= 32'd0;
            id_ex_rs1           <= 5'd0;
            id_ex_rs2           <= 5'd0;
            id_ex_rd            <= 5'd0;
            id_ex_rs1_val       <= 32'd0;
            id_ex_rs2_val       <= 32'd0;
            id_ex_frs1_val      <= 64'd0;
            id_ex_frs2_val      <= 64'd0;
            id_ex_reg_write_int <= 1'b0;
            id_ex_reg_write_fp  <= 1'b0;
            id_ex_use_rs1_int   <= 1'b0;
            id_ex_use_rs2_int   <= 1'b0;
            id_ex_alu_src_a_pc  <= 1'b0;
            id_ex_alu_src_b_imm <= 1'b0;
            id_ex_alu_op        <= `ALU_ADD;
            id_ex_wb_sel        <= `WB_ALU;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_size      <= `MEM_W;
            id_ex_mem_unsigned  <= 1'b0;
            id_ex_mem_dest_fp   <= 1'b0;
            id_ex_store_src_fp  <= 1'b0;
            id_ex_branch_type   <= `BR_NONE;
            id_ex_jump_type     <= `J_NONE;
            id_ex_fp_op         <= `FP_OP_NONE;
            id_ex_fp_fmt        <= `FP_FMT_S;
            ex_mem_valid        <= 1'b0;
            ex_mem_pc           <= 32'd0;
            ex_mem_instr        <= 32'h00000013;
            ex_mem_int_result   <= 32'd0;
            ex_mem_fp_result    <= 64'd0;
            ex_mem_store_int_data <= 32'd0;
            ex_mem_store_fp_data  <= 64'd0;
            ex_mem_pc4          <= 32'd0;
            ex_mem_imm          <= 32'd0;
            ex_mem_rd           <= 5'd0;
            ex_mem_reg_write_int <= 1'b0;
            ex_mem_reg_write_fp <= 1'b0;
            ex_mem_wb_sel       <= `WB_ALU;
            ex_mem_mem_read     <= 1'b0;
            ex_mem_mem_write    <= 1'b0;
            ex_mem_mem_size     <= `MEM_W;
            ex_mem_mem_unsigned <= 1'b0;
            ex_mem_mem_dest_fp  <= 1'b0;
            ex_mem_store_src_fp <= 1'b0;
            mem_wb_valid        <= 1'b0;
            mem_wb_pc           <= 32'd0;
            mem_wb_instr        <= 32'h00000013;
            mem_wb_int_result   <= 32'd0;
            mem_wb_load_data_int<= 32'd0;
            mem_wb_fp_result    <= 64'd0;
            mem_wb_load_data_fp <= 64'd0;
            mem_wb_pc4          <= 32'd0;
            mem_wb_imm          <= 32'd0;
            mem_wb_rd           <= 5'd0;
            mem_wb_reg_write_int<= 1'b0;
            mem_wb_reg_write_fp <= 1'b0;
            mem_wb_wb_sel       <= `WB_ALU;
        end else if (halted) begin
            halted          <= halted;
            illegal_latched <= illegal_latched;
            pc_reg          <= pc_reg;
            if_id_valid     <= if_id_valid;
            id_ex_valid     <= id_ex_valid;
            ex_mem_valid    <= ex_mem_valid;
            mem_wb_valid    <= mem_wb_valid;
        end else if (id_illegal_fire || mem_fault) begin
            halted          <= 1'b1;
            illegal_latched <= 1'b1;
        end else begin
            illegal_latched <= 1'b0;

            if (ex_redirect)
                pc_reg <= ex_target_pc;
            else if (!stall_if)
                pc_reg <= pc_plus4_f;

            if (ex_redirect) begin
                if_id_valid <= 1'b0;
                if_id_pc    <= 32'd0;
                if_id_instr <= 32'h00000013;
            end else if (!stall_id) begin
                if_id_valid <= 1'b1;
                if_id_pc    <= pc_reg;
                if_id_instr <= instr_f;
            end

            if (ex_redirect || bubble_ex) begin
                id_ex_valid         <= 1'b0;
                id_ex_pc            <= 32'd0;
                id_ex_instr         <= 32'h00000013;
                id_ex_imm           <= 32'd0;
                id_ex_rs1           <= 5'd0;
                id_ex_rs2           <= 5'd0;
                id_ex_rd            <= 5'd0;
                id_ex_rs1_val       <= 32'd0;
                id_ex_rs2_val       <= 32'd0;
                id_ex_frs1_val      <= 64'd0;
                id_ex_frs2_val      <= 64'd0;
                id_ex_reg_write_int <= 1'b0;
                id_ex_reg_write_fp  <= 1'b0;
                id_ex_use_rs1_int   <= 1'b0;
                id_ex_use_rs2_int   <= 1'b0;
                id_ex_alu_src_a_pc  <= 1'b0;
                id_ex_alu_src_b_imm <= 1'b0;
                id_ex_alu_op        <= `ALU_ADD;
                id_ex_wb_sel        <= `WB_ALU;
                id_ex_mem_read      <= 1'b0;
                id_ex_mem_write     <= 1'b0;
                id_ex_mem_size      <= `MEM_W;
                id_ex_mem_unsigned  <= 1'b0;
                id_ex_mem_dest_fp   <= 1'b0;
                id_ex_store_src_fp  <= 1'b0;
                id_ex_branch_type   <= `BR_NONE;
                id_ex_jump_type     <= `J_NONE;
                id_ex_fp_op         <= `FP_OP_NONE;
                id_ex_fp_fmt        <= `FP_FMT_S;
            end else begin
                id_ex_valid         <= if_id_valid;
                id_ex_pc            <= if_id_pc;
                id_ex_instr         <= if_id_instr;
                id_ex_imm           <= id_imm_selected;
                id_ex_rs1           <= id_rs1;
                id_ex_rs2           <= id_rs2;
                id_ex_rd            <= id_rd;
                id_ex_rs1_val       <= id_rs1_data;
                id_ex_rs2_val       <= id_rs2_data;
                id_ex_frs1_val      <= id_frs1_data;
                id_ex_frs2_val      <= id_frs2_data;
                id_ex_reg_write_int <= id_reg_write_int;
                id_ex_reg_write_fp  <= id_reg_write_fp;
                id_ex_use_rs1_int   <= id_use_rs1_int;
                id_ex_use_rs2_int   <= id_use_rs2_int;
                id_ex_alu_src_a_pc  <= id_alu_src_a_pc;
                id_ex_alu_src_b_imm <= id_alu_src_b_imm;
                id_ex_alu_op        <= id_alu_op;
                id_ex_wb_sel        <= id_wb_sel;
                id_ex_mem_read      <= id_mem_read;
                id_ex_mem_write     <= id_mem_write;
                id_ex_mem_size      <= id_mem_size;
                id_ex_mem_unsigned  <= id_mem_unsigned;
                id_ex_mem_dest_fp   <= id_mem_dest_fp;
                id_ex_store_src_fp  <= id_store_src_fp;
                id_ex_branch_type   <= id_branch_type;
                id_ex_jump_type     <= id_jump_type;
                id_ex_fp_op         <= id_fp_op;
                id_ex_fp_fmt        <= id_fp_fmt;
            end

            ex_mem_valid          <= id_ex_valid;
            ex_mem_pc             <= id_ex_pc;
            ex_mem_instr          <= id_ex_instr;
            ex_mem_int_result     <= ex_alu_y;
            ex_mem_fp_result      <= ex_fp_y;
            ex_mem_store_int_data <= ex_rs2_forward;
            ex_mem_store_fp_data  <= id_ex_frs2_val;
            ex_mem_pc4            <= ex_pc4;
            ex_mem_imm            <= id_ex_imm;
            ex_mem_rd             <= id_ex_rd;
            ex_mem_reg_write_int  <= id_ex_reg_write_int;
            ex_mem_reg_write_fp   <= id_ex_reg_write_fp;
            ex_mem_wb_sel         <= id_ex_wb_sel;
            ex_mem_mem_read       <= id_ex_mem_read;
            ex_mem_mem_write      <= id_ex_mem_write;
            ex_mem_mem_size       <= id_ex_mem_size;
            ex_mem_mem_unsigned   <= id_ex_mem_unsigned;
            ex_mem_mem_dest_fp    <= id_ex_mem_dest_fp;
            ex_mem_store_src_fp   <= id_ex_store_src_fp;

            mem_wb_valid          <= ex_mem_valid;
            mem_wb_pc             <= ex_mem_pc;
            mem_wb_instr          <= ex_mem_instr;
            mem_wb_int_result     <= ex_mem_int_result;
            mem_wb_load_data_int  <= lsu_load_int;
            mem_wb_fp_result      <= ex_mem_fp_result;
            mem_wb_load_data_fp   <= lsu_load_fp;
            mem_wb_pc4            <= ex_mem_pc4;
            mem_wb_imm            <= ex_mem_imm;
            mem_wb_rd             <= ex_mem_rd;
            mem_wb_reg_write_int  <= ex_mem_reg_write_int;
            mem_wb_reg_write_fp   <= ex_mem_reg_write_fp;
            mem_wb_wb_sel         <= ex_mem_wb_sel;
        end
    end

    assign dbg_pc      = pc_reg;
    assign dbg_instr   = if_id_instr;
    assign dbg_halted  = halted;
    assign dbg_illegal = illegal_latched;
endmodule
