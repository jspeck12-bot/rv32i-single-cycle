//=====================================================================
// controller.v -- the whole control unit
//
// main_decoder (opcode) + alu_decoder (funct fields) + next-PC select.
// Entirely combinational: in a single-cycle machine the control unit
// has no state of its own.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module controller (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    input  wire       branch_take,   // from branch_unit

    output wire       reg_write,
    output wire [2:0] imm_src,
    output wire [1:0] alu_src_a,
    output wire       alu_src_b,
    output wire       mem_write,
    output wire [1:0] result_src,
    output wire [3:0] alu_ctrl,
    output wire [1:0] pc_src,
    output wire       illegal
);
    wire       branch, jump, jalr;
    wire [1:0] alu_op;

    main_decoder u_main (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .imm_src    (imm_src),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .mem_write  (mem_write),
        .result_src (result_src),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr),
        .alu_op     (alu_op),
        .illegal    (illegal)
    );

    alu_decoder u_aludec (
        .alu_op    (alu_op),
        .funct3    (funct3),
        .funct7b5  (funct7b5),
        .op_is_reg (opcode == `OP_REG),
        .alu_ctrl  (alu_ctrl)
    );

    // Next-PC select. JALR wins, then JAL / taken branch, else PC+4.
    assign pc_src = jalr                            ? `PC_JALR   :
                    (jump || (branch && branch_take)) ? `PC_TARGET :
                                                        `PC_PLUS4;
endmodule
