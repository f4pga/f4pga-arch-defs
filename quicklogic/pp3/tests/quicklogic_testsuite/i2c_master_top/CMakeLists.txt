add_file_target(FILE i2c_master_defines.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_byte_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE StateMachine.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_bit_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE i2c_master_top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME i2c_master_top-ql-chandalar
  BOARD chandalar
  SOURCES i2c_master_top.v i2c_master_defines.v i2c_master_byte_ctrl.v StateMachine.v i2c_master_bit_ctrl.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT i2c_master_top-ql-chandalar
)

add_dependencies(all_ql_tests i2c_master_top-ql-chandalar_bit)
add_dependencies(all_ql_tests i2c_master_top-ql-chandalar_jlink)
add_dependencies(all_quick_tests i2c_master_top-ql-chandalar_analysis)
add_dependencies(i2c_master_top-ql-chandalar_analysis i2c_master_top-ql-chandalar_bit_v)

