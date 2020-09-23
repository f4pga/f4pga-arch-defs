add_file_target(FILE ntemplate.Nlut.sim.v SCANNER_TYPE verilog)

n_template(NAME xcu_Nlut.sim.v
  PREFIXES a;b;c;d;e;f;g;h
  SRCS ntemplate.Nlut.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )
