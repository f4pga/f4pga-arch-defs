set(MAC_16 ${QL_DESIGNS_DIR}/mac_16/mac_16.v)

add_file_target(FILE ${MAC_16} SCANNER_TYPE verilog)

add_fpga_target(
  NAME mac_16-gf12-dsp
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES  ${MAC_16}
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME mac_16-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES  ${MAC_16}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_dsp
  )

add_dependencies(all_qlf_k6n10_tests_no_adder mac_16-gf12-dsp_route)
add_dependencies(all_qlf_k6n10_tests_adder    mac_16-gf12-adder_route)
