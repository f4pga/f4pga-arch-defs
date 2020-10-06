add_file_target(FILE counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME sdiomux-counter-ql-chandalar
  BOARD chandalar
  SOURCES counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT sdiomux-counter-ql-chandalar
)

add_openocd_output(
  PARENT sdiomux-counter-ql-chandalar
)

add_dependencies(all_quick_tests sdiomux-counter-ql-chandalar_bit)
add_dependencies(all_quick_tests sdiomux-counter-ql-chandalar_jlink)
add_dependencies(all_quick_tests sdiomux-counter-ql-chandalar_openocd)

add_dependencies(all_ql_tests sdiomux-counter-ql-chandalar_bit)
add_dependencies(all_ql_tests sdiomux-counter-ql-chandalar_jlink)
add_dependencies(all_ql_tests sdiomux-counter-ql-chandalar_openocd)

