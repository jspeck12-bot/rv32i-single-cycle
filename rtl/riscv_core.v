//=====================================================================
// riscv_core.v -- single-cycle RV32I datapath + control
//
// One instruction per clock. No pipeline, no hazards, no stalls.
// The clock period must cover the entire path:
//
//   PC -> IMEM -> decode -> regfile read -> ALU -> DMEM -> writeback
//
// Implements the RV32I base integer ISA except FENCE, ECALL, EBREAK
// and the Zicsr CSR instructions.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module riscv_core #(
    parameter [31:0] RESET_PC = 32'h0000_0000
)(
    input  wire        clk,
    input  wire        rst,           // synchronous, active high

    // instruction port
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // data port
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    input  wire [31:0] dmem_rdata,

    output wire        illegal_instr  // debug / trap hook
);
    //================= declarations (all nets up front) ===============
    reg  [31:0] pc;
    reg  [31:0] pc_next;
    reg  [31:0] src_a;
    reg  [31:0] result;

    wire [31:0] pc_plus4;
    wire [31:0] pc_target;
    wire [31:0] pc_jalr;

    wire [31:0] instr;
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire        funct7b5;
    wire [4:0]  rs1_a, rs2_a, rd_a;

    wire        reg_write, alu_src_b, mem_write, branch_take;
    wire [1:0]  alu_src_a, result_src, pc_src;
    wire [2:0]  imm_src;
    wire [3:0]  alu_ctrl;

    wire [31:0] rd1, rd2, imm, alu_result, load_data;
    wire [31:0] src_b;

    //======================= instruction fields ========================
    assign instr    = imem_rdata;
    assign opcode   = instr[6:0];
    assign funct3   = instr[14:12];
    assign funct7b5 = instr[30];
    assign rs1_a    = instr[19:15];
    assign rs2_a    = instr[24:20];
    assign rd_a     = instr[11:7];

    //========================= program counter =========================
    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm;                        // branches, JAL
    assign pc_jalr   = {alu_result[31:1], 1'b0};        // JALR clears bit 0

    always @(*) begin
        case (pc_src)
            `PC_TARGET: pc_next = pc_target;
            `PC_JALR  : pc_next = pc_jalr;
            default   : pc_next = pc_plus4;
        endcase
    end

    always @(posedge clk) begin
        if (rst) pc <= RESET_PC;
        else     pc <= pc_next;
    end

    assign imem_addr = pc;

    //============================= control =============================
    controller u_ctrl (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7b5    (funct7b5),
        .branch_take (branch_take),
        .reg_write   (reg_write),
        .imm_src     (imm_src),
        .alu_src_a   (alu_src_a),
        .alu_src_b   (alu_src_b),
        .mem_write   (mem_write),
        .result_src  (result_src),
        .alu_ctrl    (alu_ctrl),
        .pc_src      (pc_src),
        .illegal     (illegal_instr)
    );

    //============================= datapath ============================
    regfile u_rf (
        .clk (clk),
        .we  (reg_write),
        .ra1 (rs1_a),
        .ra2 (rs2_a),
        .wa  (rd_a),
        .wd  (result),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    extend u_ext (
        .instr   (instr[31:7]),
        .imm_src (imm_src),
        .imm     (imm)
    );

    branch_unit u_br (
        .funct3 (funct3),
        .rs1    (rd1),
        .rs2    (rd2),
        .take   (branch_take)
    );

    // ALU operand A: rs1 / PC (auipc) / zero (lui)
    always @(*) begin
        case (alu_src_a)
            `SRCA_PC  : src_a = pc;
            `SRCA_ZERO: src_a = 32'h0000_0000;
            default   : src_a = rd1;
        endcase
    end

    // ALU operand B: rs2 or immediate
    assign src_b = alu_src_b ? imm : rd2;

    alu u_alu (
        .a        (src_a),
        .b        (src_b),
        .alu_ctrl (alu_ctrl),
        .y        (alu_result)
    );

    //=========================== memory access =========================
    lsu u_lsu (
        .addr_lo    (alu_result[1:0]),
        .funct3     (funct3),
        .mem_write  (mem_write),
        .rs2        (rd2),
        .rdata_word (dmem_rdata),
        .wdata_word (dmem_wdata),
        .wstrb      (dmem_wstrb),
        .load_data  (load_data)
    );

    assign dmem_addr = alu_result;

    //============================= writeback ===========================
    always @(*) begin
        case (result_src)
            `RES_MEM: result = load_data;
            `RES_PC4: result = pc_plus4;      // JAL / JALR return address
            default : result = alu_result;
        endcase
    end
endmodule
