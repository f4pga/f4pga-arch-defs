add_file_target(
  FILE carry4_vpr.sim.v
  SCANNER_TYPE verilog
  )

# TODO - Switch to use V2X once FASM parameter support exists.
#v2x(
#  NAME carry4_vpr
#  SRCS carry4_vpr.sim.v
#)
add_file_target(FILE carry4_vpr.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE carry4_vpr.model.xml SCANNER_TYPE xml)

