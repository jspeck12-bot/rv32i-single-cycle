#!/usr/bin/env bash
#=====================================================================
# scripts/publish.sh -- one-shot first push to GitHub
#
#   ./scripts/publish.sh <your-github-username>
#
# What it does:
#   1. verifies git identity is configured
#   2. git init, stage, and show you exactly what will be committed
#   3. commit with a real message
#   4. add the remote and push to main
#
# What it does NOT do: create the repo, or handle your credentials.
# Create the empty repo on github.com first (Public, NO README, NO
# .gitignore, NO license). Git will prompt you for auth on push.
#=====================================================================
set -euo pipefail

USER="${1:-}"
REPO="rv32i-single-cycle"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -z "$USER" ]; then
    echo "usage: ./scripts/publish.sh <your-github-username>"
    exit 1
fi

#---------------------------- identity -------------------------------
if ! git config --get user.email >/dev/null; then
    echo "ERROR: git identity not set. Run:"
    echo "  git config --global user.name  \"Joshua Speck\""
    echo "  git config --global user.email \"your.github@email.com\""
    echo "The email must match your GitHub account or commits will not"
    echo "attribute to your profile."
    exit 1
fi
echo "committing as: $(git config --get user.name) <$(git config --get user.email)>"

#------------------------------ init ---------------------------------
if [ ! -d .git ]; then
    git init -q
    git branch -M main
fi

git add -A

echo
echo "== files staged for the first commit =="
git diff --cached --name-only
echo
echo "== sanity check: none of these should appear above =="
echo "   *.bit  *.elf  *.bin  build/  .Xil/  *.jou  *.log  *.xpr"
echo
read -r -p "Look right? Commit and push? [y/N] " ans
case "$ans" in [yY]*) ;; *) echo "aborted, nothing pushed."; exit 0 ;; esac

#----------------------------- commit --------------------------------
git commit -q -m "Single-cycle RV32I core: full base ISA, verified in simulation

- 37-instruction RV32I base integer ISA (no FENCE/ECALL/EBREAK/Zicsr)
- Dedicated branch comparator; byte-enabled load/store alignment unit
- Self-checking testbenches: 16-case ALU test, 34-case ISA test
- Executes C compiled with RISC-V GCC (-march=rv32i -mabi=ilp32)
- Yosys lint: zero inferred latches, maps cleanly to Artix-7
- Basys 3 wrapper with a constrained 12.5 MHz generated clock"

#------------------------------ push ---------------------------------
if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/$USER/$REPO.git"
fi

echo
echo "pushing to https://github.com/$USER/$REPO ..."
git push -u origin main

cat <<EOS

--------------------------------------------------------------------
pushed.

DO NOT TAG v1.0 YET. The tag means "runs on hardware." Tag it only
after Vivado closes timing and the bitstream runs on the board:

    git tag -a v1.0 -m "v1.0 - runs gcc-compiled C on Basys 3 hardware"
    git push origin v1.0

Then set the repo description and topics on GitHub:
  riscv  verilog  fpga  cpu  computer-architecture  basys3  rtl  vivado
--------------------------------------------------------------------
EOS
