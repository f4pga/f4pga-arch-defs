set(CURR_DIR ${QL_DESIGNS_DIR}/e_sdio_host_controller)

add_file_target(FILE ${CURR_DIR}/af256x18_512x9.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/af512x9_256x18.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/bipadoff_pp.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_Card_Detect.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_clock_mng_pp.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_cmd_control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_crc16.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_dat0_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_dat123_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_dat_control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_registers.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_rx_fifo.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_sdio_host_controller.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_sync.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/e_tx_fifo.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/pp_dcntx8.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/quad_buff.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/r256x18_256x18.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME e_sdio_host_controller_test-umc22-no-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/af256x18_512x9.v
    ${CURR_DIR}/af512x9_256x18.v
    ${CURR_DIR}/bipadoff_pp.v
    ${CURR_DIR}/e_Card_Detect.v
    ${CURR_DIR}/e_clock_mng_pp.v
    ${CURR_DIR}/e_cmd_control.v
    ${CURR_DIR}/e_crc16.v
    ${CURR_DIR}/e_dat0_line.v
    ${CURR_DIR}/e_dat123_line.v
    ${CURR_DIR}/e_dat_control.v
    ${CURR_DIR}/e_registers.v
    ${CURR_DIR}/e_rx_fifo.v
    ${CURR_DIR}/e_sdio_host_controller.v
    ${CURR_DIR}/e_sync.v
    ${CURR_DIR}/e_tx_fifo.v
    ${CURR_DIR}/pp_dcntx8.v
    ${CURR_DIR}/quad_buff.v
    ${CURR_DIR}/r256x18_256x18.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME e_sdio_host_controller_test-umc22-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES
    ${CURR_DIR}/af256x18_512x9.v
    ${CURR_DIR}/af512x9_256x18.v
    ${CURR_DIR}/bipadoff_pp.v
    ${CURR_DIR}/e_Card_Detect.v
    ${CURR_DIR}/e_clock_mng_pp.v
    ${CURR_DIR}/e_cmd_control.v
    ${CURR_DIR}/e_crc16.v
    ${CURR_DIR}/e_dat0_line.v
    ${CURR_DIR}/e_dat123_line.v
    ${CURR_DIR}/e_dat_control.v
    ${CURR_DIR}/e_registers.v
    ${CURR_DIR}/e_rx_fifo.v
    ${CURR_DIR}/e_sdio_host_controller.v
    ${CURR_DIR}/e_sync.v
    ${CURR_DIR}/e_tx_fifo.v
    ${CURR_DIR}/pp_dcntx8.v
    ${CURR_DIR}/quad_buff.v
    ${CURR_DIR}/r256x18_256x18.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder e_sdio_host_controller_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    e_sdio_host_controller_test-umc22-adder_bit)
