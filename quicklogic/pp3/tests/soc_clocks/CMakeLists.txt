add_file_target(FILE soc_clocks.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME soc_clocks-ql-chandalar
  BOARD chandalar
  SOURCES soc_clocks.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT soc_clocks-ql-chandalar
)

add_dependencies(all_ql_tests soc_clocks-ql-chandalar_bit)
add_dependencies(all_ql_tests soc_clocks-ql-chandalar_jlink)
add_dependencies(all_quick_tests soc_clocks-ql-chandalar_analysis)
add_dependencies(soc_clocks-ql-chandalar_analysis soc_clocks-ql-chandalar_bit_v)


add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME soc_clocks-ql-quickfeather
  BOARD quickfeather
  SOURCES soc_clocks.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT soc_clocks-ql-quickfeather
)

add_dependencies(all_ql_tests soc_clocks-ql-quickfeather_bit)
add_dependencies(all_ql_tests soc_clocks-ql-quickfeather_jlink)
