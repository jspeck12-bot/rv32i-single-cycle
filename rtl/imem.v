//=====================================================================
// imem.v -- instruction ROM
//
// Asynchronous read, because a single-cycle CPU has to fetch, decode,
// execute and write back inside one clock period. On the Artix-7 this
// becomes a LUT-based ROM, not block RAM. That is the price of the
// single-cycle architecture and it is the honest way to build it.
//
// Contents come from imem.hex, produced by sw/Makefile.
//=====================================================================
`timescale 1ns/1ps

module imem #(
    parameter integer AW   = 10,          // word-address bits (1024 words = 4 KB)
    parameter         INIT = "imem.hex"
)(
    input  wire [31:0] addr,              // BYTE address
    output wire [31:0] rdata
);
    localparam integer WORDS = (1 << AW);

    reg [31:0] rom [0:WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) rom[i] = 32'h0000_0000;
        $readmemh(INIT, rom);
    end

    assign rdata = rom[addr[AW+1:2]];     // drop the 2 byte-offset bits
endmodule
