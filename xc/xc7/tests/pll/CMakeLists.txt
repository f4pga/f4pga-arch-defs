add_file_target(FILE plle2_test.v SCANNER_TYPE verilog)
add_file_target(FILE pll_int_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_buf_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_ext_basys3_bottom.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME pll_int_basys3_full
  BOARD basys3-bottom
  SOURCES pll_int_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_buf_basys3_full
  BOARD basys3-bottom
  SOURCES pll_buf_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_ext_basys3_full
  BOARD basys3-bottom
  SOURCES pll_ext_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_pmod.pcf
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

