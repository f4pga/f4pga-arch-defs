set(MULT_8BIT ${QL_DESIGNS_DIR}/multiplier_8bit/multiplier_8bit.v)
set(QLF_K4N8_UMC22 qlf_k4n8-qlf_k4n8_umc22_fast)
set(MULT_TB ${CMAKE_CURRENT_SOURCE_DIR}/multiplier_8bit_tb.v)

set(CELLS_SIM ${CMAKE_CURRENT_SOURCE_DIR}/../../../techmap/cells_sim.v)
set(POST_SYNTH_FILE ${CMAKE_CURRENT_BINARY_DIR}/multiplier_8bit_test4-umc22-adder/qlf_k4n8-${QLF_K4N8_UMC22}-virt-${QLF_K4N8_UMC22}-${QLF_K4N8_UMC22}/multiplier_8bit_post_synthesis.v)

add_fpga_target(
  NAME multiplier_8bit_test4-umc22-adder
  TOP multiplier_8bit
  BOARD qlf_k4n8-qlf_k4n8_umc22_fast_board
  SOURCES ${MULT_8BIT}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder post_synthesis_comb)

add_custom_target(
  post_synthesis_comb
  COMMAND ${IVERILOG} -v -gspecify -o multiplier_8bit.vvp ${MULT_TB} ${POST_SYNTH_FILE} ${CELLS_SIM}
  DEPENDS ${IVERILOG}
  COMMAND ${VVP} -v multiplier_8bit.vvp -sdf-verbose | egrep -q "PASS"
  DEPENDS ${VVP}
  DEPENDS multiplier_8bit_test4-umc22-adder_analysis
  )
