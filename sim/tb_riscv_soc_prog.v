//=====================================================================
// tb_riscv_soc_prog.v -- runs the gcc-compiled C demo on the core
//
// This is the test that proves the definition of done: a program
// written in C, compiled by riscv32-unknown-elf-gcc with -march=rv32i,
// executes correctly on the RTL.
//
// It lets the CPU boot, waits for the Fibonacci table to be built in
// RAM, drives the switches, and checks that the right value appears on
// the 7-segment output register.
//
//   iverilog -g2012 -I ../rtl -o tb_prog.out -s tb_riscv_soc_prog \
//            ../rtl/*.v tb_riscv_soc_prog.v
//   vvp tb_prog.out
//=====================================================================
`timescale 1ns/1ps

module tb_riscv_soc_prog;

    localparam integer CLK_NS = 20;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg  [15:0] sw  = 16'd0;
    wire [15:0] led, hex;
    wire        illegal_instr;
    integer     errors = 0;

    always #(CLK_NS/2) clk = ~clk;

    riscv_soc #(
        .IMEM_INIT ("imem.hex"),
        .DMEM_INIT ("dmem.hex")
    ) dut (
        .clk(clk), .rst(rst), .sw(sw),
        .led(led), .hex(hex), .illegal_instr(illegal_instr)
    );

    // expected Fibonacci table (fib[0]=0, fib[1]=1)
    reg [31:0] expect_fib [0:23];
    integer i;

    task check_hex(input [15:0] idx, input [15:0] want);
        begin
            sw = idx;
            repeat (600) @(posedge clk);      // let the polling loop run
            if (hex !== want) begin
                $display("  FAIL: sw=%0d  hex=%04h  expected %04h", idx, hex, want);
                errors = errors + 1;
            end else begin
                $display("  ok:   sw=%0d  hex=%04h  (fib[%0d])", idx, hex, idx);
            end
        end
    endtask

    initial begin
        expect_fib[0]  = 0;
        for (i = 1; i < 24; i = i + 1)
            expect_fib[i] = (i == 1) ? 32'd1 : expect_fib[i-1] + expect_fib[i-2];

        $display("");
        $display("=========================================================");
        $display(" single-cycle RV32I -- running gcc-compiled C");
        $display("=========================================================");

        repeat (4) @(posedge clk);
        rst = 1'b0;

        // give crt0 + compute_fib() time to finish
        repeat (4000) @(posedge clk);

        // verify the table in RAM (RAM word 0 == 0x10000000 == &fib[0])
        for (i = 0; i < 24; i = i + 1) begin
            if (dut.u_dmem.mem[i] !== expect_fib[i]) begin
                $display("  FAIL: fib[%0d] in RAM = %08h, expected %08h",
                         i, dut.u_dmem.mem[i], expect_fib[i]);
                errors = errors + 1;
            end
        end
        if (errors == 0)
            $display("  Fibonacci table in RAM matches (24 entries)");

        // verify the MMIO path end to end
        check_hex(16'd0,  16'h0000);
        check_hex(16'd10, expect_fib[10][15:0]);
        check_hex(16'd23, expect_fib[23][15:0]);

        $display("");
        if (errors == 0) $display("  C PROGRAM RAN CORRECTLY");
        else             $display("  %0d FAILURES", errors);
        $display("=========================================================");
        $display("");
        if (errors != 0) $fatal(1);
        $finish;
    end

    always @(posedge clk)
        if (!rst && illegal_instr) begin
            $display("  FAIL: illegal instruction at pc=%08h", dut.u_core.pc);
            $fatal(1);
        end

endmodule
