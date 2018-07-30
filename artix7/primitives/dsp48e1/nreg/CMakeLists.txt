MAKE_FILE_TARGET(
  FILE reg.sim.v
  SCANNER_TYPE verilog
  )

MAKE_FILE_TARGET(
  FILE nreg.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME nreg
  SRCS nreg.sim.v
  )

V2X(
  NAME reg
  SRCS reg.sim.v
  )

