add_file_target(FILE reg.sim.v SCANNER_TYPE verilog)
v2x(NAME reg SRCS reg.sim.v)
add_file_target(FILE nreg.sim.v SCANNER_TYPE verilog)
v2x(NAME nreg SRCS nreg.sim.v)
