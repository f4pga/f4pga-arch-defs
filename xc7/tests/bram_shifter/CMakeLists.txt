add_file_target(FILE bram_shifter_18.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram_shifter_18
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v bram_shifter_18.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE bram_shifter_36.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram_shifter_36
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v bram_shifter_36.v
  EXPLICIT_ADD_FILE_TARGET
  )
