add_file_target(FILE plle2_adv_test.v SCANNER_TYPE verilog)
add_file_target(FILE pll_adv_int_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_adv_buf_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_adv_ext_basys3_bottom.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME pll_adv_int_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_adv_int_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_adv_buf_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_adv_buf_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_adv_ext_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_adv_ext_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )


add_vivado_target(
  NAME pll_adv_int_basys3_bottom_vivado
  PARENT_NAME pll_adv_int_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )

add_vivado_target(
  NAME pll_adv_buf_basys3_bottom_vivado
  PARENT_NAME pll_adv_buf_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )

add_vivado_target(
  NAME pll_adv_ext_basys3_bottom_vivado
  PARENT_NAME pll_adv_ext_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )


add_dependencies(all_xc7_tests
  pll_adv_int_basys3_bottom
  pll_adv_buf_basys3_bottom
  pll_adv_ext_basys3_bottom
)

add_file_target(FILE plle2_base_test.v SCANNER_TYPE verilog)
add_file_target(FILE pll_base_int_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_base_buf_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE pll_base_ext_basys3_bottom.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME pll_base_int_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_base_int_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_base_buf_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_base_buf_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME pll_base_ext_basys3_bottom
  BOARD basys3-bottom
  SOURCES pll_base_ext_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )


add_vivado_target(
  NAME pll_base_int_basys3_bottom_vivado
  PARENT_NAME pll_base_int_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )

add_vivado_target(
  NAME pll_base_buf_basys3_bottom_vivado
  PARENT_NAME pll_base_buf_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )

add_vivado_target(
  NAME pll_base_ext_basys3_bottom_vivado
  PARENT_NAME pll_base_ext_basys3_bottom
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )


add_dependencies(all_xc7_tests
  pll_base_int_basys3_bottom
  pll_base_buf_basys3_bottom
  pll_base_ext_basys3_bottom
)
