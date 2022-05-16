set(AND2_L ${QL_DESIGNS_DIR}/and2_latch/and2_latch.v)
#add_file_target(FILE ${CURR_DIR}/and2_latch.v SCANNER_TYPE verilog)
set(QLF_K4N8_UMC22 qlf_k4n8-qlf_k4n8_umc22_fast)
set(ROUTE_LOG ${CMAKE_CURRENT_BINARY_DIR}/and2_latch_test2-umc22-adder/qlf_k4n8-${QLF_K4N8_UMC22}-virt-${QLF_K4N8_UMC22}-${QLF_K4N8_UMC22}/route.log)

add_fpga_target(
  NAME and2_latch_test2-umc22-adder
  TOP and2_latch
  BOARD qlf_k4n8-qlf_k4n8_umc22_fast_board
  SOURCES ${AND2_L}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    fast_corner)

add_custom_target(
  fast_corner
  COMMAND egrep -q -i "qlf_k4n8-qlf_k4n8_umc22_fast.arch.xml" ${ROUTE_LOG} 
  DEPENDS and2_latch_test2-umc22-adder_route
  )
