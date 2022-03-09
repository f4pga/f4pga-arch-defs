set(CURR_DIR ${QL_DESIGNS_DIR}/IR_Remote)
add_file_target(FILE ${CURR_DIR}/IR_Remote.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/i2cSlave.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/i2cSlaveTop.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/i2cSlaveSerialInterface.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/r1024x9_1024x9.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/IR_Emitter_Carrier_Generator.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/IR_Emitter_Interface.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/IR_Emitter_Modulator.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/IR_Emitter_Registers.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME IR_Remote_test-umc22-no-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/IR_Remote.v ${CURR_DIR}/r1024x9_1024x9.v ${CURR_DIR}/IR_Emitter_Carrier_Generator.v ${CURR_DIR}/i2cSlave.v ${CURR_DIR}/i2cSlaveTop.v ${CURR_DIR}/i2cSlaveSerialInterface.v ${CURR_DIR}/IR_Emitter_Interface.v ${CURR_DIR}/IR_Emitter_Modulator.v ${CURR_DIR}/IR_Emitter_Registers.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME IR_Remote_test-umc22-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${CURR_DIR}/IR_Remote.v ${CURR_DIR}/r1024x9_1024x9.v ${CURR_DIR}/IR_Emitter_Carrier_Generator.v ${CURR_DIR}/i2cSlave.v ${CURR_DIR}/i2cSlaveTop.v ${CURR_DIR}/i2cSlaveSerialInterface.v ${CURR_DIR}/IR_Emitter_Interface.v ${CURR_DIR}/IR_Emitter_Modulator.v ${CURR_DIR}/IR_Emitter_Registers.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder IR_Remote_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    IR_Remote_test-umc22-adder_bit)
