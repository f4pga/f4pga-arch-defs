# A 24-bit counter with LED output

This design implements a 24-bit counter driven by the `Clk16` clock signal from the SoC. The design instantiates the `qlal4s3b_cell_macro` cell access SoC signal(s).

The value of 4 MSBs of the counter is exposed to `FBIO_21`, `FBIO_22`, `FBIO_26` and `FBIO_18` which correspond to LEDs 2, 4, 5 and 6 on the Chandalar board.