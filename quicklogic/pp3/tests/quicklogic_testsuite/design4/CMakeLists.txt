add_file_target(FILE ram_blk.v SCANNER_TYPE verilog)
add_file_target(FILE r512x16_512x16.v SCANNER_TYPE verilog)
add_file_target(FILE r512x32_512x32.v SCANNER_TYPE verilog)
add_file_target(FILE dma_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE ksa32.v SCANNER_TYPE verilog)
add_file_target(FILE r2_bfly_p.v SCANNER_TYPE verilog)
add_file_target(FILE f_512_compute.v SCANNER_TYPE verilog)
add_file_target(FILE f_registers.v SCANNER_TYPE verilog)
add_file_target(FILE f_512_wrapp.v SCANNER_TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER_TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design4-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v  AL4S3B_FPGA_IP.v f_512_wrapp.v f_registers.v f_512_compute.v r2_bfly_p.v ksa32.v dma_ctrl.v r512x32_512x32.v r512x16_512x16.v ram_blk.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design4-ql-chandalar
)

add_dependencies(all_ql_tests design4-ql-chandalar_bit)
add_dependencies(all_ql_tests design4-ql-chandalar_jlink)

