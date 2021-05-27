set(COUNTER_16BIT ${QL_DESIGNS_DIR}/counter_16bit/counter_16bit.v)
set(QLF_K4N8_UMC22 qlf_k4n8-qlf_k4n8_umc22_slow)
set(COUNTER_TB ${CMAKE_CURRENT_SOURCE_DIR}/counter_16bit_tb.v)

set(CELLS_SIM ${CMAKE_CURRENT_SOURCE_DIR}/../../../techmap/cells_sim.v)
set(POST_SYNTH_FILE ${CMAKE_CURRENT_BINARY_DIR}/counter_16bit_test4-umc22-adder/qlf_k4n8-${QLF_K4N8_UMC22}-virt-${QLF_K4N8_UMC22}-${QLF_K4N8_UMC22}/top_post_synthesis.v)

add_fpga_target(
  NAME counter_16bit_test4-umc22-adder
  TOP top
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${COUNTER_16BIT}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder post_synthesis_seq)

add_custom_target(
  post_synthesis_seq
  COMMAND ${IVERILOG} -v -gspecify -o counter_16bit.vvp ${COUNTER_TB} ${POST_SYNTH_FILE} ${CELLS_SIM}
  DEPENDS ${IVERILOG}
  COMMAND ${VVP} -v counter_16bit.vvp | egrep -q -w "97"
  DEPENDS ${VVP}
  DEPENDS counter_16bit_test4-umc22-adder_analysis
  )
