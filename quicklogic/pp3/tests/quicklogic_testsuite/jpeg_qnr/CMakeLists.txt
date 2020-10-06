add_file_target(FILE timescale.v SCANNER_TYPE verilog)
add_file_target(FILE div_su.v SCANNER_TYPE verilog)
add_file_target(FILE div_uu.v SCANNER_TYPE verilog)
add_file_target(FILE jpeg_qnr.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME jpeg-ql-chandalar
  BOARD chandalar
  SOURCES div_su.v div_uu.v jpeg_qnr.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT jpeg-ql-chandalar
)

add_openocd_output(
  PARENT jpeg-ql-chandalar
)

add_dependencies(all_ql_tests jpeg-ql-chandalar_bit)
add_dependencies(all_ql_tests jpeg-ql-chandalar_jlink)
add_dependencies(all_ql_tests jpeg-ql-chandalar_openocd)

