add_file_target(FILE obufds_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

add_fpga_target(
  NAME obufds_basys3
  BOARD basys3-bottom
  SOURCES obufds_basys3.v
  INPUT_IO_FILE basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME obufds_basys3_vivado
  PARENT_NAME obufds_basys3
  )

add_dependencies(all_xc7_tests
  obufds_basys3
)

