add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE f_compute.v SCANNER TYPE verilog)
add_file_target(FILE fll_acslip.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_rx.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_RxRAMs.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_registers.v SCANNER TYPE verilog)
add_file_target(FILE i2s_slave_w_DMA_StateMachine.v SCANNER TYPE verilog)
add_file_target(FILE r1024x16_1024x16.v SCANNER TYPE verilog)
add_file_target(FILE r2_bfly.v SCANNER TYPE verilog)
add_file_target(FILE r512x16_512x16.v SCANNER TYPE verilog)
add_file_target(FILE ram_blk.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design5-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v f_compute.v fll_acslip.v i2s_slave_rx.v i2s_slave_RxRAMs.v i2s_slave_w_DMA.v i2s_slave_w_DMA_registers.v i2s_slave_w_DMA_StateMachine.v r1024x16_1024x16.v r2_bfly.v r512x16_512x16.v ram_blk.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design5-ql-chandalar
)

# FIXME: Temporarily disable due to not enough resources after packing
#add_dependencies(all_ql_tests design5-ql-chandalar_bit)
#add_dependencies(all_ql_tests design5-ql-chandalar_jlink)

