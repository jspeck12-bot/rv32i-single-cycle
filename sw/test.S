#=====================================================================
# test.S -- self-checking ISA test for the single-cycle RV32I core
#
# Each sub-test loads a test number into x28, computes a result, and
# compares it against a known-good value. On a mismatch it jumps to
# 'fail', which parks the test number on the LEDs and the 7-seg.
#
# Pass condition (what sim/tb_riscv_soc.v watches for):
#   store 0x0000002A to 0x10000064
#
# Fail condition:
#   store the failing test number to 0x2000_0000, then spin.
#=====================================================================
    .equ MMIO_LED, 0x20000000
    .equ MMIO_HEX, 0x20000008
    .equ PASS_ADDR, 0x10000064
    .equ PASS_VAL,  0x2A

    .section .text.init, "ax"
    .globl _start
_start:

#---- 1: ADDI -------------------------------------------------------
    li      x28, 1
    addi    x5, x0, 5
    li      x29, 5
    bne     x5, x29, fail

#---- 2: ADD --------------------------------------------------------
    li      x28, 2
    add     x6, x5, x5
    li      x29, 10
    bne     x6, x29, fail

#---- 3: SUB --------------------------------------------------------
    li      x28, 3
    sub     x7, x6, x5
    li      x29, 5
    bne     x7, x29, fail

#---- 4: AND / OR / XOR --------------------------------------------
    li      x28, 4
    li      x5, 0xF0F0
    li      x6, 0xFF00
    and     x7, x5, x6
    li      x29, 0xF000
    bne     x7, x29, fail

    li      x28, 5
    or      x7, x5, x6
    li      x29, 0xFFF0
    bne     x7, x29, fail

    li      x28, 6
    xor     x7, x5, x6
    li      x29, 0x0FF0
    bne     x7, x29, fail

#---- 7: ANDI / ORI / XORI -----------------------------------------
    li      x28, 7
    li      x5, 0x0FF
    andi    x7, x5, 0x00F
    li      x29, 0x00F
    bne     x7, x29, fail

    li      x28, 8
    ori     x7, x0, 0x123
    li      x29, 0x123
    bne     x7, x29, fail

    li      x28, 9
    li      x5, 0x0FF
    xori    x7, x5, 0x0F0
    li      x29, 0x00F
    bne     x7, x29, fail

#---- 10: SLL / SRL / SRA ------------------------------------------
    li      x28, 10
    li      x5, 1
    li      x6, 4
    sll     x7, x5, x6
    li      x29, 16
    bne     x7, x29, fail

    li      x28, 11
    li      x5, 0x80000000
    srl     x7, x5, x6
    li      x29, 0x08000000
    bne     x7, x29, fail

    li      x28, 12
    sra     x7, x5, x6
    li      x29, 0xF8000000
    bne     x7, x29, fail

#---- 13: SLLI / SRLI / SRAI ---------------------------------------
    li      x28, 13
    li      x5, 3
    slli    x7, x5, 8
    li      x29, 0x300
    bne     x7, x29, fail

    li      x28, 14
    li      x5, 0xFFFFFF00
    srli    x7, x5, 8
    li      x29, 0x00FFFFFF
    bne     x7, x29, fail

    li      x28, 15
    srai    x7, x5, 8
    li      x29, 0xFFFFFFFF
    bne     x7, x29, fail

#---- 16: SLT / SLTU / SLTI / SLTIU --------------------------------
    li      x28, 16
    li      x5, -1
    li      x6, 1
    slt     x7, x5, x6              # -1 < 1 signed   -> 1
    li      x29, 1
    bne     x7, x29, fail

    li      x28, 17
    sltu    x7, x5, x6              # 0xFFFFFFFF < 1 unsigned -> 0
    li      x29, 0
    bne     x7, x29, fail

    li      x28, 18
    slti    x7, x5, 0               # -1 < 0 signed   -> 1
    li      x29, 1
    bne     x7, x29, fail

    li      x28, 19
    sltiu   x7, x5, 1               # huge < 1 unsigned -> 0
    li      x29, 0
    bne     x7, x29, fail

