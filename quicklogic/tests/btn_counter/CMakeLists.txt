add_file_target(FILE btn_counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar-top.pcf)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME btn_counter-ql-chandalar-top
  BOARD chandalar-top
  SOURCES btn_counter.v
  INPUT_IO_FILE chandalar-top.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_counter-ql-chandalar-top
)

add_dependencies(all_ql_tests btn_counter-ql-chandalar-top_bit)
add_dependencies(all_ql_tests btn_counter-ql-chandalar-top_jlink)

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

add_dependencies(all_ql_tests btn_counter-ql-chandalar_bit)
add_dependencies(all_ql_tests btn_counter-ql-chandalar_jlink)

add_fpga_target(
  NAME btn_counter-ql-jimbob4
  BOARD jimbob4
  SOURCES btn_counter.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_counter-ql-jimbob4
)

add_dependencies(all_ql_tests btn_counter-ql-jimbob4_bit)
add_dependencies(all_ql_tests btn_counter-ql-jimbob4_jlink)
