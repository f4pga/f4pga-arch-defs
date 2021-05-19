set(IO_TC1 ${QL_DESIGNS_DIR}/io_tc1/io_tc1.v)
set(IO_TC1_DEMUX ${QL_DESIGNS_DIR}/io_tc1/demux.v)
set(IO_TC1_MUX ${QL_DESIGNS_DIR}/io_tc1/mux.v)

add_file_target(FILE ${IO_TC1} SCANNER_TYPE verilog)
add_file_target(FILE ${IO_TC1_DEMUX} SCANNER_TYPE verilog)
add_file_target(FILE ${IO_TC1_MUX} SCANNER_TYPE verilog)

add_fpga_target(
  NAME io_tc1_test-umc22-adder
  TOP io_tc1
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES ${IO_TC1} ${IO_TC1_DEMUX} ${IO_TC1_MUX}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    io_tc1_test-umc22-adder_bit)
