//=====================================================================
// lsu.v -- load/store alignment unit
//
// The data memory is 32 bits wide and word-addressed. RV32I lets you
// touch bytes and halfwords, so something has to sit between the CPU
// and the RAM to:
//   - STORE: shift rs2 into the right lane and produce byte-enables
//   - LOAD : pick the right lane out of the returned word and
//            sign- or zero-extend it
//
// Note: this is a purely combinational unit and does NOT trap on
// misaligned accesses. That is a documented limitation, not an
// accident -- see README.
//=====================================================================
`timescale 1ns/1ps

module lsu (
    input  wire [1:0]  addr_lo,      // byte offset within the word
    input  wire [2:0]  funct3,       // width + signedness
    input  wire        mem_write,
    input  wire [31:0] rs2,          // value being stored
    input  wire [31:0] rdata_word,   // raw 32-bit word from memory

    output reg  [31:0] wdata_word,   // lane-aligned store data
    output reg  [3:0]  wstrb,        // per-byte write enables
    output reg  [31:0] load_data     // extracted + extended load result
);
    //---------------------------- STORE ------------------------------
    always @(*) begin
        wdata_word = rs2;
        wstrb      = 4'b0000;
        if (mem_write) begin
            case (funct3)
                3'b000: begin                       // SB
                    wdata_word = {4{rs2[7:0]}};     // same byte in all lanes
                    wstrb      = 4'b0001 << addr_lo;
                end
                3'b001: begin                       // SH
                    wdata_word = {2{rs2[15:0]}};
                    wstrb      = addr_lo[1] ? 4'b1100 : 4'b0011;
                end
                3'b010: begin                       // SW
                    wdata_word = rs2;
                    wstrb      = 4'b1111;
                end
                default: begin
                    wdata_word = rs2;
                    wstrb      = 4'b0000;
                end
            endcase
        end
    end

    //----------------------------- LOAD ------------------------------
    reg [7:0]  sel_byte;
    reg [15:0] sel_half;

    always @(*) begin
        case (addr_lo)
            2'd0   : sel_byte = rdata_word[7:0];
            2'd1   : sel_byte = rdata_word[15:8];
            2'd2   : sel_byte = rdata_word[23:16];
            default: sel_byte = rdata_word[31:24];
        endcase

        sel_half = addr_lo[1] ? rdata_word[31:16] : rdata_word[15:0];

        case (funct3)
            3'b000 : load_data = {{24{sel_byte[7]}},  sel_byte};   // LB
            3'b001 : load_data = {{16{sel_half[15]}}, sel_half};   // LH
            3'b010 : load_data = rdata_word;                        // LW
            3'b100 : load_data = {24'b0, sel_byte};                 // LBU
            3'b101 : load_data = {16'b0, sel_half};                 // LHU
            default: load_data = rdata_word;
        endcase
    end
endmodule
