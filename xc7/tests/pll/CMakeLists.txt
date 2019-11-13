add_file_target(FILE plle2_test.v SCANNER_TYPE verilog)
add_file_target(FILE pll_int_basys3_x1y0.v SCANNER_TYPE verilog)
add_file_target(FILE pll_buf_basys3_x1y0.v SCANNER_TYPE verilog)
add_file_target(FILE pll_ext_basys3_x1y0.v SCANNER_TYPE verilog)

add_file_target(FILE basys3_x1y0.pcf)

add_fpga_target(
  NAME pll_int_basys3_full
  BOARD basys3-full
  SOURCES pll_int_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_buf_basys3_full
  BOARD basys3-full
  SOURCES pll_buf_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_ext_basys3_full
  BOARD basys3-full
  SOURCES pll_ext_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  EXPLICIT_ADD_FILE_TARGET
  )


add_vivado_target(
  NAME pll_int_basys3_full_vivado
  PARENT_NAME pll_int_basys3_full
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_vivado_target(
  NAME pll_buf_basys3_full_vivado
  PARENT_NAME pll_buf_basys3_full
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_vivado_target(
  NAME pll_ext_basys3_full_vivado
  PARENT_NAME pll_ext_basys3_full
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )


add_dependencies(all_xc7_tests
  pll_int_basys3_full
  pll_buf_basys3_full
#  pll_ext_basys3_full  # Vivado import crashes as the feedback net does not have the CLOCK_DEDICATED_ROUTE=FALSE set.
)

