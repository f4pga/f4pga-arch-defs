add_file_target(FILE ntemplate.Nlut.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ntemplate.Nlut.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.Nlut.model.xml SCANNER_TYPE xml)

n_template(NAME Nlut.sim.v
  PREFIXES a;b;c;d;e;f;g;h
  SRCS ntemplate.Nlut.sim.v
  APPLY_VERILOG_IMAGE_GEN
  APPLY_V2X
  )
