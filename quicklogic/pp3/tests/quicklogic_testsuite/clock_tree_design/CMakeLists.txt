add_file_target(FILE clock_tree_design.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME clock-tree-design-ql-chandalar
  BOARD chandalar
  SOURCES clock_tree_design.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT clock-tree-design-ql-chandalar
)

add_dependencies(all_ql_tests clock-tree-design-ql-chandalar_bit)
add_dependencies(all_ql_tests clock-tree-design-ql-chandalar_jlink)
