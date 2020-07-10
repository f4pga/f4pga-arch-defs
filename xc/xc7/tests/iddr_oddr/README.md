# IDDR/ODDR test

These tests are meant to check correct support for IDDR and ODDR primitives as well as their operation in real hardware.

## The hardware test

1. Build the test named `ioddr_hw_test_basys3` and upload the bitstream to a Basys3 board
2. Make wire loop connections on JC connector so that pins 1,7 2,8 3,9 and 4,10 are shorted.

LED7 should blink continuously indicating that the bitstream is working.

LEDs 0 to 3 indicate error in data transmission. They all should remain off while the shorting wires are connected.

