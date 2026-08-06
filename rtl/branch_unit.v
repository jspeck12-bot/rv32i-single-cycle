//=====================================================================
// branch_unit.v -- branch condition evaluator
//
// A design choice worth being able to defend: branches are resolved by
// a dedicated comparator fed straight from the register file, NOT by
// reusing the ALU's zero flag. Costs one extra comparator; buys a
// shorter control path and makes BLT/BGE/BLTU/BGEU fall out for free.
//=====================================================================
`timescale 1ns/1ps

module branch_unit (
    input  wire [2:0]  funct3,
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    output reg         take
);
    wire signed [31:0] s1 = rs1;
    wire signed [31:0] s2 = rs2;

    always @(*) begin
        case (funct3)
            3'b000 : take = (rs1 == rs2);   // BEQ
            3'b001 : take = (rs1 != rs2);   // BNE
            3'b100 : take = (s1   <  s2 );  // BLT   signed
            3'b101 : take = (s1   >= s2 );  // BGE   signed
            3'b110 : take = (rs1  <  rs2);  // BLTU  unsigned
            3'b111 : take = (rs1  >= rs2);  // BGEU  unsigned
            default: take = 1'b0;
        endcase
    end
endmodule
