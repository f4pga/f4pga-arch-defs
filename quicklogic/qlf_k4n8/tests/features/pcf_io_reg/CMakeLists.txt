set(CURR_DIR ${QL_DESIGNS_DIR}/io_reg)
add_file_target(FILE ${CURR_DIR}/io_reg.v SCANNER_TYPE verilog)
add_file_target(FILE io_reg.pcf)
set(QLF_K4N8_UMC22 qlf_k4n8-qlf_k4n8_umc22_slow)

set(FASM_LOG ${CMAKE_CURRENT_BINARY_DIR}/io_reg_test-umc22-adder/qlf_k4n8-${QLF_K4N8_UMC22}-virt-${QLF_K4N8_UMC22}-${QLF_K4N8_UMC22}/io_reg.fasm)

add_fpga_target(
  NAME io_reg_test-umc22-adder
  TOP io_reg
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  INPUT_IO_FILE io_reg.pcf
  SOURCES ${CURR_DIR}/io_reg.v
  EXPLICIT_ADD_FILE_TARGET
)

add_dependencies(all_qlf_k4n8_tests_adder    pcf_io_reg_verify)

add_custom_target(
  pcf_io_reg_verify
  COMMAND egrep -q -i "mem_iopad_0_clk_0.mem_out" ${FASM_LOG} 
  DEPENDS io_reg_test-umc22-adder_bit
  )

