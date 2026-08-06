#=====================================================================
# sw/Makefile -- build the software images for the RV32I SoC
#
#   make toolchain  show which compiler was detected
#   make            build main.c        -> imem.hex, dmem.hex
#   make test       build test.S        -> imem_test.hex, dmem_test.hex
#   make dis        disassembly listing -> prog.lst
#   make clean
#
# You do NOT need a toolchain to synthesize this design -- imem.hex and
# dmem.hex are committed. You need one only to change the software.
#=====================================================================
# Auto-detect the toolchain prefix. RISC-V GCC ships under several
# different names; ../scripts/find_toolchain.sh explains which you have.
# Override explicitly with:  make CROSS=riscv-none-elf-
ifndef CROSS
CROSS := $(shell for p in riscv32-unknown-elf- riscv64-unknown-elf- \
                          riscv-none-elf- riscv-none-embed- \
                          riscv64-elf- riscv32-elf-; do \
             if command -v $${p}gcc >/dev/null 2>&1; then echo $$p; break; fi; \
         done)
endif

ifeq ($(strip $(CROSS)),)
$(warning No RISC-V toolchain found on PATH.)
$(warning Run ../scripts/find_toolchain.sh, or see the README.)
$(warning NOTE: imem.hex and dmem.hex are already committed -- you only)
$(warning need a toolchain if you want to CHANGE the C program.)
endif

CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
PYTHON  ?= python3

# -march=rv32i  : base integer ISA only, no M/A/F/D/C extensions
# -mabi=ilp32   : soft float, 32-bit ints/longs/pointers
# -mno-relax    : keep linker relaxation off so we do not need a gp setup
ARCH    := -march=rv32i -mabi=ilp32 -mno-relax
CFLAGS  := $(ARCH) -O2 -Wall -Wextra -ffreestanding -fno-builtin \
           -fno-tree-loop-distribute-patterns -nostdlib -nostartfiles
LDFLAGS := -T link.ld -Wl,--gc-sections -Wl,-Map=prog.map

IMEM_WORDS := 1024
DMEM_WORDS := 1024

.PHONY: all test dis clean toolchain

toolchain:
	@echo "CROSS  = $(CROSS)"
	@echo "CC     = $(CC)"
	@command -v $(CC) >/dev/null 2>&1 && $(CC) --version | head -1 \
	  || echo "  ^ NOT FOUND on PATH"

all: imem.hex dmem.hex prog.lst

#--------------------------- C application ---------------------------
prog.elf: crt0.S main.c link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) crt0.S main.c -o $@ -lgcc

text.bin: prog.elf
	$(OBJCOPY) -O binary --only-section=.text $< $@

data.bin: prog.elf
	$(OBJCOPY) -O binary --only-section=.rodata --only-section=.data $< $@

imem.hex: text.bin
	$(PYTHON) ../tools/bin2hex.py $< $(IMEM_WORDS) > $@

dmem.hex: data.bin
	$(PYTHON) ../tools/bin2hex.py $< $(DMEM_WORDS) > $@

prog.lst: prog.elf
	$(OBJDUMP) -d -Mnumeric,no-aliases $< > $@

dis: prog.lst
	cat prog.lst

#--------------------------- ISA self-test ---------------------------
test: imem_test.hex dmem_test.hex

test.elf: test.S link.ld
	$(CC) $(ARCH) -nostdlib -nostartfiles -T link.ld test.S -o $@

text_test.bin: test.elf
	$(OBJCOPY) -O binary --only-section=.text $< $@

data_test.bin: test.elf
	$(OBJCOPY) -O binary --only-section=.rodata --only-section=.data $< $@ 2>/dev/null || : > $@

imem_test.hex: text_test.bin
	$(PYTHON) ../tools/bin2hex.py $< $(IMEM_WORDS) > $@

dmem_test.hex: data_test.bin
	$(PYTHON) ../tools/bin2hex.py $< $(DMEM_WORDS) > $@

clean:
	rm -f *.elf *.bin *.hex *.lst *.map
