# Computer Structure: assembly and microcode practices

Two practices from a Computer Structure course, one in RISC-V assembly and one in microcode.

## practica1-riscv

`main.s` is RISC-V (RV32IMF) assembly. It builds the binomial theorem from scratch:

- `factorial` and `Binomial_coef` for integers.
- `Newton_int` computes (a + b)^n for an integer n.
- `Newton_real` does the same for a real exponent, using the generalized binomial coefficient and its own `Ln` and `E` routines (Taylor series), so no library `pow` is needed.
- `Compute_pows` fills an N x N matrix with `Newton_real(a + i, b + j, c)`, and `main` prints it.

It needs a RISC-V simulator with the standard print-float and print-char ecalls (`a7 = 2` and `a7 = 11`). `Newton_int` calls an external `pow` routine that is not included here.

Example output with N = 3, a = 1.5, b = 0.5 and c = 2.5:

```
5.65687 15.597558 32.16165
15.58846 32.001743 55.934334
31.99999 55.902264 88.19266
```

Entry (i, j) approximates (a + i + b + j)^c, so the top-left value is 2^2.5 = 5.657. `Newton_real` sums 6 terms of the series, which keeps the single-precision values from overflowing but drifts from the exact power when b is larger than a (the top-right entry is 32.16 instead of 32).

## practica2-wepsim

Microcode for the `ep` processor in [WepSIM](https://github.com/acaldero/wepsim).

- `firmware.mc` defines a 68000-style instruction set: `lea`, `move`, `move.w`, `tst`, `beq`, `jmp`, `bsr`, `rts`, `addi`, `add`, `nop` and `stop`. Each instruction is folded into as few cycles as possible, with the return to fetch merged into the last one. It also contains the fetch and the `in`, `out` and `rdcycle` instructions that came with the base material.
- `eyes.asm` is a program written with those instructions. It animates a pair of pixel-art eyes through the DMA of a memory-mapped display.

`main` sends nine frames to the display: open, then closed, open, right, open, left, open, closed and open again (nine calls to `show_eyes`, each followed by a short delay loop). These are the four bitmaps it uses, each 24 pixels wide, with the empty rows left out:

```
open (m1)
........................
.......####...####......
.......####...####......
.......####...####......
.......####...####......

closed (m2)
........................
........................
.......####....####.....
........................
........................

looking right (m3r)
................#####...
................#####...
..........###...#####...
..........###...#####...
........................

looking left (m3l)
......#####.............
......#####...###.......
......#####...###.......
......#####...###.......
........................
```

The same program written in RISC-V takes more cycles. Cycle counts, measured with `rdcycle`:

| | RISC-V | This instruction set |
|---|---|---|
| `show_eyes` | 757 | 508 |
| whole `main` | 7,134 | 4,718 |

That is about 34% fewer cycles for `main`, mostly because `bsr` and `rts` manage the stack and `lea` loads a 32-bit address in one instruction.

