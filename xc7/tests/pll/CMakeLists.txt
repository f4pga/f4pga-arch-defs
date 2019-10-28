add_file_target(FILE plle2_test.v SCANNER_TYPE verilog)
add_file_target(FILE pll_basys3_x1y0.v SCANNER_TYPE verilog)

add_file_target(FILE basys3_x1y0.pcf)

add_fpga_target(
  NAME pll_basys3_x1y0
  BOARD basys3-x1y0
  SOURCES pll_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME pll_basys3_x1y0_vivado
  PARENT_NAME pll_basys3_x1y0
  CLOCK_PINS in_clk
  CLOCK_PERIODS 10.0
  )

add_dependencies(all_xc7_tests
  pll_basys3_x1y0
)

