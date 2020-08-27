add_file_target(FILE r512x32_512x32.v SCANNER TYPE verilog)
add_file_target(FILE r1024x8_1024x8.v SCANNER TYPE verilog)
add_file_target(FILE r1024x16_1024x16.v SCANNER TYPE verilog)
add_file_target(FILE r512x16_512x16.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_RAMs.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog) 
add_file_target(FILE chandalar.pcf)
add_file_target(FILE init_1024x16.hex)
add_file_target(FILE init_1024x8.hex)
add_file_target(FILE init_512x16.hex)
add_file_target(FILE init_512x32.hex)

add_custom_command(OUTPUT r512x32_512x32.v DEPENDS init_512x32.hex APPEND)
add_custom_command(OUTPUT r1024x8_1024x8.v DEPENDS init_1024x8.hex APPEND)
add_custom_command(OUTPUT r1024x16_1024x16.v DEPENDS init_1024x16.hex APPEND)
add_custom_command(OUTPUT r512x16_512x16.v DEPENDS init_512x16.hex APPEND)



add_fpga_target(
  NAME ram_test-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v AL4S3B_FPGA_RAMs.v AL4S3B_FPGA_QL_Reserved.v  r512x16_512x16.v r1024x16_1024x16.v r1024x8_1024x8.v r512x32_512x32.v 
  INPUT_IO_FILE chandalar.pcf 
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT ram_test-ql-chandalar
)

add_dependencies(all_ql_tests ram_test-ql-chandalar_bit)
add_dependencies(all_ql_tests ram_test-ql-chandalar_jlink)

