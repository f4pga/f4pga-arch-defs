# A test for extrernal global clock inputs (CLOCK pad via GMUX)

This tests consists of two counters clocked by external clock signals which enter the fabric using dedicated clock inputs.

For the Chandalar board LEDs 0 and 1 correspond to bits 23 and 24 of a counter clocked by the CLK0 input while LEDs 2 and 3 correspond to bits 23 and 24 of a counter clocked by the CLK1 input. The CLK0 is available on J6.4 pin and CLK1 on J6.6 pin.
