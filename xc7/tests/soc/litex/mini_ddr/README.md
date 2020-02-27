# MiniLitex with DDR - Litex BaseSoC

This test features a Mini Litex design with a VexRiscv CPU in the lite variant with a DDR controler.
The firmware is compiled into the bitstream and the ROM and SRAM memories are instantiated and initialized on the FPGA.
Additionaly a memory test of the DRAM memory is performed.

## Synthesis+implementation

In order to run one of them enter the specific directory and run `make`.
Once the bitstream is generated and loaded to the board, we should see the test result on the terminal connected to one of the serial ports.

## HDL code generation

The following instructions are for generation of the HDL code

## 1. Install Litex

* Create an empty directory and clone there the following repos. Be sure to checkout the specific SHA given.

    | Repo URL | SHA |
    |    ---   | --- |
    | <https://github.com/antmicro/litex>         | 60f2853e |
    | <https://github.com/enjoy-digital/litedram> | 7fbe0b7  |
    | <https://github.com/enjoy-digital/liteeth>  | f2b3f7e  |
    | <https://github.com/m-labs/migen>           | 8d0e740  |

* If you do not want to install LiteX and Migen in your system, setup the Python virtualenv and activate it in the following way:

```
virtualenv litex-env
source litex-env/bin/activate
```

* Install LiteX and Migen packages from the previously cloned repos.

    Run the following command in each repo subdirectory:

```
./setup.py develop
```

## 2. Generate gateware

Run `./scripts/min_ddr_arty.py --no-compile-software --no-compile-gateware`

The top netlist (top.v) will be placed in the `soc_minsoc_arty/gateware` directory.
