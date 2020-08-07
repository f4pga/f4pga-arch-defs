add_file_target(FILE Serializer_Deserializer_Test.v SCANNER TYPE verilog)
add_file_target(FILE Serializer_Deserializer.v SCANNER TYPE verilog)
add_file_target(FILE Dma_Ctrl.v SCANNER TYPE verilog)
add_file_target(FILE Fsm_Top.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design10-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_QL_Reserved.v AL4S3B_FPGA_Registers.v Dma_Ctrl.v Fsm_Top.v Serializer_Deserializer.v Serializer_Deserializer_Test.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design10-ql-chandalar
)

add_dependencies(all_ql_tests design10-ql-chandalar_bit)
add_dependencies(all_ql_tests design10-ql-chandalar_jlink)

