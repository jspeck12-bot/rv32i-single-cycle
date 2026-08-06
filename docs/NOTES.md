# Design notes

Working notes kept alongside the RTL. Written for the version of me who has to
explain this design in an interview eighteen months from now.

## Why the critical path is what it is

The single-cycle clock period must cover, in series:

```
PC register clk->Q
  -> instruction ROM (combinational LUT read)
  -> opcode decode
  -> register file read (async)
  -> ALU src mux
  -> ALU (worst case: 32-bit add with carry propagation)
  -> data RAM address decode + async read
  -> load/store lane select and sign extend
  -> writeback mux
  -> register file setup
```

A load is the worst case; it touches every stage. Everything else has slack it
cannot use, which is exactly the argument for pipelining.

## Blocking vs non-blocking, and where each is used

- `<=` in every clocked block: `pc`, `regfile`, `dmem`, MMIO registers.
- `=` in every `always @(*)` block: all muxes and decoders.

Mixing these is the classic way to get a design that simulates correctly and
synthesizes into something else. There is exactly one clocked block per piece
of state in this design, which is the rule that keeps it clean.

## Latch avoidance

Every combinational `always @(*)` assigns all of its outputs on every path.
`main_decoder.v` does this by assigning safe defaults at the top of the block
before the `case`; every other combinational block has a `default` branch.

## The x0 problem

`x0` is handled in two places, and both are needed:

1. Reads: `assign rd1 = (ra1 == 0) ? 0 : rf[ra1];`
2. Writes: `if (we && wa != 0) rf[wa] <= wd;`

The read mux alone is not enough. Without the write guard, `rf[0]` would hold
stale data that the read mux hides — harmless today, but it would surface the
moment the read mux was optimized away or the register file was replaced with
a BRAM macro.

## Why the register file writes on posedge and not negedge

Some single-cycle designs write the register file on the falling edge so that
a read-then-write in the same cycle works. That is unnecessary here: the read
is combinational and happens at the top of the cycle, the write lands at the
end. There is only one edge in the whole CPU, which makes static timing
analysis meaningful.

## Next steps

1. Run the official `riscv-tests` `rv32ui` suite instead of the hand-written
   self-test.
2. Pipeline it: IF / ID / EX / MEM / WB, with a forwarding unit and a load-use
   hazard stall. Compare Fmax and IPC against this baseline.
3. Move the memories to block RAM once the pipeline can absorb a one-cycle
   read latency.
4. Add `Zicsr` plus `mtvec` / `mepc` / `mcause` so traps actually work.
