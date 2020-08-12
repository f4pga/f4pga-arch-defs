add_file_target(FILE Simon_bit_serial_top_module.v SCANNER_TYPE verilog)
add_file_target(FILE Simon_bit_serial_datapath_FPGA.v SCANNER_TYPE verilog)
add_file_target(FILE Simon_bit_serial_key_expansion_FPGA.v SCANNER_TYPE verilog)
add_file_target(FILE Simon_bit_serial_tb.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME simon-bit-serial-ql-chandalar
  BOARD chandalar
  SOURCES Simon_bit_serial_top_module.v Simon_bit_serial_datapath_FPGA.v Simon_bit_serial_key_expansion_FPGA.v
  TESTBENCH_SOURCES Simon_bit_serial_tb.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT simon-bit-serial-ql-chandalar
)

add_dependencies(all_ql_tests simon-bit-serial-ql-chandalar_bit)
add_dependencies(all_ql_tests simon-bit-serial-ql-chandalar_jlink)
add_dependencies(all_quick_tests simon-bit-serial-ql-chandalar_analysis)
add_dependencies(all_quick_tests testbench_simon-bit-serial_tb)
