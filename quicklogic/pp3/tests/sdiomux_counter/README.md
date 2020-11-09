# A 24-bit counter with LED output

This design implements a 24-bit counter driven by the `Sys_Clk0` clock signal from the SoC. The design instantiates the `qlal4s3b_cell_macro` cell access SoC signal(s).

The value of the MSBs of the counter is exposed to `FBIO_18` which corresponds to LED6 on the Chandalar board. The other bits are exposed to `SFBIO_10`, `SFBIO_9` and `SFBIO_8`.
