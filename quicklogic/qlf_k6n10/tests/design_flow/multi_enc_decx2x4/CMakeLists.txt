set(DECODER 		${QL_DESIGNS_DIR}/multi_enc_decx2x4/decoder.v)
set(ENCODER 		${QL_DESIGNS_DIR}/multi_enc_decx2x4/encoder.v)
set(TOPENC_DECX2 	${QL_DESIGNS_DIR}/multi_enc_decx2x4/topenc_decx2.v)
set(MULTI_ENC_DECX2X4 	${QL_DESIGNS_DIR}/multi_enc_decx2x4/multi_enc_decx2x4.v)

add_file_target(FILE ${DECODER} SCANNER_TYPE verilog)
add_file_target(FILE ${ENCODER} SCANNER_TYPE verilog)
add_file_target(FILE ${TOPENC_DECX2} SCANNER_TYPE verilog)
add_file_target(FILE ${MULTI_ENC_DECX2X4} SCANNER_TYPE verilog)

add_fpga_target(
  NAME multi_enc_decx2x4-gf12-no-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  TOP multi_enc_decx2x4
  SOURCES 	${DECODER}
		${ENCODER}
		${TOPENC_DECX2}
		${MULTI_ENC_DECX2X4}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME multi_enc_decx2x4-gf12-adder
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  TOP multi_enc_decx2x4
  SOURCES 	${DECODER}
 		${ENCODER}
		${TOPENC_DECX2}
		${MULTI_ENC_DECX2X4}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k6n10_tests_no_adder multi_enc_decx2x4-gf12-no-adder_route)
add_dependencies(all_qlf_k6n10_tests_adder    multi_enc_decx2x4-gf12-adder_route)
