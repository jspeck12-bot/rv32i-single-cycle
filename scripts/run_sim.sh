#!/usr/bin/env bash
#=====================================================================
# scripts/run_sim.sh -- build the software, then run every testbench
#
#   ./scripts/run_sim.sh
#
# Requires: iverilog, python3, and a RISC-V GCC. The toolchain prefix is
# auto-detected; run ./scripts/find_toolchain.sh if it cannot find one.
#=====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Leave CROSS unset unless the caller set it -- sw/Makefile auto-detects
# the toolchain prefix. Override with: CROSS=riscv-none-elf- ./run_sim.sh
MAKE_ARGS=()
if [ -n "${CROSS:-}" ]; then MAKE_ARGS+=("CROSS=$CROSS"); fi

RTL=(
  "$ROOT/rtl/alu.v"
  "$ROOT/rtl/alu_decoder.v"
  "$ROOT/rtl/branch_unit.v"
  "$ROOT/rtl/controller.v"
  "$ROOT/rtl/dmem.v"
  "$ROOT/rtl/extend.v"
  "$ROOT/rtl/imem.v"
  "$ROOT/rtl/lsu.v"
  "$ROOT/rtl/main_decoder.v"
  "$ROOT/rtl/regfile.v"
  "$ROOT/rtl/riscv_core.v"
  "$ROOT/rtl/riscv_soc.v"
)

echo "== building software =="
make -C "$ROOT/sw" toolchain
make -C "$ROOT/sw" "${MAKE_ARGS[@]}" all test

WORK="$ROOT/sim/work"
mkdir -p "$WORK"
cp "$ROOT/sw"/*.hex "$WORK/"
cd "$WORK"

echo
echo "== ALU unit test =="
iverilog -g2012 -I "$ROOT/rtl" -o tb_alu.out -s tb_alu \
    "$ROOT/rtl/alu.v" "$ROOT/sim/tb_alu.v"
vvp tb_alu.out

echo "== ISA self-test (test.S) =="
iverilog -g2012 -I "$ROOT/rtl" -o tb_soc.out -s tb_riscv_soc \
    "${RTL[@]}" "$ROOT/sim/tb_riscv_soc.v"
vvp tb_soc.out

echo "== gcc-compiled C program (main.c) =="
iverilog -g2012 -I "$ROOT/rtl" -o tb_prog.out -s tb_riscv_soc_prog \
    "${RTL[@]}" "$ROOT/sim/tb_riscv_soc_prog.v"
vvp tb_prog.out

echo
echo "all testbenches passed"
