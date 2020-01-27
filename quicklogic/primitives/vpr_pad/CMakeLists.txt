add_file_target(FILE vpr_ipad.sim.v SCANNER_TYPE verilog)
add_file_target(FILE vpr_opad.sim.v SCANNER_TYPE verilog)

v2x(NAME vpr_ipad SRCS vpr_ipad.sim.v)
v2x(NAME vpr_opad SRCS vpr_opad.sim.v)
