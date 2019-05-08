add_file_target(FILE ntemplate.N5lut.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ntemplate.Nlut.sim.v SCANNER_TYPE verilog)

n_template(NAME N5lut.sim.v PREFIXES a;b;c;d SRCS ntemplate.N5lut.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )

n_template(NAME Nlut.sim.v PREFIXES a;b;c;d SRCS ntemplate.Nlut.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )

