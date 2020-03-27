add_file_target(FILE rs_decoder_1.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME rs-decoder-ql-chandalar
  BOARD chandalar
  SOURCES rs_decoder_1.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT rs-decoder-ql-chandalar
)

add_dependencies(all_ql_tests rs-decoder-ql-chandalar_bit)
add_dependencies(all_ql_tests rs-decoder-ql-chandalar_jlink)

