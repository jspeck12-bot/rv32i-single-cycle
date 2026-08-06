//=====================================================================
// top_basys3.v -- board wrapper for the Digilent Basys 3 (XC7A35T)
//
// Clocking: the board gives 100 MHz. A single-cycle RV32I with
// LUT-based memories will not close timing there, so the CPU runs on a
// divide-by-8 clock (12.5 MHz) routed through a BUFG. The generated
// clock is declared in constr/Basys3.xdc so the timing engine analyses
// the real CPU period rather than 10 ns.
//
// Reset: btnC, resynchronized into the CPU clock domain. The shift
// register powers up all-ones so the core is held in reset for a few
// cycles after configuration.
//
// I/O: 16 switches in, 16 LEDs out, 4-digit hex display out.
//=====================================================================
`timescale 1ns/1ps

module top_basys3 (
    input  wire        clk,        // W5, 100 MHz
    input  wire        btnC,       // U18, reset (active high when pressed)
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);
    //------------------------- CPU clock 12.5 MHz -----------------------
    reg [2:0] div = 3'd0;
    always @(posedge clk) div <= div + 3'd1;

    wire cpu_clk_raw = div[2];
    wire cpu_clk;

    BUFG u_bufg_cpu (.I(cpu_clk_raw), .O(cpu_clk));

    //---------------------- reset synchronizer --------------------------
    reg [2:0] rst_sync = 3'b111;
    always @(posedge cpu_clk) rst_sync <= {rst_sync[1:0], btnC};
    wire rst = rst_sync[2];

    //------------------------------ SoC ---------------------------------
    wire [15:0] hex;
    wire        illegal_instr;

    riscv_soc #(
        .IMEM_INIT ("imem.hex"),
        .DMEM_INIT ("dmem.hex")
    ) u_soc (
        .clk           (cpu_clk),
        .rst           (rst),
        .sw            (sw),
        .led           (led),
        .hex           (hex),
        .illegal_instr (illegal_instr)
    );

    //-------------------------- hex display -----------------------------
    seg7 u_seg7 (
        .clk   (clk),         // refresh from the fast clock
        .value (hex),
        .an    (an),
        .seg   (seg),
        .dp    (dp)
    );
endmodule
