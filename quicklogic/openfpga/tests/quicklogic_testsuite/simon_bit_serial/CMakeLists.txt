add_file_target(FILE Simon_bit_serial_datapath_FPGA.v SCANNER_TYPE verilog)
add_file_target(FILE Simon_bit_serial_key_expansion_FPGA.v SCANNER_TYPE verilog)
add_file_target(FILE Simon_bit_serial_top_module_FPGA.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME simon_bit_serial-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES Simon_bit_serial_top_module_FPGA.v Simon_bit_serial_key_expansion_FPGA.v Simon_bit_serial_datapath_FPGA.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME simon_bit_serial-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES Simon_bit_serial_top_module_FPGA.v Simon_bit_serial_key_expansion_FPGA.v Simon_bit_serial_datapath_FPGA.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder simon_bit_serial-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    simon_bit_serial-ql-openfpga-k4_N8-adder_route)
