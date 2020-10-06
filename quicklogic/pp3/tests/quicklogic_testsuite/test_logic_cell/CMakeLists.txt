add_file_target(FILE test_logic_cell.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME test_logic_cell-ql-chandalar
  BOARD chandalar
  SOURCES test_logic_cell.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT test_logic_cell-ql-chandalar
)

add_openocd_output(
  PARENT test_logic_cell-ql-chandalar
)

add_dependencies(all_ql_tests test_logic_cell-ql-chandalar_bit)
add_dependencies(all_ql_tests test_logic_cell-ql-chandalar_jlink)
add_dependencies(all_ql_tests test_logic_cell-ql-chandalar_openocd)
