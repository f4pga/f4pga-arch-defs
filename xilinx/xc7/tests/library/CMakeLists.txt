add_subdirectory(uart)

add_file_target(FILE lfsr.v SCANNER_TYPE verilog)
add_file_target(FILE tbassert.v SCANNER_TYPE verilog)
