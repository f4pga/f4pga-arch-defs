add_file_target(FILE sha1.v SCANNER_TYPE verilog)
add_file_target(FILE sha256_fullfit.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME sha256_fullfit-ql-chandalar
  BOARD chandalar
  SOURCES sha256_fullfit.v sha1.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT sha256_fullfit-ql-chandalar
)

add_dependencies(all_ql_tests sha256_fullfit-ql-chandalar_bit)
add_dependencies(all_ql_tests sha256_fullfit-ql-chandalar_jlink)

