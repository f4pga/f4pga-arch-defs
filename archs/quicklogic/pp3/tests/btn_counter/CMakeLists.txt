add_file_target(FILE btn_counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE quickfeather.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME btn_counter-ql-chandalar
  BOARD chandalar
  SOURCES btn_counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_counter-ql-chandalar
)

add_openocd_output(
  PARENT btn_counter-ql-chandalar
)

add_dependencies(all_quick_tests btn_counter-ql-chandalar_bit)
add_dependencies(all_quick_tests btn_counter-ql-chandalar_jlink)
add_dependencies(all_quick_tests btn_counter-ql-chandalar_openocd)

add_dependencies(all_ql_tests_bit btn_counter-ql-chandalar_bit)
add_dependencies(all_ql_tests_bit_v btn_counter-ql-chandalar_bit_v)
add_dependencies(all_ql_tests_prog btn_counter-ql-chandalar_jlink)
add_dependencies(all_ql_tests_prog btn_counter-ql-chandalar_openocd)


add_fpga_target(
  NAME btn_counter-ql-quickfeather
  BOARD quickfeather
  SOURCES btn_counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_counter-ql-quickfeather
)

add_openocd_output(
  PARENT btn_counter-ql-quickfeather
)

add_dependencies(all_ql_tests_bit btn_counter-ql-quickfeather_bit)
add_dependencies(all_ql_tests_bit_v btn_counter-ql-quickfeather_bit_v)
add_dependencies(all_ql_tests_prog btn_counter-ql-quickfeather_jlink)
add_dependencies(all_ql_tests_prog btn_counter-ql-quickfeather_openocd)

# add_fpga_target(
#  NAME btn_counter-ql-jimbob4
#  BOARD jimbob4
#  SOURCES btn_counter.v
#  INPUT_IO_FILE jimbob4.pcf
#  EXPLICIT_ADD_FILE_TARGET
#  )

# add_jlink_output(
#  PARENT btn_counter-ql-jimbob4
#)

# add_openocd_output(
#  PARENT btn_counter-ql-jimbob4
#)

# add_dependencies(all_ql_tests btn_counter-ql-jimbob4_bit)
# add_dependencies(all_ql_tests btn_counter-ql-jimbob4_jlink)
# add_dependencies(all_ql_tests btn_counter-ql-jimbob4_openocd)
