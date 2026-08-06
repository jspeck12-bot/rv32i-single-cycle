//=====================================================================
// riscv_soc.v -- core + memories + memory-mapped I/O
//
// Memory map
//   0x0000_0000 - 0x0000_0FFF   instruction ROM   (4 KB, imem.hex)
//   0x1000_0000 - 0x1000_0FFF   data RAM          (4 KB, dmem.hex)
//   0x2000_0000                 LED  register     (write, 16 bit)
//   0x2000_0004                 switch input      (read,  16 bit)
//   0x2000_0008                 7-seg hex value   (write, 16 bit)
//
// Stack starts at 0x1000_1000 and grows down (set in sw/link.ld).
//=====================================================================
`timescale 1ns/1ps

module riscv_soc #(
    parameter IMEM_INIT = "imem.hex",
    parameter DMEM_INIT = "dmem.hex"
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [15:0] hex,
    output wire        illegal_instr
);
    wire [31:0] imem_addr, imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire [3:0]  dmem_wstrb;

    //------------------------------ CPU -------------------------------
    riscv_core #(.RESET_PC(32'h0000_0000)) u_core (
        .clk           (clk),
        .rst           (rst),
        .imem_addr     (imem_addr),
        .imem_rdata    (imem_rdata),
        .dmem_addr     (dmem_addr),
        .dmem_wdata    (dmem_wdata),
        .dmem_wstrb    (dmem_wstrb),
        .dmem_rdata    (dmem_rdata),
        .illegal_instr (illegal_instr)
    );

    //-------------------------- instruction ROM ------------------------
    imem #(.AW(10), .INIT(IMEM_INIT)) u_imem (
        .addr  (imem_addr),
        .rdata (imem_rdata)
    );

    //-------------------------- address decode -------------------------
    wire sel_ram  = (dmem_addr[31:28] == 4'h1);
    wire sel_mmio = (dmem_addr[31:28] == 4'h2);

    //----------------------------- data RAM ----------------------------
    wire [31:0] ram_rdata;

    dmem #(.AW(10), .INIT(DMEM_INIT)) u_dmem (
        .clk   (clk),
        .addr  (dmem_addr),
        .wdata (dmem_wdata),
        .wstrb (sel_ram ? dmem_wstrb : 4'b0000),
        .rdata (ram_rdata)
    );

    //------------------------------ MMIO -------------------------------
    reg [15:0] led_r;
    reg [15:0] hex_r;
    wire       mmio_we = sel_mmio & (|dmem_wstrb);

    always @(posedge clk) begin
        if (rst) begin
            led_r <= 16'h0000;
            hex_r <= 16'h0000;
        end else if (mmio_we) begin
            case (dmem_addr[7:2])
                6'd0: led_r <= dmem_wdata[15:0];   // 0x2000_0000
                6'd2: hex_r <= dmem_wdata[15:0];   // 0x2000_0008
                default: ;
            endcase
        end
    end

    wire [31:0] mmio_rdata = (dmem_addr[7:2] == 6'd1) ? {16'h0000, sw} :
                             (dmem_addr[7:2] == 6'd0) ? {16'h0000, led_r} :
                                                        32'h0000_0000;

    //------------------------- read data return ------------------------
    assign dmem_rdata = sel_ram  ? ram_rdata  :
                        sel_mmio ? mmio_rdata :
                                   32'h0000_0000;

    assign led = led_r;
    assign hex = hex_r;
endmodule
