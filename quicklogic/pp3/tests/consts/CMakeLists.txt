add_file_target(FILE consts.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME consts-ql-chandalar
  BOARD chandalar
  SOURCES consts.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_eos_s3_tests consts-ql-chandalar_route)

add_fpga_target(
  NAME consts-ql-jimbob4
  BOARD jimbob4
  SOURCES consts.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
 )

add_jlink_output(
  PARENT consts-ql-jimbob4
)

 add_openocd_output(
  PARENT consts-ql-jimbob4
)

add_dependencies(all_pp3e_tests consts-ql-jimbob4_route)
