add_file_target(FILE obuf_packing.v SCANNER_TYPE verilog)
add_file_target(FILE dummy.pcf)

add_fpga_target(
  NAME obuf_packing
  BOARD arty-full
  SOURCES obuf_packing.v
  INPUT_IO_FILE dummy.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME obuf_packing_vivado
  PARENT_NAME obuf_packing
  )
