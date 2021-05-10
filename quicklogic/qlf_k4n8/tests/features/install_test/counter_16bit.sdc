create_clock -period 20 clk
set_clock_uncertainty 2.0

set_input_delay -clock clk -max 1.0 [get_ports user_IN_T[0]]
set_input_delay -clock clk -max 0.5 [get_ports user_IN_T[1]]
