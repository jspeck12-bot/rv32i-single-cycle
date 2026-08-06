#!/usr/bin/env bash
#=====================================================================
# scripts/find_toolchain.sh -- locate a usable RISC-V GCC
#
# RISC-V toolchains ship under at least six different names depending
# on who built them. This scans for all of them and, for each one it
# finds, actually compiles a test file for rv32i/ilp32 -- because a
# toolchain existing is not the same as it supporting our target.
#
#   ./scripts/find_toolchain.sh
#
# Prints the prefix to use, or tells you nothing works.
#=====================================================================
set -uo pipefail

PREFIXES=(
    riscv32-unknown-elf-      # riscv-gnu-toolchain, 32-bit build
    riscv64-unknown-elf-      # riscv-gnu-toolchain, 64-bit multilib (most common)
    riscv-none-elf-           # xPack GNU RISC-V Embedded GCC (current)
    riscv-none-embed-         # xPack, older naming
    riscv64-elf-              # Homebrew, Arch Linux
    riscv32-elf-
    riscv64-linux-gnu-        # Linux-target GCC; often lacks rv32 multilib
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/probe.c" <<'EOC'
int probe(int a, int b) { return (a << 3) + b; }
EOC

FOUND=()
BROKEN=()

echo "scanning PATH for RISC-V compilers..."
echo

for p in "${PREFIXES[@]}"; do
    if ! command -v "${p}gcc" >/dev/null 2>&1; then
        continue
    fi

    VER=$("${p}gcc" -dumpversion 2>/dev/null || echo "?")
    WHERE=$(command -v "${p}gcc")

    if "${p}gcc" -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles \
                 -c "$TMP/probe.c" -o "$TMP/probe.o" 2>"$TMP/err.txt"; then
        echo "  [OK]     ${p}gcc   (gcc $VER)"
        echo "           $WHERE"
        FOUND+=("$p")
    else
        echo "  [NO RV32] ${p}gcc  (gcc $VER)"
        echo "           $WHERE"
        echo "           $(head -1 "$TMP/err.txt")"
        BROKEN+=("$p")
    fi
    echo
done

if [ ${#FOUND[@]} -gt 0 ]; then
    echo "--------------------------------------------------------------"
    echo "USE THIS:   make CROSS=${FOUND[0]}"
    echo
    echo "Or just run 'make' -- sw/Makefile auto-detects it."
    echo "--------------------------------------------------------------"
    exit 0
fi

echo "--------------------------------------------------------------"
if [ ${#BROKEN[@]} -gt 0 ]; then
    echo "Found a RISC-V compiler, but none support -march=rv32i -mabi=ilp32."
    echo "You likely have a Linux-target or 64-bit-only build."
else
    echo "No RISC-V compiler found on PATH at all."
fi
echo
echo "Install one -- see README section 'Getting a RISC-V toolchain'."
echo "Fastest option on Ubuntu / WSL:"
echo "    sudo apt update && sudo apt install -y gcc-riscv64-unknown-elf"
echo "--------------------------------------------------------------"
exit 1
