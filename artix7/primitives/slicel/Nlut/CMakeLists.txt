MAKE_FILE_TARGET(
  FILE ntemplate.Nlut.sim.v
  SCANNER_TYPE verilog
  )

MAKE_FILE_TARGET(
  FILE ntemplate.Nlut.pb_type.xml
  )
N_TEMPLATE(
  NAME Nlut.pb_type.xml
  PREFIXES a;b;c;d
  SRCS ntemplate.Nlut.pb_type.xml
  
  )

N_TEMPLATE(
  NAME Nlut.sim.v
  PREFIXES a;b;c;d
  SRCS ntemplate.Nlut.sim.v
  
  )

