add_file_target(FILE dsp_combinational.sim.v SCANNER_TYPE verilog)
v2x(NAME dsp_combinational SRCS dsp_combinational.sim.v TOP_MODULE dsp_combinational)
v2x_test_generic(NAME dsp_combinational TYPE pb_type)
v2x_test_generic(NAME dsp_combinational TYPE model)
