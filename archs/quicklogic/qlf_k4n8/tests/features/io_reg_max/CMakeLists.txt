set(IO_REG_MAX  ${QL_DESIGNS_DIR}/io_reg_max/io_reg_max.v)
set(IO_DEMUX  ${QL_DESIGNS_DIR}/io_reg_max/demux.v)
set(IO_MUX  ${QL_DESIGNS_DIR}/io_reg_max/mux.v)

set(QLF_K4N8_UMC22 qlf_k4n8-qlf_k4n8_umc22_slow)
set(ROUTE_LOG ${CMAKE_CURRENT_BINARY_DIR}/io_reg_max_test-umc22-adder/qlf_k4n8-${QLF_K4N8_UMC22}-virt-${QLF_K4N8_UMC22}-${QLF_K4N8_UMC22}/route.log)

add_file_target(FILE ${IO_REG_MAX} SCANNER_TYPE verilog)
add_file_target(FILE ${IO_DEMUX} SCANNER_TYPE verilog)
add_file_target(FILE ${IO_MUX} SCANNER_TYPE verilog)


add_fpga_target(
  NAME io_reg_max_test-umc22-adder
  TOP io_reg_max
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  SOURCES ${IO_REG_MAX} ${IO_DEMUX} ${IO_MUX}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder    io_reg_max_verify)

add_custom_target(
  io_reg_max_verify
  COMMAND egrep -q -i "iopad \+: 1034" ${ROUTE_LOG} 
  COMMAND egrep -q -i "fle \+: 1032" ${ROUTE_LOG}
  DEPENDS io_reg_max_test-umc22-adder_route
  )
