add_file_target(FILE bram.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME bram-ql-chandalar
  BOARD chandalar
  SOURCES bram.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT bram-ql-chandalar
)

add_openocd_output(
  PARENT bram-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit bram-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v bram-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog bram-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog bram-ql-chandalar_openocd)

add_fpga_target(
  NAME bram-ql-jimbob4
  BOARD jimbob4
  SOURCES bram.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

#add_dependencies(all_pp3e_tests_bit bram-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v bram-ql-jimbob4_bit_v)
