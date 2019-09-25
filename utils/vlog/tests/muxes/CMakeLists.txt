add_subdirectory(routing)
add_file_target(FILE use_mux.sim.v SCANNER_TYPE verilog)
v2x_test_both(NAME use_mux TOP_MODULE USE_MUX TECHMAPS routing/rmux.techmap.v)
