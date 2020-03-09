add_file_target(FILE gclk_through.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)
#add_file_target(FILE arty.pcf)

add_fpga_target(
  NAME gclk_through_basys3
  BOARD basys3-full
  SOURCES gclk_through.v
  INPUT_IO_FILE basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME gclk_through_basys3_vivado
  PARENT_NAME gclk_through_basys3
  )

