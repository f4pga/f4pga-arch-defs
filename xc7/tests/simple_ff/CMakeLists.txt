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

add_file_target(FILE simple_ff_full.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME simple_ff_full
  BOARD basys3-full
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES simple_ff_full.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_ff_full_vivado
  PARENT_NAME simple_ff_full
  )

add_file_target(FILE simple_ff_full_loc.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME simple_ff_full_loc
  BOARD basys3-full
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES simple_ff_full_loc.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_ff_full_loc_vivado
  PARENT_NAME simple_ff_full_loc
  )
