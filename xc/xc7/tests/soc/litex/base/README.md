# Linux on LiteX-Vexriscv on Arty - Litex BaseSoC

This test features a Litex design with a Linux capable VexRiscv CPU.
The firmware is compiled into the bitstream and the ROM and SRAM memories are instantiated and initialized on the FPGA.
DDR3 memory is used as the `main_ram`.

## Synthesis+implementation

In order to run one of them enter the specific directory and run `make`.
Once the bitstream is generated and loaded to the board, we should see the test result on the terminal connected to one of the serial ports.

## HDL code generation

The HDL code is generated from [litex-buildenv](https://github.com/timvideos/litex-buildenv)

The buildenv project can also generate all necessary software for running Linux on the system.
Follow the [buildenv's Linux guide](https://github.com/timvideos/litex-buildenv/wiki/Linux) to see how to generate and run the software.
Since this test targets the [Arty A7-35T](https://store.digilentinc.com/arty-a7-artix-7-fpga-development-board-for-makers-and-hobbyists/) board make sure to export the following variables before building the software:

```
export CPU=vexriscv
export CPU_VARIANT=linux
export PLATFORM=arty
export FIRMWARE=linux
```

To create `baselitex_arty100t.v`, copy from `baselitex_arty.v` and then make the following edits:
* *Add* constraint `(* LOC="PLLE2_ADV_X1Y1" *)` to instance `PLLE2_ADV`.
* *Change* constraint `(* LOC="IDELAYCTRL_X1Y0" *)` to `(* LOC="IDELAYCTRL_X1Y1" *)` on instance `IDELAYCTRL`.
