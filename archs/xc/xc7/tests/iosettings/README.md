# IO settings tests

A test suite for almost all combinations of IOSTANDARD+DRIVE+SLEW (+IN_TERM) parameters. The script `generate.py` generates designs with either inputs, outputs or inouts of the same IOSTANDARD but with different DRIVE, SLEW, IN_TERM settings.

All "output" designs generate 100Hz square wave on output pins. "Input" designs sample input pins and present their state on LEDs. Finally "inout" designs cycle inout pin state through L,z,H,z (50kHz frequency) while sampling their state during "z" period. The sampled state is presented on LEDs. The generation script support Basys3 and Arty board.
