set(DESIGN_DIR ${QL_DESIGNS_DIR}/e_sdio_host_controller)

add_fpga_target(
  NAME e_sdio_host_controller-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/af256x18_512x9.v
    ${DESIGN_DIR}/af512x9_256x18.v
    ${DESIGN_DIR}/bipadoff_pp.v
    ${DESIGN_DIR}/e_Card_Detect.v
    ${DESIGN_DIR}/e_clock_mng_pp.v
    ${DESIGN_DIR}/e_cmd_control.v
    ${DESIGN_DIR}/e_crc16.v
    ${DESIGN_DIR}/e_dat0_line.v
    ${DESIGN_DIR}/e_dat123_line.v
    ${DESIGN_DIR}/e_dat_control.v
    ${DESIGN_DIR}/e_registers.v
    ${DESIGN_DIR}/e_rx_fifo.v
    ${DESIGN_DIR}/e_sdio_host_controller.v
    ${DESIGN_DIR}/e_sync.v
    ${DESIGN_DIR}/e_tx_fifo.v
    ${DESIGN_DIR}/pp_dcntx8.v
    ${DESIGN_DIR}/quad_buff.v
    ${DESIGN_DIR}/r256x18_256x18.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=2,PB-GMUX=2,PB-LOGIC<=498
)


add_jlink_output(
  PARENT e_sdio_host_controller-ql-chandalar
)

add_openocd_output(
  PARENT e_sdio_host_controller-ql-chandalar
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_prog  e_sdio_host_controller-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests_prog  e_sdio_host_controller-ql-chandalar_openocd)
#
#add_dependencies(all_eos_s3_tests_bit   e_sdio_host_controller-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_bit_v e_sdio_host_controller-ql-chandalar_bit_v)

add_dependencies(e_sdio_host_controller-ql-chandalar_analysis e_sdio_host_controller-ql-chandalar_bit_v)

#add_dependencies(all_eos_s3_tests_regression e_sdio_host_controller-ql-chandalar_assert_usage)
