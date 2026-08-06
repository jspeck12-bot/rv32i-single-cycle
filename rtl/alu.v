//=====================================================================
// alu.v -- 32-bit arithmetic / logic unit
//
// Pure combinational. One case statement, one operation per cycle.
// The synthesizer shares the adder between ADD/SUB/SLT automatically;
// writing it explicitly keeps the source readable.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] y
);
    wire signed [31:0] a_s   = a;      // same bits, read as two's complement
    wire signed [31:0] b_s   = b;
    wire        [4:0]  shamt = b[4:0]; // RV32I shifts use only the low 5 bits

    always @(*) begin
        case (alu_ctrl)
            `ALU_ADD : y = a + b;
            `ALU_SUB : y = a - b;
            `ALU_AND : y = a & b;
            `ALU_OR  : y = a | b;
            `ALU_XOR : y = a ^ b;
            `ALU_SLL : y = a << shamt;
            `ALU_SRL : y = a >> shamt;               // logical: shift in 0
            `ALU_SRA : y = a_s >>> shamt;            // arithmetic: shift in sign
            `ALU_SLT : y = {31'b0, (a_s < b_s)};     // signed compare
            `ALU_SLTU: y = {31'b0, (a   < b  )};     // unsigned compare
            default  : y = 32'h0000_0000;
        endcase
    end
endmodule
