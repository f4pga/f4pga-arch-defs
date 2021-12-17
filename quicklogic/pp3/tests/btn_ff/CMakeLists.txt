add_file_target(FILE btn_ff.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME btn_ff-ql-chandalar
  BOARD chandalar
  SOURCES btn_ff.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_ff-ql-chandalar
)

add_openocd_output(
  PARENT btn_ff-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit btn_ff-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v btn_ff-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog btn_ff-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog btn_ff-ql-chandalar_openocd)

add_fpga_target(
  NAME btn_ff-ql-jimbob4
  BOARD jimbob4
  SOURCES btn_ff.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT btn_ff-ql-jimbob4
)

add_openocd_output(
  PARENT btn_ff-ql-jimbob4
)

add_dependencies(all_pp3e_tests_bit btn_ff-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v btn_ff-ql-jimbob4_bit_v)	# Failure in mux expanding
