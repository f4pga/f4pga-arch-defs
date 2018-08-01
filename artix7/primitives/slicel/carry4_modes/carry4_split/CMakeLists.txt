add_subdirectory(carry4_Nmux)
add_subdirectory(carry4_Nxor)
make_file_target(FILE carry4_split.sim.v SCANNER_TYPE verilog)
v2x(NAME carry4_split SRCS carry4_split.sim.v)
