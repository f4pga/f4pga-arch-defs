add_file_target(FILE lut4.sim.v SCANNER_TYPE verilog)
v2x(NAME lut4 SRCS lut4.sim.v TOP_MODULE lut4)
v2x_test_generic(NAME lut4 TYPE pb_type)
v2x_test_generic(NAME lut4 TYPE model)
