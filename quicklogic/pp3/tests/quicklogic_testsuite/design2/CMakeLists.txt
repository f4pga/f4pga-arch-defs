add_file_target(FILE af1024x16_512x32.v SCANNER_TYPE verilog)
add_file_target(FILE af512x16_512x16.v SCANNER_TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER_TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER_TYPE verilog)
add_file_target(FILE fifo_blk.v SCANNER_TYPE verilog)
add_file_target(FILE i2s_slave_rx.v SCANNER_TYPE verilog)
add_file_target(FILE i2s_slave_Rx_FIFOs.v SCANNER_TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA.v SCANNER_TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_registers.v SCANNER_TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_StateMachine.v SCANNER_TYPE verilog)
add_file_target(FILE ir_counters.v SCANNER_TYPE verilog)
add_file_target(FILE ir_reg_if.v SCANNER_TYPE verilog)
add_file_target(FILE ir_rx_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE ir_tx_ctrl.v SCANNER_TYPE verilog)
add_file_target(FILE ir_tx_rx.v SCANNER_TYPE verilog)
add_file_target(FILE ir_tx_rx_wrap.v SCANNER_TYPE verilog)
add_file_target(FILE r1024x8_1024x8.v SCANNER_TYPE verilog)
add_file_target(FILE ram_blk.v SCANNER_TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design2-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v af1024x16_512x32.v AL4S3B_FPGA_IP.v fifo_blk.v i2s_slave_Rx_FIFOs.v i2s_slave_w_DMA_registers.v ir_counters.v ir_rx_ctrl.v ir_tx_rx.v r1024x8_1024x8.v af512x16_512x16.v AL4S3B_FPGA_Registers.v i2s_slave_rx.v i2s_slave_w_DMA.v i2s_slave_w_DMA_StateMachine.v ir_reg_if.v ir_tx_ctrl.v ir_tx_rx_wrap.v ram_blk.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design2-ql-chandalar
)

add_openocd_output(
  PARENT design2-ql-chandalar
)

add_dependencies(all_ql_tests design2-ql-chandalar_bit)
add_dependencies(all_ql_tests design2-ql-chandalar_jlink)
add_dependencies(all_ql_tests design2-ql-chandalar_openocd)

