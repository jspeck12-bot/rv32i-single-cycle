#!/usr/bin/env bash
#=====================================================================
# scripts/lint_yosys.sh -- pre-synthesis sanity check with Yosys
#
# Catches the classes of bug that simulate fine and synthesize wrong:
#   - inferred latches from an incomplete combinational block
#   - unconnected or driverless nets
#   - constructs that are not synthesizable at all
#
# Runs in seconds. Use it before every Vivado run, not instead of one.
#
#   ./scripts/lint_yosys.sh
#=====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/lint"
mkdir -p "$WORK"

# $readmemh resolves relative to the working directory
if [ -f "$ROOT/sw/imem.hex" ]; then cp "$ROOT/sw/imem.hex" "$WORK/"; fi
if [ -f "$ROOT/sw/dmem.hex" ]; then cp "$ROOT/sw/dmem.hex" "$WORK/"; fi
cd "$WORK"

CORE_SRC=$(ls "$ROOT"/rtl/*.v | grep -v top_basys3 | grep -v seg7 | tr '\n' ' ')

echo "== 1/3  structural check (hierarchy, drivers, connectivity) =="
yosys -q -p "
  read_verilog -I $ROOT/rtl $CORE_SRC
  hierarchy -check -top riscv_soc
  proc
  opt
  check -assert
"
echo "   ok"

echo
echo "== 2/3  latch check (must report 0 objects) =="
LATCHES=$(yosys -p "
  read_verilog -I $ROOT/rtl $CORE_SRC
  hierarchy -top riscv_soc
  proc
  opt
  select -count t:\$dlatch t:\$_DLATCH_*
" 2>&1 | grep -oP '^\d+(?= objects)' | tail -1)

echo "   inferred latches: ${LATCHES:-unknown}"
if [ "${LATCHES:-1}" != "0" ]; then
    echo "   FAIL: a combinational always block is missing an assignment path."
    exit 1
fi

echo
echo "== 3/3  Artix-7 technology mapping + resource estimate =="
yosys -q -p "
  read_verilog -I $ROOT/rtl $ROOT/rtl/*.v
  synth_xilinx -family xc7 -top top_basys3
  stat
" -l xilinx_map.log

# The last stat block in the log is the whole-design total.
awk '/=== design hierarchy ===/{f=1} f' xilinx_map.log |
    sed -n '/Number of cells:/,/^$/p' |
    sed 's/^/   /'

cat <<'EON'

   XC7A35T budget:  20800 LUT   41600 FF   9600 LUTRAM   50 BRAM36
EON

echo
echo "lint passed -- see $WORK/xilinx_map.log"
echo "NOTE: this is a mapping estimate, NOT timing closure."
echo "      Only Vivado can tell you your WNS. Run scripts/build_vivado.tcl."
