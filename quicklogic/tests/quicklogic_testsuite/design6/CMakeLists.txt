add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE duty_cycle_count.v SCANNER TYPE verilog)
add_file_target(FILE freq_counter.v SCANNER TYPE verilog)
add_file_target(FILE pwm_counter.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design6-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_QL_Reserved.v AL4S3B_FPGA_Registers.v duty_cycle_count.v freq_counter.v pwm_counter.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design6-ql-chandalar
)

add_dependencies(all_ql_tests design6-ql-chandalar_bit)
add_dependencies(all_ql_tests design6-ql-chandalar_jlink)

