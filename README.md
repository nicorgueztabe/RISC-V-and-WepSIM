# Computer Structure: assembly and microcode practices

Two practices from a Computer Structure course, one in RISC-V assembly and one in microcode.

## practica1-riscv

`main.s` is RISC-V (RV32IMF) assembly. It builds the binomial theorem from scratch:

- `factorial` and `Binomial_coef` for integers.
- `Newton_int` computes (a + b)^n for an integer n.
- `Newton_real` does the same for a real exponent, using the generalized binomial coefficient and its own `Ln` and `E` routines (Taylor series), so no library `pow` is needed.
- `Compute_pows` fills an N x N matrix with `Newton_real(a + i, b + j, c)`, and `main` prints it.

It needs a RISC-V simulator with the standard print-float and print-char ecalls (`a7 = 2` and `a7 = 11`). `Newton_int` calls an external `pow` routine that is not included here.

## practica2-wepsim

Microcode for the `ep` processor in [WepSIM](https://github.com/acaldero/wepsim).

- `firmware.mc` defines a 68000-style instruction set: `lea`, `move`, `move.w`, `tst`, `beq`, `jmp`, `bsr`, `rts`, `addi`, `add`, `nop` and `stop`. Each instruction is folded into as few cycles as possible, with the return to fetch merged into the last one. It also contains the fetch and the `in`, `out` and `rdcycle` instructions that came with the base material.
- `eyes.asm` is a program written with those instructions. It animates a pair of pixel-art eyes through the DMA of a memory-mapped display.

The same program in RISC-V takes 7,134 cycles. With this instruction set it takes 4,718, about 34% fewer, mostly because `bsr` and `rts` manage the stack and `lea` loads a 32-bit address in one instruction.
