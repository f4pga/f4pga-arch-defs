add_file_target(FILE adder.sim.v SCANNER_TYPE verilog)
#v2x_test_both(NAME adder TOP_MODULE adder)
v2x(
    NAME adder
    SRCS adder.sim.v
    )
