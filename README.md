# rv32i-single-cycle

A complete 37-instruction RV32I single-cycle processor in Verilog, synthesized and verified on hardware on a Digilent Basys 3 (Xilinx Artix-7 XC7A35T).

**Status: complete.** Timing closed, hardware bring-up done, demo captured. Tagged `v1.0` with bitstream.

---

## Results

### Post-synthesis utilization (Vivado 2024.2)

| Resource | Used | Available | Utilization |
|---|---|---|---|
| LUT | 1,528 | 20,800 | 7.35% |
| LUTRAM | 560 | 9,600 | 5.83% |
| FF | 88 | 41,600 | 0.21% |
| IO | 46 | 106 | 43.4% |
| BUFG | 2 | 32 | 6.25% |

### Timing

| Metric | Value |
|---|---|
| Constrained period (`cpu_clk`) | 80.000 ns |
| Worst negative slack (setup) | +64.608 ns |
| Critical path | 15.39 ns |
| Implied Fmax | ~65 MHz |
| Failing endpoints | 0 of 5,878 |
| Operating frequency | 12.5 MHz (100 MHz ÷ 8 via BUFG) |

The core is clocked well below its Fmax. The 80 ns constraint was chosen to give margin during bring-up, not because the design required it.

### Verification

| Test | Coverage | Result |
|---|---|---|
| `test.S` ISA test | 34 self-checking cases, 185 cycles | Pass |
| ALU unit test | 16 cases | Pass |
| Yosys lint | Full RTL | 0 inferred latches |
| Hardware demo | `fib(23)` = `0x6FF1` on 7-segment | Confirmed (video in repo) |

---

## Note on tool numbers

Two toolchains report area, and they do not agree. Both figures appear in this repo, so they are labeled explicitly:

- **Yosys** (generic synthesis, used for linting): roughly 1,000 cells and 85 FF. This is a technology-independent estimate, not a mapping to the Artix-7 fabric.
- **Vivado 2024.2** (post-synthesis, XC7A35T): 1,528 LUT and 88 FF. **These are the real numbers** — they reflect actual mapping to 6-input LUTs and the LUTRAM used for the register file and memories.

The gap is expected. Yosys counts abstract gates; Vivado counts what physically lands on the device. Cite the Vivado numbers.

---

## Instruction set

All 37 instructions of the RV32I base integer ISA:

- **Arithmetic/logic (register):** `ADD` `SUB` `SLL` `SLT` `SLTU` `XOR` `SRL` `SRA` `OR` `AND`
- **Arithmetic/logic (immediate):** `ADDI` `SLTI` `SLTIU` `XORI` `ORI` `ANDI` `SLLI` `SRLI` `SRAI`
- **Loads:** `LB` `LH` `LW` `LBU` `LHU`
- **Stores:** `SB` `SH` `SW`
- **Branches:** `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU`
- **Jumps:** `JAL` `JALR`
- **Upper immediate:** `LUI` `AUIPC`

**Not implemented:** `FENCE`, `ECALL`, `EBREAK`, and the Zicsr extension. These are not needed to run compiled C on bare metal without an OS or trap handler.

### Why 37 and not 10

Most tutorial cores implement a 10-instruction subset. That subset cannot run compiled code. Disassembling gcc output for any trivial C program shows `LUI`, `AUIPC`, `JALR`, `BGEU`, `SLLI`, and `SRAI` appearing within the first 20 instructions — stack setup and the calling convention require them before `main` is even reached.

The instruction set was scoped from the requirement backwards: the target was "runs a C program compiled by the standard toolchain," and that requirement dictated 37 instructions.

---

## Architecture

15 RTL files, 956 lines of Verilog.

```
rtl/
  rv32i_defs.vh      opcode, funct3, funct7, and ALU control constants
  riscv_soc.v        top-level SoC: core + imem + dmem + MMIO
  riscv_core.v       datapath and control integration
  controller.v       control unit wrapper
  main_decoder.v     opcode -> control signals
  alu_decoder.v      funct3/funct7 -> ALU operation
  alu.v              arithmetic, logic, shifts, comparisons
  regfile.v          32x32 register file, x0 hardwired to zero
  extend.v           I/S/B/U/J immediate generation
  branch_unit.v      dedicated branch comparator
  lsu.v              load/store alignment, byte enables, sign/zero extension
  imem.v             instruction memory (4 KB, async read)
  dmem.v             data memory (4 KB, async read)
  seg7.v             7-segment display driver
  top_basys3.v       board top level, clock divider, pin mapping
```

