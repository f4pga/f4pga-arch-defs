# Dual 24-bit counters with LED output

This design implements two 24-bit counters driven by the `Sys_Clk0` and `Sys_Clk1` clock signals from the SoC. The design instantiates the `qlal4s3b_cell_macro` cell access SoC signal(s). Both counters are also reset (syncrhonously) by `Sys_Clk0_Rst` and `Sys_Clk1_Rst` signals respectively.

The value of the first counter is exposed to `FBIO_21`, `FBIO_22` and the value of the second one is exposed to `FBIO_26` and `FBIO_18` which correspond to LEDs 2, 4, 5 and 6 on the Chandalar board. Only two MSBs are exposed due to the limited LED count.