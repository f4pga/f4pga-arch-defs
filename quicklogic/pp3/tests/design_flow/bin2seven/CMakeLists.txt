set(DESIGN_DIR ${QL_DESIGNS_DIR}/bin2seven)

add_file_target(FILE ${DESIGN_DIR}/bin2seven.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME bin2seven-ql-chandalar
  BOARD chandalar
  SOURCES ${DESIGN_DIR}/bin2seven.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT bin2seven-ql-chandalar
)

add_openocd_output(
  PARENT bin2seven-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  bin2seven-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v bin2seven-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog bin2seven-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog bin2seven-ql-chandalar_openocd)

# FIXME: FasmInconsistentBits: feature X16Y16.LOGIC.LOGIC.Ipwr_gates.J_pwr_st
#add_fpga_target(
  #NAME bin2seven-ql-jimbob4
  #BOARD jimbob4
  #SOURCES ${DESIGN_DIR}/bin2seven.v
  #INPUT_IO_FILE jimbob4.pcf
  #EXPLICIT_ADD_FILE_TARGET
  #)

#add_jlink_output(
  #PARENT bin2seven-ql-jimbob4
#)

#add_openocd_output(
  #PARENT bin2seven-ql-jimbob4
#)

#add_dependencies(all_pp3e_tests_bit  bin2seven-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v bin2seven-ql-jimbob4_bit_v)
