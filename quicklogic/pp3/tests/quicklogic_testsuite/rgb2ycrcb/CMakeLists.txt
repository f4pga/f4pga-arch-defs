add_file_target(FILE rgb2ycrcb.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME rgb2ycrcb-ql-chandalar
  BOARD chandalar
  SOURCES rgb2ycrcb.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT rgb2ycrcb-ql-chandalar
)

add_openocd_output(
  PARENT rgb2ycrcb-ql-chandalar
)

add_dependencies(all_ql_tests rgb2ycrcb-ql-chandalar_bit)
add_dependencies(all_ql_tests rgb2ycrcb-ql-chandalar_jlink)
add_dependencies(all_ql_tests rgb2ycrcb-ql-chandalar_openocd)

add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME rgb2ycrcb-ql-quickfeather
  BOARD quickfeather
  SOURCES rgb2ycrcb.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT rgb2ycrcb-ql-quickfeather
)

add_openocd_output(
  PARENT rgb2ycrcb-ql-quickfeather
)

add_dependencies(all_ql_tests rgb2ycrcb-ql-quickfeather_bit)
add_dependencies(all_ql_tests rgb2ycrcb-ql-quickfeather_jlink)
add_dependencies(all_ql_tests rgb2ycrcb-ql-quickfeather_openocd)

