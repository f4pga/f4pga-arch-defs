add_file_target(FILE bufr_unit.v SCANNER_TYPE verilog)
add_file_target(FILE bufr_basys3.v SCANNER_TYPE verilog)

add_file_target(FILE basys3.pcf)

add_fpga_target(
  NAME bufr_basys3
  BOARD basys3-full
  SOURCES bufr_basys3.v
  INPUT_IO_FILE basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME bufr_basys3_vivado
  PARENT_NAME bufr_basys3
  CLOCK_PINS in_clk
  CLOCK_PERIODS 10.0
  )

add_dependencies(all_xc7_tests
  bufr_basys3
)

