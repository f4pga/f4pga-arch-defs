add_file_target(FILE adder.sim.v SCANNER_TYPE verilog)
v2x(NAME adder SRCS adder.sim.v TOP_MODULE adder)
v2x_test_generic(NAME adder TYPE pb_type)
v2x_test_generic(NAME adder TYPE model)
