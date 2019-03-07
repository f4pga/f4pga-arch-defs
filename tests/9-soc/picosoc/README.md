# PicoSoC

This test is the
[PicoSoC](https://github.com/cliffordwolf/picorv32/tree/master/picosoc)
built from
[revision 9b6ea045f9b539b0f708d71962716e5dde865181](https://github.com/cliffordwolf/picorv32/commit/9b6ea045f9b539b0f708d71962716e5dde865181)

It has been modified so it does not require external SPI flash. Instead, the program is stored in ROM which is intended to be implemented as distributed ram (not BRAM).

The ROM content is stored in `progmem.v` file. The file is generated from `progmem.v.template` using the `hex2progmem.py` Python script.

**! WARNING !** This version of PicoRV32 does not work with compressed instruction set! Make sure to set up proper architecture when building the firmware.

ROM generation procedure:

 - Compile your firmware using the RISC-V toolchain (just run `make` in the `firmware` subdir).
 - Convert ELF to HEX using: `objdump -O verilog`
 - Run the `hex2progmem.py` script and give it the HEX file as the first argument.

Now the `progmem.v` is re-generated with the new firmware code.
