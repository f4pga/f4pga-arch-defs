# Zephyr on Arty - Litex BaseSoC

This test features a Litex design with Zephyr capable VexRiscv CPU.
The firmware is compiled into the bitstream and the ROM and SRAM memories are instantiated and initialized on the FPGA.
Additional memory (`main_ram`) is instantiated using block rams. Zephyr runs from this memory.

## Synthesis+implementation

In order to run one of them enter the specific directory and run `make`.
Once the bitstream is generated and loaded to the board, we should see the test result on the terminal connected to one of the serial ports.

## HDL code generation

The HDL code is generated from [litex-buildenv](https://github.com/timvideos/litex-buildenv/pull/338)

The buildenv project can also generate Zephyr software for the system.
Follow the [buildenv's Zephyr guide](https://github.com/timvideos/litex-buildenv/wiki/Zephyr) to get the Zephyr software.
The memory pool available in the system may be insufficient for the default Zephyr application built with the buildenv.
To change the application set the `ZEPHYR_APP` env variable before building the app:

```
export ZEPHYR_APP=philosophers
```

