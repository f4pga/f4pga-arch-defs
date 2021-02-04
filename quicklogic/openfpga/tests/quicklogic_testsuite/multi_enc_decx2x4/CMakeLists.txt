add_file_target(FILE decoder.v SCANNER_TYPE verilog)
add_file_target(FILE encoder.v SCANNER_TYPE verilog)
add_file_target(FILE topenc_decx2.v SCANNER_TYPE verilog)
add_file_target(FILE multi_enc_decx2x4.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME multi_enc_decx2x4-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES decoder.v encoder.v topenc_decx2.v multi_enc_decx2x4.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME multi_enc_decx2x4-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES decoder.v encoder.v topenc_decx2.v multi_enc_decx2x4.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder multi_enc_decx2x4-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    multi_enc_decx2x4-ql-openfpga-k4_N8-adder_route)
