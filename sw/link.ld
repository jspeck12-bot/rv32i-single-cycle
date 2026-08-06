/*=====================================================================
  link.ld -- memory layout for the single-cycle RV32I SoC

  ROM holds .text only. Everything the CPU can write, plus .rodata,
  lives in RAM. That keeps the data port pointed at a single device and
  means the ROM needs only one read port.

  Two separate images come out of this: text.bin -> imem.hex and
  (.rodata + .data) -> dmem.hex. There is no runtime copy loop, because
  the FPGA initialises both memories at configuration time.
=====================================================================*/
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 4K
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);   /* 0x10001000, grows down */

SECTIONS
{
  .text : ALIGN(4)
  {
    KEEP(*(.text.init))          /* crt0 must be first: reset PC is 0 */
    *(.text .text.*)
  } > ROM

  .rodata : ALIGN(4)
  {
    _rodata_start = .;
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
    . = ALIGN(4);
  } > RAM

  .data : ALIGN(4)
  {
    _data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(4);
    _data_end = .;
  } > RAM

  .bss (NOLOAD) : ALIGN(4)
  {
    _bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  _heap_start = .;

  /DISCARD/ :
  {
    *(.comment)
    *(.note*)
    *(.eh_frame*)
    *(.riscv.attributes)
  }
}
