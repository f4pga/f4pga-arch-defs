add_file_target(FILE RAM_16K_BLK.v SCANNER TYPE verilog)
add_file_target(FILE r512x32_512x32.v SCANNER TYPE verilog)
add_file_target(FILE r512x16_512x16_r1024x8_1024x8.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_RAMs.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog) 
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME ram_test-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v AL4S3B_FPGA_RAMs.v AL4S3B_FPGA_QL_Reserved.v  r512x16_512x16_r1024x8_1024x8.v r512x32_512x32.v RAM_16K_BLK.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ram_test-ql-chandalar
)

add_dependencies(all_ql_tests ram_test-ql-chandalar_bit)
add_dependencies(all_ql_tests ram_test-ql-chandalar_jlink)
#add_dependencies(all_quick_tests ram_test-ql-chandalar_analysis)
#add_dependencies(ram_test-ql-chandalar_analysis ram_test-ql-chandalar_bit_v)


