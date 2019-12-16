add_file_target(FILE carry.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME carry_basys3
  BOARD basys3
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES carry.v
  EXPLICIT_ADD_FILE_TARGET
  )
