add_file_target(FILE iobuf_basys3_x1y0.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_x1y0.pcf)

add_fpga_target(
  NAME iobuf_basys3_x1y0
  BOARD basys3-x1y0
  SOURCES iobuf_basys3_x1y0.v
  INPUT_IO_FILE basys3_x1y0.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME iobuf_basys3_x1y0_vivado
  PARENT_NAME iobuf_basys3_x1y0
  )

add_dependencies(all_xc7_tests
  iobuf_basys3_x1y0
)

