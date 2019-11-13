add_fpga_target(
  NAME simple_ff
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  SOURCES simple_ff.v
  )

add_vivado_target(
  NAME simple_ff_vivado
  PARENT_NAME simple_ff
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_fpga_target(
  NAME simple_ff_full
  BOARD basys3-full
  INPUT_IO_FILE basys3_x1y0.pcf
  SOURCES simple_ff_x1y0.v
  )

add_vivado_target(
  NAME simple_ff_full_vivado
  PARENT_NAME simple_ff_full
  )
