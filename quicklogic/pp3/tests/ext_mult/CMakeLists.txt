add_file_target(FILE ext_mult.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE pd64.pcf)

add_fpga_target(
  NAME ext_mult-ql-chandalar
  BOARD chandalar
  SOURCES ext_mult.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_eos_s3_tests ext_mult-ql-chandalar_route)
add_dependencies(ext_mult-ql-chandalar_analysis ext_mult-ql-chandalar_bit_v)
