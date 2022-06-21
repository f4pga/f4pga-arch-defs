set(DESIGN_DIR ${QL_DESIGNS_DIR}/design8)

add_fpga_target(
  NAME design8-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_Fabric_Top.v
    ${DESIGN_DIR}/AL4S3B_Fabric_IP.v
    ${DESIGN_DIR}/AL4S3B_Fabric_Registers.v
    ${DESIGN_DIR}/AL4S3B_Fabric_QL_Reserved.v
    ${DESIGN_DIR}/in_vga_wrapper_Top.v
    ${DESIGN_DIR}/vga_frame_capture.v
    ${DESIGN_DIR}/vga_rx_reg.v
    ${DESIGN_DIR}/vga_rx_fifo_interface.v
    ${DESIGN_DIR}/vga_rx_dma_ctrl.v
    ${DESIGN_DIR}/UART_16550.v
    ${DESIGN_DIR}/UART_16550_Tx_Logic.v
    ${DESIGN_DIR}/UART_16550_Rx_Logic.v
    ${DESIGN_DIR}/UART_16550_Registers.v
    ${DESIGN_DIR}/UART_16550_Interrupt_Control.v
    ${DESIGN_DIR}/UART_16550_Tx_FIFO.v
    ${DESIGN_DIR}/UART_16550_Rx_FIFO.v
    ${DESIGN_DIR}/f512x16_512x16.v
    ${DESIGN_DIR}/f512x8_512x8.v
    ${DESIGN_DIR}/af1024x16_1024x16.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design8-ql-chandalar
)

add_openocd_output(
  PARENT design8-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design8-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design8-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design8-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design8-ql-chandalar_openocd)

