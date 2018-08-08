add_file_target(FILE ntemplate.Nused.sim.v SCANNER_TYPE verilog)

add_file_target(FILE ntemplate.Nused.model.xml)

add_file_target(FILE ntemplate.Nused.pb_type.xml)
n_template(NAME Nused.model.xml PREFIXES a;b;c;d SRCS ntemplate.Nused.model.xml)

n_template(NAME Nused.sim.v PREFIXES a;b;c;d SRCS ntemplate.Nused.sim.v)

n_template(
  NAME Nused.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nused.pb_type.xml
)
