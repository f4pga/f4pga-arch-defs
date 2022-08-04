add_file_target(FILE bram.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram
  BOARD basys3
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES bram.v
  EXPLICIT_ADD_FILE_TARGET
  )