### Design decisions

**Asynchronous-read LUT-based memories.** A single-cycle design must fetch an instruction and complete a data access within one clock period. Block RAM on Artix-7 has a registered read, which would force a second cycle. Distributed LUTRAM gives combinational reads at the cost of capacity — each memory is capped at 4 KB. This is the constraint that makes single-cycle possible on this device, and it is the first thing a pipelined version would change.

**Dedicated branch comparator.** Branch conditions are evaluated by a separate unit fed directly from the register file rather than by reusing the ALU's zero flag. Reusing the ALU would serialize the subtract and the branch decision into the same critical path. Separating them costs a small amount of area and buys timing margin.

**LUI through a third ALU-A mux input.** `LUI` needs to produce `0 + immediate`. Rather than adding a special-case path, a third input to the ALU operand-A mux supplies a hardwired zero, and `LUI` reuses the existing adder. One mux input instead of a dedicated datapath.

**Standalone load/store unit.** Byte enables, sub-word alignment, and sign versus zero extension for `LB`/`LH`/`LBU`/`LHU` are handled in one module rather than scattered across the datapath. Keeps the memory interface in a single place.

---

## Software flow

```
sw/
  link.ld            linker script: memory map and section placement
  crt0.S             startup: stack pointer init, jump to main
  main.c             C test program (Fibonacci)
  test.S             34-case self-checking ISA test
  Makefile           build flow with toolchain auto-detect
tools/
  bin2hex.py         ELF/binary -> Verilog $readmemh .mem format
```

Requires the RISC-V GNU toolchain (`riscv32-unknown-elf-gcc`). The Makefile auto-detects common install paths and prefixes.

```
make            # build main.c -> program.mem
make test       # build the ISA test
```

---

## Build and run

### Simulation

```
iverilog -o sim.out -I rtl rtl/*.v tb/tb_riscv_soc.v
vvp sim.out
gtkwave dump.vcd
```

### Lint

```
yosys -p "read_verilog -I rtl rtl/*.v; hierarchy -top riscv_soc; proc; check"
```

### Vivado

1. Create a project targeting **xc7a35tcpg236-1**.
2. Add all files from `rtl/` as design sources.
3. Add `constraints/top_basys3.xdc`.
4. Add the generated `.mem` file as a design source.
5. Run synthesis, implementation, and generate bitstream.

### Prebuilt bitstream

`top_basys3.bit` is included in the `v1.0` release. Program it directly with the Vivado Hardware Manager — no build required.

---

## Two things that cost me time

### `$readmemh` fails silently in Vivado

If the memory initialization file is missing or unreadable, Vivado prints an informational message reading roughly "could not open file, ignoring" and **synthesis completes successfully.** No error, no warning. The ROM is silently zero-filled, the CPU fetches all zeros, and the design does nothing.

The build looked clean. The board did nothing. This was only found by reading the full message log on a run that had already reported success.

Two related traps:

- **Memory files must use the `.mem` extension.** Vivado's Add Sources dialog filters by extension and will not display `.hex` files at all, even though `$readmemh` itself does not care about the name.
- **Never run Vivado inside a cloud-synced folder.** OneDrive locks `.cache` files mid-write and corrupts the project. Use a local path such as `C:\fpga`.

### Scoping the instruction set

Covered above. Working backwards from "must run gcc output" rather than forwards from a tutorial changed the entire scope of the project, and it is the decision I would defend first.

---

## Next

- 5-stage pipeline (IF/ID/EX/MEM/WB) with forwarding and load-use stalls, benchmarked against this 65 MHz single-cycle baseline
- Scan chain insertion and a MISR BIST controller on the existing core

---

## License

MIT. See `LICENSE`.
