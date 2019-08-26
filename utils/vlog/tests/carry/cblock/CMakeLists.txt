add_file_target(FILE cblock.sim.v SCANNER_TYPE verilog)
v2x(NAME cblock SRCS cblock.sim.v TOP_MODULE cblock)
v2x_test_generic(NAME cblock TYPE pb_type)
v2x_test_generic(NAME cblock TYPE model)
