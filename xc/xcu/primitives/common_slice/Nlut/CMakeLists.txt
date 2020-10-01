add_file_target(FILE lut5.sim.v SCANNER_TYPE verilog)
add_file_target(FILE f6mux.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ntemplate.Nlut.sim.v SCANNER_TYPE verilog)

v2x(
  NAME lut5
  SRCS lut5.sim.v
)

v2x(
  NAME f6mux
  SRCS f6mux.sim.v
)

n_template(NAME xcu_Nlut.sim.v
  PREFIXES a;b;c;d;e;f;g;h
  SRCS ntemplate.Nlut.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )
