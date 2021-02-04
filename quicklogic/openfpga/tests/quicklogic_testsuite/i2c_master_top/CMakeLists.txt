add_file_target(FILE i2c_master_defines.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_byte_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE StateMachine.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_bit_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME i2c_master_top-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES i2c_master_top.v i2c_master_defines.v i2c_master_byte_ctrl.v StateMachine.v i2c_master_bit_ctrl.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME i2c_master_top-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES i2c_master_top.v i2c_master_defines.v i2c_master_byte_ctrl.v StateMachine.v i2c_master_bit_ctrl.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder i2c_master_top-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    i2c_master_top-ql-openfpga-k4_N8-adder_route)
