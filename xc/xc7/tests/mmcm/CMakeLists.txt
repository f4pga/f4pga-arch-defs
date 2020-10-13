add_file_target(FILE mmcme2_test.v SCANNER_TYPE verilog)
add_file_target(FILE mmcm_int_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE mmcm_buf_basys3_bottom.v SCANNER_TYPE verilog)
add_file_target(FILE mmcm_ext_basys3_bottom.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME mmcm_int_basys3
  BOARD basys3-bottom
  SOURCES mmcm_int_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME mmcm_buf_basys3
  BOARD basys3-bottom
  SOURCES mmcm_buf_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME mmcm_ext_basys3
  BOARD basys3-bottom
  SOURCES mmcm_ext_basys3_bottom.v
  INPUT_IO_FILE ${COMMON}/basys3_bottom_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )


add_vivado_target(
  NAME mmcm_int_basys3_vivado
  PARENT_NAME mmcm_int_basys3
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_vivado_target(
  NAME mmcm_buf_basys3_vivado
  PARENT_NAME mmcm_buf_basys3
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_vivado_target(
  NAME mmcm_ext_basys3_vivado
  PARENT_NAME mmcm_ext_basys3
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )


add_dependencies(all_xc7_tests
  mmcm_int_basys3
  mmcm_buf_basys3
#  mmcm_ext_basys3_full  # Vivado import crashes as the feedback net does not have the CLOCK_DEDICATED_ROUTE=FALSE set.
)

