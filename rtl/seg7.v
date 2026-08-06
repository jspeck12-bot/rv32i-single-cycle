//=====================================================================
// seg7.v -- 4-digit hex display driver for the Basys 3
//
// Time-multiplexes the four common-anode digits. Both the anodes and
// the cathodes are ACTIVE LOW on this board. Refresh runs off the raw
// 100 MHz clock at ~380 Hz per digit -- fast enough that the eye sees
// all four lit at once.
//=====================================================================
`timescale 1ns/1ps

module seg7 (
    input  wire        clk,        // 100 MHz board clock
    input  wire [15:0] value,      // hex value to display
    output reg  [3:0]  an,         // digit anodes, active low
    output reg  [6:0]  seg,        // cathodes CA..CG, active low
    output wire        dp
);
    reg [17:0] cnt = 18'd0;
    always @(posedge clk) cnt <= cnt + 18'd1;

    wire [1:0] digit_sel = cnt[17:16];
    reg  [3:0] nib;

    always @(*) begin
        case (digit_sel)
            2'd0   : begin nib = value[3:0];   an = 4'b1110; end
            2'd1   : begin nib = value[7:4];   an = 4'b1101; end
            2'd2   : begin nib = value[11:8];  an = 4'b1011; end
            default: begin nib = value[15:12]; an = 4'b0111; end
        endcase
    end

    always @(*) begin
        case (nib)                 //      gfedcba  (0 = segment ON)
            4'h0   : seg = 7'b1000000;
            4'h1   : seg = 7'b1111001;
            4'h2   : seg = 7'b0100100;
            4'h3   : seg = 7'b0110000;
            4'h4   : seg = 7'b0011001;
            4'h5   : seg = 7'b0010010;
            4'h6   : seg = 7'b0000010;
            4'h7   : seg = 7'b1111000;
            4'h8   : seg = 7'b0000000;
            4'h9   : seg = 7'b0010000;
            4'hA   : seg = 7'b0001000;
            4'hB   : seg = 7'b0000011;
            4'hC   : seg = 7'b1000110;
            4'hD   : seg = 7'b0100001;
            4'hE   : seg = 7'b0000110;
            default: seg = 7'b0001110;   // F
        endcase
    end

    assign dp = 1'b1;   // decimal point off
endmodule
