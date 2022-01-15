add_file_target(FILE simple_latch.v SCANNER_TYPE verilog)
add_file_target(FILE arty.xdc)

add_fpga_target(
  NAME simple_latch
  BOARD arty-full
  INPUT_XDC_FILE arty.xdc
  SOURCES simple_latch.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME simple_latch_vivado
  PARENT_NAME simple_latch
  )

