add_file_target(FILE ram_blk.v SCANNER TYPE verilog)
add_file_target(FILE fifo_blk.v SCANNER TYPE verilog)
add_file_target(FILE af512x16_512x16.v SCANNER TYPE verilog)
add_file_target(FILE r512x16_512x16.v SCANNER TYPE verilog)
add_file_target(FILE fll_acslip.v SCANNER TYPE verilog)
add_file_target(FILE deci_filter_fir128coeff.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_Rx_FIFOs.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_StateMachine.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_registers.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_rx.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design3-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v i2s_slave_w_DMA.v i2s_slave_rx.v i2s_slave_w_DMA_registers.v i2s_slave_w_DMA_StateMachine.v i2s_slave_Rx_FIFOs.v deci_filter_fir128coeff.v fll_acslip.v r512x16_512x16.v af512x16_512x16.v fifo_blk.v ram_blk.v 
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design3-ql-chandalar
)

add_dependencies(all_ql_tests design3-ql-chandalar_bit)
add_dependencies(all_ql_tests design3-ql-chandalar_jlink)
