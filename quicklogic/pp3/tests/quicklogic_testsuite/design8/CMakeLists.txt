add_file_target(FILE fifo_blk.v SCANNER TYPE verilog)
add_file_target(FILE af1024x16_1024x16.v SCANNER TYPE verilog)
add_file_target(FILE f512x18_512x9.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_Rx_FIFOs.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Interrupt_Control.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Registers.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Rx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550.v SCANNER TYPE verilog)
add_file_target(FILE vga_rx_dma_ctrl.v SCANNER TYPE verilog)
add_file_target(FILE vga_rx_fifo_interface.v SCANNER TYPE verilog)
add_file_target(FILE vga_rx_reg.v SCANNER TYPE verilog)
add_file_target(FILE vga_frame_capture.v SCANNER TYPE verilog)
add_file_target(FILE in_vga_wrapper_Top.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_Fabric_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_Fabric_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_Fabric_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_Fabric_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design8-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_Fabric_Top.v AL4S3B_Fabric_IP.v AL4S3B_Fabric_Registers.v AL4S3B_Fabric_QL_Reserved.v in_vga_wrapper_Top.v vga_frame_capture.v vga_rx_reg.v vga_rx_fifo_interface.v vga_rx_dma_ctrl.v UART_16550.v UART_16550_Tx_Logic.v UART_16550_Rx_Logic.v UART_16550_Registers.v UART_16550_Interrupt_Control.v UART_16550_Tx_Rx_FIFOs.v f512x18_512x9.v af1024x16_1024x16.v fifo_blk.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design8-ql-chandalar
)

add_dependencies(all_ql_tests design8-ql-chandalar_bit)
add_dependencies(all_ql_tests design8-ql-chandalar_jlink)

