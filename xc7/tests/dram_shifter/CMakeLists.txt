add_file_target(FILE dram_shifter_32x1s.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME dram_shifter_32x1s
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v dram_shifter_32x1s.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE dram_shifter_32x1d.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME dram_shifter_32x1d
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v dram_shifter_32x1d.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE dram_shifter_64x1s.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME dram_shifter_64x1s
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v dram_shifter_64x1s.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_file_target(FILE dram_shifter_64x1d.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME dram_shifter_64x1d
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ../common/ram_shifter.v dram_shifter_64x1d.v
  EXPLICIT_ADD_FILE_TARGET
  )
