add_file_target(FILE sdiomux_xor.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME sdiomux_xor-ql-chandalar
  BOARD chandalar
  SOURCES sdiomux_xor.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT sdiomux_xor-ql-chandalar
)

add_dependencies(all_ql_tests sdiomux_xor-ql-chandalar_bit)
add_dependencies(all_ql_tests sdiomux_xor-ql-chandalar_jlink)

