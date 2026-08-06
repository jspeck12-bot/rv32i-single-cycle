#!/usr/bin/env python3
"""
bin2hex.py -- flat binary  ->  $readmemh word list

Verilog's $readmemh wants one hex value per memory location. RISC-V is
little-endian, so byte 0 of the file is the LEAST significant byte of
word 0.

usage:  bin2hex.py <input.bin> [max_words] > out.hex
"""
import sys


def main():
    if len(sys.argv) < 2:
        sys.stderr.write("usage: bin2hex.py <input.bin> [max_words]\n")
        return 2

    path = sys.argv[1]
    max_words = int(sys.argv[2]) if len(sys.argv) > 2 else 0

    with open(path, "rb") as f:
        data = f.read()

    # pad up to a word boundary
    if len(data) % 4:
        data += b"\x00" * (4 - (len(data) % 4))

    n_words = len(data) // 4

    if max_words and n_words > max_words:
        sys.stderr.write(
            "ERROR: %s is %d words but the memory holds %d.\n"
            "       Shrink the program or grow AW in the memory module.\n"
            % (path, n_words, max_words)
        )
        return 1

    lines = []
    for i in range(n_words):
        word = int.from_bytes(data[4 * i:4 * i + 4], "little")
        lines.append("%08x" % word)

    # Pad out to the full memory depth. Every simulator and Vivado warn
    # when $readmemh runs out of data before the end of the array, so we
    # fill the tail with zeros and keep the logs clean.
    if max_words:
        lines += ["00000000"] * (max_words - len(lines))

    if not lines:
        lines = ["00000000"]

    sys.stdout.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
