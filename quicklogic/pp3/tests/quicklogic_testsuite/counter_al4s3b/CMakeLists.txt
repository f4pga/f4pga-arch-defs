add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog) 
add_file_target(FILE chandalar.pcf)
add_file_target(FILE jlink_cmds.txt)
add_file_target(FILE jlink_out_gold)
add_file_target(FILE jlink_script.sh)

add_fpga_target(
  NAME counter_al4s3b-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v AL4S3B_FPGA_QL_Reserved.v 
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT counter_al4s3b-ql-chandalar
)

add_dependencies(all_ql_tests counter_al4s3b-ql-chandalar_bit)
add_dependencies(all_ql_tests counter_al4s3b-ql-chandalar_jlink)
