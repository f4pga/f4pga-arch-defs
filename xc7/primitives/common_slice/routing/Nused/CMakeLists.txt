add_file_target(FILE ntemplate.Nused.sim.v SCANNER_TYPE verilog)

n_template(NAME Nused.sim.v PREFIXES a;b;c;d SRCS ntemplate.Nused.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )

