add_file_target(FILE af512x16_512x16.v SCANNER_TYPE verilog)
add_file_target(FILE decoder_2x4.v SCANNER_TYPE verilog)
add_file_target(FILE decoder_3x8.v SCANNER_TYPE verilog)
add_file_target(FILE decoder_5x32.v SCANNER_TYPE verilog)
add_file_target(FILE mux2x0.v SCANNER_TYPE verilog)
add_file_target(FILE mux4x0.v SCANNER_TYPE verilog)
add_file_target(FILE mux8x0.v SCANNER_TYPE verilog)
add_file_target(FILE mux32x1.v SCANNER_TYPE verilog)
add_file_target(FILE camif.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME camif-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES af512x16_512x16.v decoder_2x4.v decoder_3x8.v decoder_5x32.v mux2x0.v mux4x0.v  mux8x0.v mux32x1.v camif.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME camif-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES af512x16_512x16.v decoder_2x4.v decoder_3x8.v decoder_5x32.v mux2x0.v mux4x0.v  mux8x0.v mux32x1.v camif.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder camif-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    camif-ql-openfpga-k4_N8-adder_route)
