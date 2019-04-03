add_file_target(
  FILE carry.sim.v
  SCANNER_TYPE verilog
  )

v2x(
  NAME carry
  SRCS carry.sim.v
)

add_file_target(
  FILE carry0.pb_type.xml
  SCANNER_TYPE xml
  )
add_file_target(
  FILE carry0.model.xml
  SCANNER_TYPE xml
  )
