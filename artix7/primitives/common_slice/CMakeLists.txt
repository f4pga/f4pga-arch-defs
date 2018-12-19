add_subdirectory(muxes)
add_subdirectory(Nlut)
add_subdirectory(carry)
add_subdirectory(routing)

add_file_target(FILE common_lut_and_f78mux.model.xml SCANNER_TYPE xml)
add_file_target(FILE common_lut_and_f78mux.pb_type.xml SCANNER_TYPE xml)

add_file_target(FILE common_slice.model.xml SCANNER_TYPE xml)
add_file_target(FILE common_slice.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE common_slice.sim.v SCANNER_TYPE verilog)
