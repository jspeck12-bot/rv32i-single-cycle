//=====================================================================
// tb_riscv_soc.v -- self-checking testbench for the RV32I SoC
//
// Runs sw/test.S and watches the data bus. The test program signals
// success by storing 0x2A to 0x1000_0064 and failure by writing a test
// number to the LED register at 0x2000_0000.
//
// Run with icarus:
//   iverilog -g2012 -I ../rtl -o tb.out -s tb_riscv_soc \
//            ../rtl/*.v tb_riscv_soc.v
//   vvp tb.out
//
// Optional: +TRACE dumps every retired instruction.
//=====================================================================
`timescale 1ns/1ps

module tb_riscv_soc;

    localparam integer CLK_NS      = 20;          // 50 MHz sim clock
    localparam [31:0]  PASS_ADDR   = 32'h1000_0064;
    localparam [31:0]  PASS_VAL    = 32'h0000_002A;
    localparam [31:0]  LED_ADDR    = 32'h2000_0000;
    localparam integer MAX_CYCLES  = 200_000;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg  [15:0] sw  = 16'h0000;
    wire [15:0] led;
    wire [15:0] hex;
    wire        illegal_instr;

    integer cycles = 0;
    integer trace  = 0;

    always #(CLK_NS/2) clk = ~clk;

    riscv_soc #(
        .IMEM_INIT ("imem_test.hex"),
        .DMEM_INIT ("dmem_test.hex")
    ) dut (
        .clk           (clk),
        .rst           (rst),
        .sw            (sw),
        .led           (led),
        .hex           (hex),
        .illegal_instr (illegal_instr)
    );

    //-------------------------- convenience taps ----------------------
    wire [31:0] pc        = dut.u_core.pc;
    wire [31:0] instr     = dut.u_core.instr;
    wire [31:0] d_addr    = dut.dmem_addr;
    wire [31:0] d_wdata   = dut.dmem_wdata;
    wire [3:0]  d_wstrb   = dut.dmem_wstrb;

    //------------------------------ stimulus --------------------------
    initial begin
        if ($test$plusargs("TRACE")) trace = 1;
        if ($test$plusargs("VCD")) begin
            $dumpfile("tb_riscv_soc.vcd");
            $dumpvars(0, tb_riscv_soc);
        end

        $display("");
        $display("=========================================================");
        $display(" single-cycle RV32I -- ISA self-test");
        $display("=========================================================");

        repeat (4) @(posedge clk);
        rst = 1'b0;
    end

    //------------------------- pass / fail watch ----------------------
    always @(posedge clk) begin
        if (!rst) begin
            cycles <= cycles + 1;

            if (trace)
                $display("  %0t  pc=%08h  instr=%08h", $time, pc, instr);

            if (illegal_instr)
                fail("illegal instruction fetched");

            if (d_wstrb == 4'b1111 && d_addr == PASS_ADDR) begin
                if (d_wdata == PASS_VAL) begin
                    $display("");
                    $display("  ALL TESTS PASSED   (%0d cycles)", cycles);
                    $display("=========================================================");
                    $display("");
                    $finish;
                end else begin
                    $display("  signature mismatch: got %08h expected %08h",
                             d_wdata, PASS_VAL);
                    fail("bad signature");
                end
            end

            if ((|d_wstrb) && d_addr == LED_ADDR && d_wdata != 32'h0000_00FF) begin
                $display("");
                $display("  TEST %0d FAILED  (pc=%08h)", d_wdata, pc);
                fail("self-test reported a failure");
            end

            if (cycles > MAX_CYCLES)
                fail("timeout -- core never reached the pass store");
        end
    end

    task fail(input [8*48:1] why);
        begin
            $display("  FAIL: %0s", why);
            $display("  pc=%08h instr=%08h  after %0d cycles", pc, instr, cycles);
            $display("=========================================================");
            $display("");
            $fatal(1);
        end
    endtask

endmodule
