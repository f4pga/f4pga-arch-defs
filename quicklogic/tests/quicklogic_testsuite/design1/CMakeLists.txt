add_file_target(FILE fifo_blk.v SCANNER TYPE verilog)
add_file_target(FILE af512x32_512x32.v SCANNER TYPE verilog)
add_file_target(FILE f512x18_512x9.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_Rx_FIFOs.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Interrupt_Control.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Registers.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Rx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550_Tx_Logic.v SCANNER TYPE verilog)
add_file_target(FILE UART_16550.v SCANNER TYPE verilog)
add_file_target(FILE Dma_Ctrl.v SCANNER TYPE verilog)
add_file_target(FILE Fsm_Top.v SCANNER TYPE verilog)
add_file_target(FILE Serializer_Deserializer_Test.v SCANNER TYPE verilog)
add_file_target(FILE Serializer_Deserializer.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_QL_Reserved.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Registers.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_IP.v SCANNER TYPE verilog)
add_file_target(FILE AL4S3B_FPGA_Top.v SCANNER TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME design1-ql-chandalar
  BOARD chandalar
  SOURCES AL4S3B_FPGA_Top.v AL4S3B_FPGA_IP.v AL4S3B_FPGA_Registers.v AL4S3B_FPGA_QL_Reserved.v Serializer_Deserializer.v Serializer_Deserializer_Test.v Fsm_Top.v Dma_Ctrl.v UART_16550.v UART_16550_Tx_Logic.v UART_16550_Rx_Logic.v UART_16550_Registers.v UART_16550_Interrupt_Control.v UART_16550_Tx_Rx_FIFOs.v f512x18_512x9.v af512x32_512x32.v fifo_blk.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design1-ql-chandalar
)

add_dependencies(all_ql_tests design1-ql-chandalar_bit)
add_dependencies(all_ql_tests design1-ql-chandalar_jlink)

