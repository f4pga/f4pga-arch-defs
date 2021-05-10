set(RS_DECODER_1 ${QL_DESIGNS_DIR}/rs_decoder_1/rs_decoder_1.v)

add_fpga_target(
  NAME rs_decoder-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${RS_DECODER_1}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME rs_decoder-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${RS_DECODER_1}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder rs_decoder-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    rs_decoder-gf12-adder_route)
