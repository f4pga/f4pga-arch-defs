# PicoSoC

This test is the
[PicoSoC](https://github.com/cliffordwolf/picorv32/tree/master/picosoc)
built from
[revision 9b6ea045f9b539b0f708d71962716e5dde865181](https://github.com/cliffordwolf/picorv32/commit/9b6ea045f9b539b0f708d71962716e5dde865181)

It has been modified so it does not require external SPI flash. Instead, the program is stored in ROM which is implemented in the FPGA.

The ROM content is stored in `progmem.v` file. The file is generated from using the `hex2progmem.py` Python script from a HEX file.

**! WARNING !** This version of PicoRV32 does not work with compressed instruction set! Make sure to set up proper architecture when building the firmware.

#### Expected output

The current firmware produces the following output on the basys3 platform. You should experience similar behavior of LEDs and identical serial output on other boards.

 - First four leds (LD0, LD1, LD2, LD3) blinking at a regular rate from left to right.
 - An UART output looking as follows (baud rate must be set to 115200):

```
Terminal ready
Press ENTER to continue..
Press ENTER to continue..
Press ENTER to continue..
Press ENTER to continue..

 ____  _          ____         ____
|  _ \(_) ___ ___/ ___|  ___  / ___|
| |_) | |/ __/ _ \___ \ / _ \| |
|  __/| | (_| (_) |__) | (_) | |___
|_|   |_|\___\___/____/ \___/ \____|


  [9] Run simplistic benchmark

Command>
```
