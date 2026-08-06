//=====================================================================
// alu_decoder.v -- (alu_op, funct3, funct7[5]) -> ALU control
//
// The one subtlety in RV32I: funct7[5] means "subtract" for ADD/SUB
// but is only valid on R-type. There is no SUBI, so for OP_IMM with
// funct3=000 we must force ADD regardless of funct7. SRLI/SRAI DO use
// funct7[5], because the shift amount only occupies instr[24:20].
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module alu_decoder (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,    // instr[30]
    input  wire       op_is_reg,   // 1 when opcode == OP_REG
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            `ALUOP_ADD: alu_ctrl = `ALU_ADD;
            `ALUOP_SUB: alu_ctrl = `ALU_SUB;
            default: begin
                case (funct3)
                    3'b000 : alu_ctrl = (op_is_reg && funct7b5) ? `ALU_SUB : `ALU_ADD;
                    3'b001 : alu_ctrl = `ALU_SLL;
                    3'b010 : alu_ctrl = `ALU_SLT;
                    3'b011 : alu_ctrl = `ALU_SLTU;
                    3'b100 : alu_ctrl = `ALU_XOR;
                    3'b101 : alu_ctrl = funct7b5 ? `ALU_SRA : `ALU_SRL;
                    3'b110 : alu_ctrl = `ALU_OR;
                    3'b111 : alu_ctrl = `ALU_AND;
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end
        endcase
    end
endmodule
