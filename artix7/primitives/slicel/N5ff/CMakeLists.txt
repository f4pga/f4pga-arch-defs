MAKE_FILE_TARGET(
  FILE ntemplate.N5ff.model.xml
  )

MAKE_FILE_TARGET(
  FILE ntemplate.N5ff.sim.v
  SCANNER_TYPE verilog
  )

MAKE_FILE_TARGET(
  FILE ntemplate.N5ff.pb_type.xml
  )
N_TEMPLATE(
  NAME N5ff.model.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.N5ff.model.xml
  
  )

N_TEMPLATE(
  NAME N5ff.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.N5ff.pb_type.xml
  
  )

N_TEMPLATE(
  NAME N5ff.sim.v
  PREFIXES a;b;c;d
  SRCS ntemplate.N5ff.sim.v
  
  )

