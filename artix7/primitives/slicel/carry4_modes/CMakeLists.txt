add_subdirectory(carry4)
add_subdirectory(carry4_split)
MAKE_FILE_TARGET(
  FILE carry4_modes.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME carry4_modes
  SRCS carry4_modes.sim.v
  )

