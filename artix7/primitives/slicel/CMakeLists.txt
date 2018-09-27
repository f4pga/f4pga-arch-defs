add_subdirectory(muxes)
add_subdirectory(Nlut)
add_subdirectory(carry)
add_subdirectory(routing)

add_file_target(
  FILE cyinit_constants.sim.v
  SCANNER_TYPE verilog
  )
v2x(
  NAME cyinit_constants
  SRCS cyinit_constants.sim.v
  )

add_file_target(
  FILE cyinit_fabric.sim.v
  SCANNER_TYPE verilog
  )

v2x(
  NAME cyinit_fabric
  SRCS cyinit_fabric.sim.v
)

add_file_target(FILE slicel.model.xml SCANNER_TYPE xml)
add_file_target(FILE slicel.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE slicel.sim.v SCANNER_TYPE verilog)
add_verilog_image_gen(FILE slicel.sim.v)
