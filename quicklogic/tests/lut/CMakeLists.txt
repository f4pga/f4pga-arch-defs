add_file_target(FILE lut1.v SCANNER_TYPE verilog)
add_file_target(FILE lut2.v SCANNER_TYPE verilog)
add_file_target(FILE lut3.v SCANNER_TYPE verilog)
add_file_target(FILE lut4.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME lut1-ql-testboard
  BOARD ql-testboard
  SOURCES lut1.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut2-ql-testboard
  BOARD ql-testboard
  SOURCES lut2.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut3-ql-testboard
  BOARD ql-testboard
  SOURCES lut3.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut4-ql-testboard
  BOARD ql-testboard
  SOURCES lut4.v
  EXPLICIT_ADD_FILE_TARGET
  )

