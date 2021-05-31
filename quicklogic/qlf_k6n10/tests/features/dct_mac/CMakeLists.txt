set(DCT_MAC ${QL_DESIGNS_DIR}/dct_mac/dct_mac.v)

add_file_target(FILE ${DCT_MAC} SCANNER_TYPE verilog)

add_fpga_target(
  NAME dct_mac-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${DCT_MAC}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME dct_mac-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${DCT_MAC}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder dct_mac-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    dct_mac-gf12-adder_route)
