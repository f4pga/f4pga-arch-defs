set(CURR_DIR ${QL_DESIGNS_DIR}/sdio_client_top)
add_file_target(FILE ${CURR_DIR}/af512x9_512x9.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/cmd_control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/crc16.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/crc7.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat0_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat123_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat1_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat23_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat_control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/dat_fifo.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/function1.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/function2.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/registers.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/sdio_client_top.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/spi_cmd_datin_line.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/spi_crc16.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/spi_dat_control.v SCANNER_TYPE verilog)
add_file_target(FILE ${CURR_DIR}/sync.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME sdio_client_top_test-umc22-no-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/af512x9_512x9.v ${CURR_DIR}/cmd_control.v ${CURR_DIR}/crc16.v ${CURR_DIR}/crc7.v ${CURR_DIR}/dat0_line.v ${CURR_DIR}/dat123_line.v ${CURR_DIR}/dat1_line.v ${CURR_DIR}/dat23_line.v ${CURR_DIR}/dat_control.v ${CURR_DIR}/dat_fifo.v ${CURR_DIR}/function1.v ${CURR_DIR}/function2.v ${CURR_DIR}/registers.v ${CURR_DIR}/sdio_client_top.v ${CURR_DIR}/spi_cmd_datin_line.v ${CURR_DIR}/spi_crc16.v ${CURR_DIR}/spi_dat_control.v ${CURR_DIR}/sync.v 
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME sdio_client_top_test-umc22-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${CURR_DIR}/af512x9_512x9.v ${CURR_DIR}/cmd_control.v ${CURR_DIR}/crc16.v ${CURR_DIR}/crc7.v ${CURR_DIR}/dat0_line.v ${CURR_DIR}/dat123_line.v ${CURR_DIR}/dat1_line.v ${CURR_DIR}/dat23_line.v ${CURR_DIR}/dat_control.v ${CURR_DIR}/dat_fifo.v ${CURR_DIR}/function1.v ${CURR_DIR}/function2.v ${CURR_DIR}/registers.v ${CURR_DIR}/sdio_client_top.v ${CURR_DIR}/spi_cmd_datin_line.v ${CURR_DIR}/spi_crc16.v ${CURR_DIR}/spi_dat_control.v ${CURR_DIR}/sync.v 
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder sdio_client_top_test-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    sdio_client_top_test-umc22-adder_bit)
