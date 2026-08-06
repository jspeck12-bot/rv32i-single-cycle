//=====================================================================
// dmem.v -- data RAM with per-byte write enables
//
// Asynchronous read (single-cycle), synchronous byte-granular write.
// Splitting the write into four byte lanes is what makes SB and SH
// work without a read-modify-write.
//
// Contents come from dmem.hex (.rodata + initialized .data).
//=====================================================================
`timescale 1ns/1ps

module dmem #(
    parameter integer AW   = 10,          // word-address bits (1024 words = 4 KB)
    parameter         INIT = "dmem.hex"
)(
    input  wire        clk,
    input  wire [31:0] addr,              // BYTE address
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire [31:0] rdata
);
    localparam integer WORDS = (1 << AW);

    reg [31:0] mem [0:WORDS-1];
    wire [AW-1:0] widx = addr[AW+1:2];

    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'h0000_0000;
        $readmemh(INIT, mem);
    end

    always @(posedge clk) begin
        if (wstrb[0]) mem[widx][7:0]   <= wdata[7:0];
        if (wstrb[1]) mem[widx][15:8]  <= wdata[15:8];
        if (wstrb[2]) mem[widx][23:16] <= wdata[23:16];
        if (wstrb[3]) mem[widx][31:24] <= wdata[31:24];
    end

    assign rdata = mem[widx];
endmodule
