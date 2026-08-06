//=====================================================================
// regfile.v -- 32 x 32-bit architectural register file
//
// Two asynchronous read ports, one synchronous write port.
// x0 is hardwired to zero: writes to it are dropped, reads return 0.
//
// Async read is what makes a SINGLE-CYCLE design possible: read, ALU,
// and writeback all happen inside one clock period. On the Artix-7 this
// infers distributed RAM (LUTRAM), not block RAM.
//=====================================================================
`timescale 1ns/1ps

module regfile (
    input  wire        clk,
    input  wire        we,       // write enable
    input  wire [4:0]  ra1,      // read address 1 (rs1)
    input  wire [4:0]  ra2,      // read address 2 (rs2)
    input  wire [4:0]  wa,       // write address  (rd)
    input  wire [31:0] wd,       // write data
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] rf [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0000_0000;
    end

    // Write lands at the END of the cycle -- correct for single-cycle.
    always @(posedge clk)
        if (we && (wa != 5'd0))
            rf[wa] <= wd;

    assign rd1 = (ra1 == 5'd0) ? 32'h0000_0000 : rf[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'h0000_0000 : rf[ra2];
endmodule
