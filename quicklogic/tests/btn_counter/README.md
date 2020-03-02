# A button-clocked 4-bit counter

This design implements a 4-bit counter driven by a clock input exposed at the `FBIO_0` pad. You need to connect a button to this pin or provide a clock signal from an external clock source. Couter value is exposed to `FBIO_21`, `FBIO_22`, `FBIO_26` and `FBIO_18` which correspond to LEDs 2, 4, 5 and 6 on the Chandalar board (for the "btn_counter-ql-chandalar" target). 

The "btn_counter-ql-chandalar-top" target uses only the topmost fragment of the FPGA grid hence it exposes the counter state on different pads which are `FBIO_9`, `FBIO_6`, `FBIO_8` and `FBIO_10`.
