add_file_target(FILE ext_counter.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jimbob4.pcf)

add_fpga_target(
  NAME ext_counter-ql-chandalar
  BOARD chandalar
  SOURCES ext_counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ext_counter-ql-chandalar
)

add_openocd_output(
  PARENT ext_counter-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit ext_counter-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v ext_counter-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog ext_counter-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog ext_counter-ql-chandalar_openocd)

add_file_target(FILE quickfeather.pcf)

add_fpga_target(
  NAME ext_counter-ql-quickfeather
  BOARD quickfeather
  SOURCES ext_counter.v
  INPUT_IO_FILE quickfeather.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ext_counter-ql-quickfeather
)

add_openocd_output(
  PARENT ext_counter-ql-quickfeather
)

add_dependencies(all_eos_s3_tests_bit ext_counter-ql-quickfeather_bit)
add_dependencies(all_eos_s3_tests_bit_v ext_counter-ql-quickfeather_bit_v)
add_dependencies(all_eos_s3_tests_prog ext_counter-ql-quickfeather_jlink)
add_dependencies(all_eos_s3_tests_prog ext_counter-ql-quickfeather_openocd)

add_fpga_target(
  NAME ext_counter-ql-jimbob4
  BOARD jimbob4
  SOURCES ext_counter.v
  INPUT_IO_FILE jimbob4.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ext_counter-ql-jimbob4
)

add_openocd_output(
  PARENT ext_counter-ql-jimbob4
)

add_dependencies(all_pp3e_tests_bit ext_counter-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v ext_counter-ql-jimbob4_bit_v)	# Failure in mux expanding
