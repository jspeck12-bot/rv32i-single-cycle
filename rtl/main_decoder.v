//=====================================================================
// main_decoder.v -- opcode -> control signals
//
// Pure combinational lookup on the 7-bit opcode. Every output is
// assigned on every path (defaults first) so no latch is inferred.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module main_decoder (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg  [2:0] imm_src,
    output reg  [1:0] alu_src_a,
    output reg        alu_src_b,    // 0 = rs2, 1 = immediate
    output reg        mem_write,
    output reg  [1:0] result_src,
    output reg        branch,       // conditional branch
    output reg        jump,         // JAL   -> PC + imm
    output reg        jalr,         // JALR  -> (rs1 + imm) & ~1
    output reg  [1:0] alu_op,
    output reg        illegal
);
    always @(*) begin
        // ---- safe defaults: do nothing, change nothing ----
        reg_write  = 1'b0;
        imm_src    = `IMM_I;
        alu_src_a  = `SRCA_RS1;
        alu_src_b  = 1'b0;
        mem_write  = 1'b0;
        result_src = `RES_ALU;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_op     = `ALUOP_ADD;
        illegal    = 1'b0;

        case (opcode)
            // ---- R-type: add sub sll slt sltu xor srl sra or and ----
            `OP_REG: begin
                reg_write  = 1'b1;
                alu_src_a  = `SRCA_RS1;
                alu_src_b  = 1'b0;          // second operand is rs2
                result_src = `RES_ALU;
                alu_op     = `ALUOP_FUNC;
            end

            // ---- I-type ALU: addi slti sltiu xori ori andi slli srli srai ----
            `OP_IMM: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_I;
                alu_src_a  = `SRCA_RS1;
                alu_src_b  = 1'b1;
                result_src = `RES_ALU;
                alu_op     = `ALUOP_FUNC;
            end

            // ---- loads: lb lh lw lbu lhu ----
            `OP_LOAD: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_I;
                alu_src_a  = `SRCA_RS1;
                alu_src_b  = 1'b1;          // address = rs1 + imm
                result_src = `RES_MEM;
                alu_op     = `ALUOP_ADD;
            end

            // ---- stores: sb sh sw ----
            `OP_STORE: begin
                imm_src    = `IMM_S;
                alu_src_a  = `SRCA_RS1;
                alu_src_b  = 1'b1;
                mem_write  = 1'b1;
                alu_op     = `ALUOP_ADD;
            end

            // ---- branches: beq bne blt bge bltu bgeu ----
            `OP_BRANCH: begin
                imm_src    = `IMM_B;
                branch     = 1'b1;          // condition comes from branch_unit
                alu_op     = `ALUOP_ADD;
            end

            // ---- jal ----
            `OP_JAL: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_J;
                result_src = `RES_PC4;      // rd = return address
                jump       = 1'b1;
            end

            // ---- jalr ----
            `OP_JALR: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_I;
                alu_src_a  = `SRCA_RS1;
                alu_src_b  = 1'b1;          // ALU computes rs1 + imm
                result_src = `RES_PC4;
                jalr       = 1'b1;
                alu_op     = `ALUOP_ADD;
            end

            // ---- lui: rd = imm[31:12] << 12  (0 + U-imm) ----
            `OP_LUI: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_U;
                alu_src_a  = `SRCA_ZERO;
                alu_src_b  = 1'b1;
                result_src = `RES_ALU;
                alu_op     = `ALUOP_ADD;
            end

            // ---- auipc: rd = PC + (imm[31:12] << 12) ----
            `OP_AUIPC: begin
                reg_write  = 1'b1;
                imm_src    = `IMM_U;
                alu_src_a  = `SRCA_PC;
                alu_src_b  = 1'b1;
                result_src = `RES_ALU;
                alu_op     = `ALUOP_ADD;
            end

            default: begin
                illegal = 1'b1;             // unimplemented -> flagged, NOP'd
            end
        endcase
    end
endmodule
