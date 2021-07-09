# A button-clocked 4-bit counter

This design implements a 4-bit counter driven by a clock input exposed at the `FBIO_0` pad. You need to connect a button to this pin or provide a clock signal from an external clock source. Couter value is exposed to `FBIO_21`, `FBIO_22`, `FBIO_26` and `FBIO_18` which correspond to LEDs 2, 4, 5 and 6 on the Chandalar board (for the "btn_counter-ql-chandalar" target). 