#---- 20: LUI -------------------------------------------------------
    li      x28, 20
    lui     x5, 0xABCDE
    li      x29, 0xABCDE000
    bne     x5, x29, fail

#---- 21: AUIPC (relative check: two in a row differ by 4) ---------
    li      x28, 21
    auipc   x5, 0
    auipc   x6, 0
    sub     x7, x6, x5
    li      x29, 4
    bne     x7, x29, fail

#---- 22: SW / LW ---------------------------------------------------
    li      x28, 22
    li      x10, 0x10000000
    li      x5, 0xDEADBEEF
    sw      x5, 0(x10)
    lw      x7, 0(x10)
    bne     x7, x5, fail

#---- 23: SB / LBU / LB --------------------------------------------
    li      x28, 23
    li      x5, 0x000000A5
    sb      x5, 4(x10)
    lbu     x7, 4(x10)
    li      x29, 0xA5
    bne     x7, x29, fail

    li      x28, 24
    lb      x7, 4(x10)              # 0xA5 sign-extends to 0xFFFFFFA5
    li      x29, 0xFFFFFFA5
    bne     x7, x29, fail

#---- 25: byte lanes are independent -------------------------------
    li      x28, 25
    li      x5, 0
    sw      x5, 8(x10)
    li      x5, 0x11
    sb      x5, 9(x10)              # write only lane 1
    lw      x7, 8(x10)
    li      x29, 0x00001100
    bne     x7, x29, fail

#---- 26: SH / LHU / LH --------------------------------------------
    li      x28, 26
    li      x5, 0x0000BEEF
    sh      x5, 12(x10)
    lhu     x7, 12(x10)
    li      x29, 0xBEEF
    bne     x7, x29, fail

    li      x28, 27
    lh      x7, 12(x10)
    li      x29, 0xFFFFBEEF
    bne     x7, x29, fail

    li      x28, 28
    li      x5, 0x00001234
    sh      x5, 14(x10)             # upper half of the same word
    lw      x7, 12(x10)
    li      x29, 0x1234BEEF
    bne     x7, x29, fail

#---- 29: branches, taken and not taken ----------------------------
    li      x28, 29
    li      x5, 7
    li      x6, 7
    beq     x5, x6, b1
    j       fail
b1: bne     x5, x6, fail

    li      x28, 30
    li      x5, -5
    li      x6, 3
    blt     x5, x6, b2              # signed: -5 < 3
    j       fail
b2: bge     x5, x6, fail            # signed: -5 >= 3 is false

    li      x28, 31
    bltu    x6, x5, b3              # unsigned: 3 < huge
    j       fail
b3: bgeu    x6, x5, fail

#---- 32: JAL writes the return address ----------------------------
    li      x28, 32
    li      x11, 0
    jal     x1, sub_a               # x1 = address of the next instr
    li      x29, 1
    bne     x11, x29, fail          # sub_a must have run

#---- 33: JALR returns ---------------------------------------------
    li      x28, 33
    li      x11, 0
    jal     x1, sub_b               # sub_b returns via jalr x0,0(x1)
    li      x29, 2
    bne     x11, x29, fail

#---- 34: x0 is immutable ------------------------------------------
    li      x28, 34
    addi    x0, x0, 99
    bne     x0, x0, fail
    li      x29, 0
    bne     x0, x29, fail

#---- all green -----------------------------------------------------
pass:
    li      x10, PASS_ADDR
    li      x11, PASS_VAL
    sw      x11, 0(x10)             # <-- testbench watches for this
    li      x10, MMIO_LED
    li      x11, 0x00FF
    sw      x11, 0(x10)
1:  j       1b

fail:
    li      x10, MMIO_LED
    sw      x28, 0(x10)             # failing test number on the LEDs
    li      x10, MMIO_HEX
    sw      x28, 0(x10)
1:  j       1b

#---- helper subroutines -------------------------------------------
sub_a:
    li      x11, 1
    jalr    x0, 0(x1)

sub_b:
    li      x11, 2
    jalr    x0, 0(x1)
