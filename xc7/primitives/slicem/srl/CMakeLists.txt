add_file_target(FILE srl32.model.xml SCANNER_TYPE xml)
add_file_target(FILE srl32.pb_type.xml SCANNER_TYPE xml)

add_file_target(FILE ntemplate.N_srl.pb_type.xml SCANNER_TYPE xml)

n_template(
  NAME N_srl.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.N_srl.pb_type.xml
)

