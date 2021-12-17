set(DESIGN_DIR ${QL_DESIGNS_DIR}/test_logic_cell)

add_fpga_target(
  NAME test_logic_cell-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/test_logic_cell.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT test_logic_cell-ql-chandalar
)

add_openocd_output(
  PARENT test_logic_cell-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  test_logic_cell-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v test_logic_cell-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog test_logic_cell-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog test_logic_cell-ql-chandalar_openocd)

# FIXME: FasmInconsistentBits: enable_feature() function didn't set or clear bit for the feature: X15Y34.INTERFACE.BIDIR.INV.OSEL
#add_fpga_target(
  #NAME test_logic_cell-ql-jimbob4
  #BOARD jimbob4
  #SOURCES
    #${DESIGN_DIR}/test_logic_cell.v
  #INPUT_IO_FILE jimbob4.pcf
  #EXPLICIT_ADD_FILE_TARGET
  #)

#add_jlink_output(
  #PARENT test_logic_cell-ql-jimbob4
#)

#add_openocd_output(
  #PARENT test_logic_cell-ql-jimbob4
#)

#add_dependencies(all_pp3e_tests_bit  test_logic_cell-ql-jimbob4_bit)
#add_dependencies(all_pp3e_tests_bit_v test_logic_cell-ql-jimbob4_bit_v)
