set(DESIGN_DIR ${QL_DESIGNS_DIR}/design1)

add_fpga_target(
  NAME design1-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/Serializer_Deserializer.v
    ${DESIGN_DIR}/Serializer_Deserializer_Test.v
    ${DESIGN_DIR}/Fsm_Top.v
    ${DESIGN_DIR}/Dma_Ctrl.v
    ${DESIGN_DIR}/UART_16550.v
    ${DESIGN_DIR}/UART_16550_Tx_Logic.v
    ${DESIGN_DIR}/UART_16550_Rx_Logic.v
    ${DESIGN_DIR}/UART_16550_Registers.v
    ${DESIGN_DIR}/UART_16550_Interrupt_Control.v
    ${DESIGN_DIR}/UART_16550_Tx_FIFO.v
    ${DESIGN_DIR}/UART_16550_Rx_FIFO.v
    ${DESIGN_DIR}/f512x16_512x16.v
    ${DESIGN_DIR}/f512x8_512x8.v
    ${DESIGN_DIR}/af512x32_512x32.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)

add_jlink_output(
  PARENT design1-ql-chandalar
)

add_openocd_output(
  PARENT design1-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design1-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design1-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design1-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design1-ql-chandalar_openocd)

