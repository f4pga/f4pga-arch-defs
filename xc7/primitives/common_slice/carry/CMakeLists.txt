add_file_target(
  FILE carry.sim.v
  SCANNER_TYPE verilog
  )
add_file_target(
  FILE carry0.sim.v
  SCANNER_TYPE verilog
  )

v2x(
  NAME carry
  SRCS carry.sim.v
)
v2x(
  NAME carry0
  SRCS carry0.sim.v
)
