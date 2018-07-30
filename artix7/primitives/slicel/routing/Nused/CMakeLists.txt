MAKE_FILE_TARGET(
  FILE ntemplate.Nused.sim.v
  SCANNER_TYPE verilog
  )

MAKE_FILE_TARGET(
  FILE ntemplate.Nused.model.xml
  )

MAKE_FILE_TARGET(
  FILE ntemplate.Nused.pb_type.xml
  )
N_TEMPLATE(
  NAME Nused.model.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nused.model.xml
  
  )

N_TEMPLATE(
  NAME Nused.sim.v
  PREFIXES a;b;c;d
  SRCS ntemplate.Nused.sim.v
  
  )

N_TEMPLATE(
  NAME Nused.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nused.pb_type.xml
  
  )

