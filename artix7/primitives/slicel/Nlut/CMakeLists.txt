make_file_target(FILE ntemplate.Nlut.sim.v SCANNER_TYPE verilog)

make_file_target(FILE ntemplate.Nlut.pb_type.xml)
n_template(
  NAME Nlut.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nlut.pb_type.xml
)

n_template(NAME Nlut.sim.v PREFIXES a;b;c;d SRCS ntemplate.Nlut.sim.v)
