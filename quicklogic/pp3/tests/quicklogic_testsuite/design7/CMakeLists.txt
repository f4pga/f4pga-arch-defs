add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE f512x18_512x18.v SCANNER TYPE verilog)
add_file_target(FILE f512x36_512x36.v SCANNER TYPE verilog)
add_file_target(FILE f512x9_512x9.v SCANNER TYPE verilog)
add_file_target(FILE fifo_blk.v SCANNER TYPE verilog)
add_file_target(FILE i2c_master_bit_ctrl.v SCANNER TYPE verilog)
add_file_target(FILE i2c_master_byte_ctrl.v SCANNER TYPE verilog)
add_file_target(FILE i2c_master_defines.v SCANNER TYPE verilog)
add_file_target(FILE i2c_master_top.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_CmdQueue.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_CmdQueue_Registers_dma.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_CmdQueue_StateMachine.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_CmdQueue_Top.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_CmdQueue_Tx_FIFO.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_DMA.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_DMA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE I2C_Master_w_DMA_StateMachine.v SCANNER TYPE verilog)
add_file_target(FILE LCD_controller_registers.v SCANNER TYPE verilog)
add_file_target(FILE LCD_Controller_StateMachine.v SCANNER TYPE verilog)
add_file_target(FILE r512x32_2048x8.v SCANNER TYPE verilog)
add_file_target(FILE ram_blk.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Interrupt_Control.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Registers.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Rx_FIFO.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Rx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_FIFO.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design7-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_QL_Reserved.v AL4S3B_FPGA_Registers.v f512x18_512x18.v f512x36_512x36.v f512x9_512x9.v fifo_blk.v i2c_master_bit_ctrl.v i2c_master_byte_ctrl.v i2c_master_defines.v i2c_master_top.v I2C_Master_w_CmdQueue.v I2C_Master_w_CmdQueue_Registers_dma.v I2C_Master_w_CmdQueue_StateMachine.v I2C_Master_w_CmdQueue_Top.v I2C_Master_w_CmdQueue_Tx_FIFO.v I2C_Master_w_DMA.v I2C_Master_w_DMA_Registers.v I2C_Master_w_DMA_StateMachine.v LCD_controller_registers.v LCD_Controller_StateMachine.v r512x32_2048x8.v ram_blk.v UART_16550.v UART_16550_Interrupt_Control.v UART_16550_Registers.v UART_16550_Rx_FIFO.v UART_16550_Rx_Logic.v UART_16550_Tx_FIFO.v UART_16550_Tx_Logic.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design7-ql-chandalar
)

add_openocd_output(
  PARENT design7-ql-chandalar
)

# FIXME: Temporarily disable due to not enough resources after packing
#add_dependencies(all_ql_tests design7-ql-chandalar_bit)
#add_dependencies(all_ql_tests design7-ql-chandalar_jlink)
#add_dependencies(all_ql_tests design7-ql-chandalar_openocd)

