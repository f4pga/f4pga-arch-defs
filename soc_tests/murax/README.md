# Murax SoC

This test is the
[Murax SoC from VexRiscv](https://github.com/SpinalHDL/VexRiscv#murax-soc)
built from
[revision 373a3fcb909c3df6c03421b21f73f83b44cb5cc6](https://github.com/SpinalHDL/VexRiscv/commit/373a3fcb909c3df6c03421b21f73f83b44cb5cc6)
using `sbt "run-main vexriscv.demo.MuraxWithRamInit"`.

It uses about ~2500 LUTs and ~1500 flipflops meaning it should fit in all of;
 * up3k
 * lm4k
 * up5k
 * lp8k
 * hx8k

## What does this image do?

This test creates an image that will blink LED7, display a counter on
LED5-LED0, and echo characters on the UART. The C code that is running on this
image can be found
[here](https://github.com/SpinalHDL/VexRiscvSocSoftware/blob/master/projects/murax/demo/src/main.c).

## UART baudrate

This image will have an output baudrate of (clock/100).

On hx8k-b-evn, the ref clock is 12 MHz, so the true baudrate will be 120000,
with the closest standard baudrate of 115200 with ~4% error.

On BASYS3, the ref clock is 100 MHz, so the baudrate will be 1000000.

## Run on BASYS3

The target to run this on a BASYS3 board is `murax_basys_prog`.
