add_file_target(FILE ext_counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME ext_counter-ql-chandalar
  BOARD chandalar
  SOURCES ext_counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ext_counter-ql-chandalar
)

add_dependencies(all_ql_tests ext_counter-ql-chandalar_bit)
add_dependencies(all_ql_tests ext_counter-ql-chandalar_jlink)
add_dependencies(all_quick_tests ext_counter-ql-chandalar_analysis)
add_dependencies(ext_counter-ql-chandalar_analysis ext_counter-ql-chandalar_bit_v)


add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME ext_counter-ql-quickfeather
  BOARD quickfeather
  SOURCES ext_counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ext_counter-ql-quickfeather
)

add_dependencies(all_ql_tests ext_counter-ql-quickfeather_bit)
add_dependencies(all_ql_tests ext_counter-ql-quickfeather_jlink)

