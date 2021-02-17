add_file_target(FILE af512x9_512x9.v SCANNER_TYPE verilog)
add_file_target(FILE cmd_control.v SCANNER_TYPE verilog)
add_file_target(FILE crc7.v SCANNER_TYPE verilog)
add_file_target(FILE crc16.v SCANNER_TYPE verilog)
add_file_target(FILE dat_control.v SCANNER_TYPE verilog)
add_file_target(FILE dat_fifo.v SCANNER_TYPE verilog)
add_file_target(FILE dat0_line.v SCANNER_TYPE verilog)
add_file_target(FILE dat1_line.v SCANNER_TYPE verilog)
add_file_target(FILE dat23_line.v SCANNER_TYPE verilog)
add_file_target(FILE dat123_line.v SCANNER_TYPE verilog)
add_file_target(FILE function1.v SCANNER_TYPE verilog)
add_file_target(FILE function2.v SCANNER_TYPE verilog)
add_file_target(FILE registers.v SCANNER_TYPE verilog)
add_file_target(FILE spi_cmd_datin_line.v SCANNER_TYPE verilog)
add_file_target(FILE spi_crc16.v SCANNER_TYPE verilog)
add_file_target(FILE spi_dat_control.v SCANNER_TYPE verilog)
add_file_target(FILE sync.v SCANNER_TYPE verilog)
add_file_target(FILE sdio_client_top.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME sdio_client_top-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cmd_control.v  dat0_line.v    dat23_line.v   function1.v  sdio_client_top.v  spi_dat_control.v crc16.v  dat123_line.v  dat_control.v  function2.v  spi_cmd_datin_line.v  sync.v af512x9_512x9.v  crc7.v  dat1_line.v    dat_fifo.v     registers.v  spi_crc16.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME sdio_client_top-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cmd_control.v  dat0_line.v dat23_line.v function1.v  sdio_client_top.v  spi_dat_control.v crc16.v  dat123_line.v  dat_control.v  function2.v  spi_cmd_datin_line.v  sync.v af512x9_512x9.v  crc7.v  dat1_line.v    dat_fifo.v     registers.v  spi_crc16.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder sdio_client_top-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    sdio_client_top-ql-openfpga-k4_N8-adder_route)
