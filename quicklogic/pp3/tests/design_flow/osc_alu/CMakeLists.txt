set(DESIGN_DIR ${QL_DESIGNS_DIR}/osc_alu)

add_file_target(FILE ${DESIGN_DIR}/oc8051_defines.v SCANNER TYPE verilog)
add_file_target(FILE ${DESIGN_DIR}/oc8051_divide.v SCANNER TYPE verilog)
add_file_target(FILE ${DESIGN_DIR}/oc8051_multiply.v SCANNER TYPE verilog)
add_file_target(FILE ${DESIGN_DIR}/oc8051_timescale.v SCANNER TYPE verilog)
add_file_target(FILE ${DESIGN_DIR}/oc8051_alu.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)
add_file_target(FILE pd64.pcf)

add_fpga_target(
  NAME osc_alu-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/oc8051_defines.v
    ${DESIGN_DIR}/oc8051_divide.v
    ${DESIGN_DIR}/oc8051_multiply.v
    ${DESIGN_DIR}/oc8051_timescale.v
    ${DESIGN_DIR}/oc8051_alu.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT osc_alu-ql-chandalar
)

add_openocd_output(
  PARENT osc_alu-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  osc_alu-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v osc_alu-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog osc_alu-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog osc_alu-ql-chandalar_openocd)
add_dependencies(osc_alu-ql-chandalar_analysis osc_alu-ql-chandalar_bit_v)
