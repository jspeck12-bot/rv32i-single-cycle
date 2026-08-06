//=====================================================================
// extend.v -- immediate generator
//
// RV32I scatters the immediate bits across the instruction word so that
// each bit lands in roughly the same place in every format. This block
// puts them back together and sign-extends to 32 bits.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module extend (
    input  wire [31:7] instr,     // only bits 31:7 carry immediate data
    input  wire [2:0]  imm_src,
    output reg  [31:0] imm
);
    always @(*) begin
        case (imm_src)
            // I-type: addi, loads, jalr  -- imm[11:0] = instr[31:20]
            `IMM_I: imm = {{20{instr[31]}}, instr[31:20]};

            // S-type: stores             -- imm[11:5]|imm[4:0]
            `IMM_S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type: branches           -- imm[12|10:5|4:1|11], bit0 = 0
            `IMM_B: imm = {{20{instr[31]}}, instr[7], instr[30:25],
                            instr[11:8], 1'b0};

            // U-type: lui, auipc         -- imm[31:12], low 12 bits = 0
            `IMM_U: imm = {instr[31:12], 12'b0};

            // J-type: jal                -- imm[20|10:1|11|19:12], bit0 = 0
            `IMM_J: imm = {{12{instr[31]}}, instr[19:12], instr[20],
                            instr[30:21], 1'b0};

            default: imm = 32'h0000_0000;
        endcase
    end
endmodule
