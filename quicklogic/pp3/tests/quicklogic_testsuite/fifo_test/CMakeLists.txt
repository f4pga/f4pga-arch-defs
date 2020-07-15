add_file_target(FILE FIFO_16K_BLK.v SCANNER TYPE verilog)
add_file_target(FILE af512x32_512x32.v SCANNER TYPE verilog)
add_file_target(FILE af512x16_512x16_f512x16_512x16.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog) 
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME fifo_test-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v AL4S3B_FPGA_QL_Reserved.v af512x16_512x16_f512x16_512x16.v af512x32_512x32.v FIFO_16K_BLK.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT fifo_test-ql-chandalar
)

add_dependencies(all_ql_tests fifo_test-ql-chandalar_bit)
add_dependencies(all_ql_tests fifo_test-ql-chandalar_jlink)

