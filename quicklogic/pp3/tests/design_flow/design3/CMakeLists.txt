set(DESIGN_DIR ${QL_DESIGNS_DIR}/design3)

add_fpga_target(
  NAME design3-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/i2s_slave_w_DMA.v
    ${DESIGN_DIR}/i2s_slave_rx.v
    ${DESIGN_DIR}/i2s_slave_w_DMA_registers.v
    ${DESIGN_DIR}/i2s_slave_w_DMA_StateMachine.v
    ${DESIGN_DIR}/i2s_slave_Rx_FIFOs.v
    ${DESIGN_DIR}/deci_filter_fir128coeff.v
    ${DESIGN_DIR}/fll_acslip.v
    ${DESIGN_DIR}/r512x16_512x16.v
    ${DESIGN_DIR}/af512x16_512x16.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT design3-ql-chandalar
)

add_openocd_output(
  PARENT design3-ql-chandalar
)

add_dependencies(all_eos_s3_tests_bit  design3-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v design3-ql-chandalar_bit_v)
add_dependencies(all_eos_s3_tests_prog design3-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog design3-ql-chandalar_openocd)
