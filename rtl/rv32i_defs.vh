//=====================================================================
// rv32i_defs.vh -- shared encodings for the single-cycle RV32I core
//
// One place for every magic number in the design. Every RTL file that
// needs an opcode, an ALU code, or a mux select `include`s this.
//=====================================================================
`ifndef RV32I_DEFS_VH
`define RV32I_DEFS_VH

//--------------------------- RV32I opcodes ---------------------------
`define OP_LUI     7'b0110111
`define OP_AUIPC   7'b0010111
`define OP_JAL     7'b1101111
`define OP_JALR    7'b1100111
`define OP_BRANCH  7'b1100011
`define OP_LOAD    7'b0000011
`define OP_STORE   7'b0100011
`define OP_IMM     7'b0010011   // ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI
`define OP_REG     7'b0110011   // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

//------------------------- ALU operation codes ------------------------
`define ALU_ADD    4'd0
`define ALU_SUB    4'd1
`define ALU_AND    4'd2
`define ALU_OR     4'd3
`define ALU_XOR    4'd4
`define ALU_SLL    4'd5
`define ALU_SRL    4'd6
`define ALU_SRA    4'd7
`define ALU_SLT    4'd8
`define ALU_SLTU   4'd9

//----------------------- ALUOp (decoder -> ALU dec) -------------------
`define ALUOP_ADD  2'b00   // address math: loads, stores, JALR, AUIPC, LUI
`define ALUOP_SUB  2'b01   // reserved
`define ALUOP_FUNC 2'b10   // decode from funct3 / funct7[5]

//-------------------------- Immediate formats -------------------------
`define IMM_I      3'd0
`define IMM_S      3'd1
`define IMM_B      3'd2
`define IMM_U      3'd3
`define IMM_J      3'd4

//------------------------ Writeback result mux ------------------------
`define RES_ALU    2'd0
`define RES_MEM    2'd1
`define RES_PC4    2'd2

//------------------------- ALU 'A' operand mux ------------------------
`define SRCA_RS1   2'd0
`define SRCA_PC    2'd1   // AUIPC
`define SRCA_ZERO  2'd2   // LUI  (0 + imm = imm)

//---------------------------- Next-PC mux -----------------------------
`define PC_PLUS4   2'd0
`define PC_TARGET  2'd1   // PC + imm  (taken branch, JAL)
`define PC_JALR    2'd2   // (rs1 + imm) & ~1

`endif
