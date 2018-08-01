make_file_target(FILE ntemplate.Nff.sim.v SCANNER_TYPE verilog)

make_file_target(FILE ntemplate.Nff.pb_type.xml)
n_template(NAME Nff.pb_type.xml PREFIXES a;b;c;d SRCS ntemplate.Nff.pb_type.xml)

n_template(NAME Nff.sim.v PREFIXES a;b;c;d SRCS ntemplate.Nff.sim.v)
