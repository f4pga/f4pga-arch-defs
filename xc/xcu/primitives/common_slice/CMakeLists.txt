add_subdirectory(muxes)
add_subdirectory(routing)
add_subdirectory(Nlut)

add_file_target(FILE common_slice.sim.v SCANNER_TYPE verilog)

v2x(
    NAME common_slice
    SRCS common_slice.sim.v
)
