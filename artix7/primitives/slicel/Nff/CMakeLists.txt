MAKE_FILE_TARGET(
  FILE ntemplate.Nff.sim.v
  SCANNER_TYPE verilog
  )

MAKE_FILE_TARGET(
  FILE ntemplate.Nff.pb_type.xml
  )
N_TEMPLATE(
  NAME Nff.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nff.pb_type.xml
  
  )

N_TEMPLATE(
  NAME Nff.sim.v
  PREFIXES a;b;c;d
  SRCS ntemplate.Nff.sim.v
  
  )

