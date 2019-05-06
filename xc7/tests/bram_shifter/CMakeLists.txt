add_file_target(FILE bram_shifter.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram_shifter
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v bram_shifter.v
  EXPLICIT_ADD_FILE_TARGET
  )
