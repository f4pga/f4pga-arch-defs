add_file_target(FILE dct.v SCANNER_TYPE verilog)
add_file_target(FILE dct_cos_table.v SCANNER_TYPE verilog)
add_file_target(FILE dct_syn.v SCANNER_TYPE verilog)
add_file_target(FILE dctu.v SCANNER_TYPE verilog)
add_file_target(FILE dctub.v SCANNER_TYPE verilog)
add_file_target(FILE fdct.v SCANNER_TYPE verilog)
add_file_target(FILE zigzag.v SCANNER_TYPE verilog)
add_file_target(FILE dct_mac.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME dct_mac-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES dct.v dct_cos_table.v dct_syn.v dctu.v dctub.v fdct.v zigzag.v dct_mac.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME dct_mac-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES dct.v dct_cos_table.v dct_syn.v dctu.v dctub.v fdct.v zigzag.v dct_mac.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder dct_mac-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    dct_mac-ql-openfpga-k4_N8-adder_route)
