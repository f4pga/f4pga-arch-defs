set(DESIGN_DIR ${QL_DESIGNS_DIR}/IR_Remote)

add_fpga_target(
  NAME IR_Remote-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/IR_Emitter_Carrier_Generator.v
    ${DESIGN_DIR}/IR_Emitter_Interface.v
    ${DESIGN_DIR}/IR_Emitter_Modulator.v
    ${DESIGN_DIR}/IR_Emitter_Registers.v
    ${DESIGN_DIR}/IR_Remote.v
    ${DESIGN_DIR}/i2cSlave.v
    ${DESIGN_DIR}/i2cSlaveSerialInterface.v
    ${DESIGN_DIR}/i2cSlaveTop.v
    ${DESIGN_DIR}/r1024x9_1024x9.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=1,PB-GMUX=1,PB-LOGIC<=387
)


add_jlink_output(
  PARENT IR_Remote-ql-chandalar
)

add_openocd_output(
  PARENT IR_Remote-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  IR_Remote-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  IR_Remote-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   IR_Remote-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v IR_Remote-ql-chandalar_bit_v)

add_dependencies(IR_Remote-ql-chandalar_analysis IR_Remote-ql-chandalar_bit_v)

add_dependencies(all_eos_s3_tests_regression IR_Remote-ql-chandalar_assert_usage)
