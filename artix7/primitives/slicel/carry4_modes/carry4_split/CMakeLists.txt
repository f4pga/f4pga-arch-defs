add_subdirectory(carry4_Nmux)
add_subdirectory(carry4_Nxor)
MAKE_FILE_TARGET(
  FILE carry4_split.sim.v
  SCANNER_TYPE verilog
  )
V2X(
  NAME carry4_split
  SRCS carry4_split.sim.v
  )

