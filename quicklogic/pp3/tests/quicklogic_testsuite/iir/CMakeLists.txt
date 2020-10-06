add_file_target(FILE iir.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME iir-ql-chandalar
  BOARD chandalar
  SOURCES iir.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT iir-ql-chandalar
)

add_openocd_output(
  PARENT iir-ql-chandalar
)

# FIXME: Temporarily disable due to not enough resources after packing
#add_dependencies(all_ql_tests iir-ql-chandalar_bit)
#add_dependencies(all_ql_tests iir-ql-chandalar_jlink)
#add_dependencies(all_ql_tests iir-ql-chandalar_openocd)

