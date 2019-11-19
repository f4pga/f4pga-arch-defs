# I2C scan test

This is a test that employes I2C scan. It uses two IOBUFs to implement the
I2C bus.

The test design repeatively scans I2C addresses from 0x04 to 0x78. Scans are
performed in 1s intervals. The I2C frequency is set to 100kHz.

Scan results are reported through the UART interface. A single line represents
one address. For example:

10 0
11 1

Means that for the address 0x10 there was no response and for the address 0x11
something acknowledged.

The switch SW0 is the design reset and the switch SW1 enables / disables the
scan.

