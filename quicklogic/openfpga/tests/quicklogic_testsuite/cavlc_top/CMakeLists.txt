add_file_target(FILE defines.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_fsm.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_len_gen.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_levels.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_run_befores.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_total_coeffs.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_total_zeros.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME cavlc_top-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cavlc_fsm.v  cavlc_len_gen.v  cavlc_read_levels.v  cavlc_read_run_befores.v  cavlc_read_total_coeffs.v  cavlc_read_total_zeros.v  cavlc_top.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME cavlc_top-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES cavlc_fsm.v  cavlc_len_gen.v  cavlc_read_levels.v  cavlc_read_run_befores.v  cavlc_read_total_coeffs.v  cavlc_read_total_zeros.v  cavlc_top.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder cavlc_top-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    cavlc_top-ql-openfpga-k4_N8-adder_route)
