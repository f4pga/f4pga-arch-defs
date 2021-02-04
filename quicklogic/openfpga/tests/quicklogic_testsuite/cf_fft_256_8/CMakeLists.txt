add_file_target(FILE cf_fft_256_8.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME cf_fft_256_8-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cf_fft_256_8.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME cf_fft_256_8-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cf_fft_256_8.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder cf_fft_256_8-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    cf_fft_256_8-ql-openfpga-k4_N8-adder_route)
