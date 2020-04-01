add_file_target(FILE defines.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_fsm.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_len_gen.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_levels.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_run_befores.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_total_coeffs.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_read_total_zeros.v SCANNER_TYPE verilog)
add_file_target(FILE cavlc_top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME cavlc-ql-chandalar
  BOARD chandalar
  SOURCES cavlc_fsm.v  cavlc_len_gen.v  cavlc_read_levels.v  cavlc_read_run_befores.v  cavlc_read_total_coeffs.v  cavlc_read_total_zeros.v  cavlc_top.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT cavlc-ql-chandalar
)

add_dependencies(all_ql_tests cavlc-ql-chandalar_bit)
add_dependencies(all_ql_tests cavlc-ql-chandalar_jlink)

