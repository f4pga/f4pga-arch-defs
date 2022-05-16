add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME counter-ql-chandalar
  BOARD chandalar
  SOURCES counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT counter-ql-chandalar
)

add_openocd_output(
  PARENT counter-ql-chandalar
)

add_dependencies(all_quick_tests counter-ql-chandalar_bit)
add_dependencies(all_quick_tests counter-ql-chandalar_jlink)
add_dependencies(all_quick_tests counter-ql-chandalar_openocd)

add_dependencies(all_ql_tests_bit counter-ql-chandalar_bit)
add_dependencies(all_ql_tests_bit_v counter-ql-chandalar_bit_v)
add_dependencies(all_ql_tests_prog counter-ql-chandalar_jlink)
add_dependencies(all_ql_tests_prog counter-ql-chandalar_openocd)


add_fpga_target(
  NAME counter-ql-quickfeather
  BOARD quickfeather
  SOURCES counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT counter-ql-quickfeather
)

add_openocd_output(
  PARENT counter-ql-quickfeather
)

add_dependencies(all_ql_tests_bit counter-ql-quickfeather_bit)
add_dependencies(all_ql_tests_bit_v counter-ql-quickfeather_bit_v)
add_dependencies(all_ql_tests_prog counter-ql-quickfeather_jlink)
add_dependencies(all_ql_tests_prog counter-ql-quickfeather_openocd)

