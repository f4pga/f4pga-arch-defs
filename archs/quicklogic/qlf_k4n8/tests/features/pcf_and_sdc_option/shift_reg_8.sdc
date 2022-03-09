create_clock -period 15.0 clk -waveform {0.000 5.000}
set_clock_uncertainty 2.0

set_input_delay -clock clk -max 1 [get_ports user_IN_T[0]]
set_input_delay -clock clk -max 1 [get_ports clr]
