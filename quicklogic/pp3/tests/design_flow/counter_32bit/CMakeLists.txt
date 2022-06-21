set(DESIGN_DIR ${QL_DESIGNS_DIR}/counter_32bit)
add_file_target(FILE ${DESIGN_DIR}/counter_32bit.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_32bit-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/counter_32bit.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_32bit-ql-chandalar
)

add_openocd_output(
  PARENT counter_32bit-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  counter_32bit-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v counter_32bit-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog counter_32bit-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog counter_32bit-ql-chandalar_openocd)
