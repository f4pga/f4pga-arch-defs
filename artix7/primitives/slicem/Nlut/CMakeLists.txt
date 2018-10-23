add_file_target(FILE ntemplate.Nlut.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.Nlut.model.xml SCANNER_TYPE xml)

n_template(
  NAME Nlut_slicem.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nlut.pb_type.xml
)

n_template(
  NAME Nlut_slicem.model.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nlut.model.xml
  )
