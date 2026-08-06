//=====================================================================
// tb_alu.v -- directed unit test for the ALU
//
// Small, fast, and worth having: when the full core test fails, this
// tells you in one second whether the ALU is the problem.
//=====================================================================
`timescale 1ns/1ps
`include "rv32i_defs.vh"

module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  ctrl;
    wire [31:0] y;
    integer errors = 0;

    alu dut (.a(a), .b(b), .alu_ctrl(ctrl), .y(y));

    task check(input [8*12:1] name,
               input [3:0] c, input [31:0] av, input [31:0] bv,
               input [31:0] exp_val);
        begin
            a = av; b = bv; ctrl = c;
            #1;
            if (y !== exp_val) begin
                $display("  FAIL %0s: %08h op %08h = %08h, expected %08h",
                         name, av, bv, y, exp_val);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("");
        $display("--- alu unit test ---");

        check("add",  `ALU_ADD,  32'd7,        32'd5,        32'd12);
        check("add-ov",`ALU_ADD, 32'hFFFFFFFF, 32'd1,        32'd0);
        check("sub",  `ALU_SUB,  32'd7,        32'd5,        32'd2);
        check("sub-neg",`ALU_SUB,32'd5,        32'd7,        32'hFFFFFFFE);
        check("and",  `ALU_AND,  32'hF0F0F0F0, 32'hFF00FF00, 32'hF000F000);
        check("or",   `ALU_OR,   32'hF0F0F0F0, 32'hFF00FF00, 32'hFFF0FFF0);
        check("xor",  `ALU_XOR,  32'hF0F0F0F0, 32'hFF00FF00, 32'h0FF00FF0);
        check("sll",  `ALU_SLL,  32'h00000001, 32'd31,       32'h80000000);
        check("sll-m",`ALU_SLL,  32'h00000001, 32'd32,       32'h00000001); // shamt = b[4:0]
        check("srl",  `ALU_SRL,  32'h80000000, 32'd4,        32'h08000000);
        check("sra",  `ALU_SRA,  32'h80000000, 32'd4,        32'hF8000000);
        check("sra-p",`ALU_SRA,  32'h40000000, 32'd4,        32'h04000000);
        check("slt",  `ALU_SLT,  32'hFFFFFFFF, 32'd1,        32'd1);   // -1 < 1
        check("slt-f",`ALU_SLT,  32'd1,        32'hFFFFFFFF, 32'd0);
        check("sltu", `ALU_SLTU, 32'hFFFFFFFF, 32'd1,        32'd0);
        check("sltu-t",`ALU_SLTU,32'd1,        32'hFFFFFFFF, 32'd1);

        if (errors == 0) $display("  alu: all cases passed");
        else             $display("  alu: %0d FAILURES", errors);
        $display("");
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
