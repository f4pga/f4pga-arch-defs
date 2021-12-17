set(DESIGN_DIR ${QL_DESIGNS_DIR}/counter_8bit)

add_file_target(FILE ${DESIGN_DIR}/counter_8bit.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME counter_8bit-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/counter_8bit.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_8bit-ql-chandalar
)

add_openocd_output(
  PARENT counter_8bit-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  counter_8bit-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v counter_8bit-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog counter_8bit-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog counter_8bit-ql-chandalar_openocd)

# FIXME: FasmInconsistentBits: feature X31Y34.INTERFACE.BIDIR.INV.OSEL
#add_fpga_target(
  #NAME counter_8bit-ql-jimbob4
  #BOARD jimbob4
  #SOURCES
    #${DESIGN_DIR}/counter_8bit.v
  #INPUT_IO_FILE jimbob4.pcf
  #EXPLICIT_ADD_FILE_TARGET
  #)

#add_jlink_output(
  #PARENT counter_8bit-ql-jimbob4
#)

#add_openocd_output(
  #PARENT counter_8bit-ql-jimbob4
#)

#add_dependencies(all_pp3e_tests_bit  counter_8bit-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v counter_8bit-ql-jimbob4_bit_v)
