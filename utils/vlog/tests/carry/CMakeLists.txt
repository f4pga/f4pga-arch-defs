add_subdirectory(cblock)
add_file_target(FILE carry.sim.v SCANNER_TYPE verilog)
v2x_test_both(NAME carry TOP_MODULE carry)
