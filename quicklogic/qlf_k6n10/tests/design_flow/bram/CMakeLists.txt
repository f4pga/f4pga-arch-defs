# Test the routing of Block RAM in different write modes.

set(BRAM ${QL_DESIGNS_DIR}/bram/bram.v)

add_file_target(FILE ${BRAM} SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram-gf12-mode0
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BRAM}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES TOP=BRAM_32x512
)

add_fpga_target(
  NAME bram-gf12-mode1
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BRAM}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES TOP=BRAM_16x1024
  )



add_fpga_target(
  NAME bram-gf12-mode2
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BRAM}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES TOP=BRAM_8x2048
  )

add_fpga_target(
  NAME bram-gf12-mode3
  BOARD qlf_k6n10-qlf_k6n10_gf12_board
  SOURCES ${BRAM}
  EXPLICIT_ADD_FILE_TARGET
  DEFINES TOP=BRAM_4x4096
  )

add_dependencies(all_qlf_k6n10_tests_adder    bram-gf12-mode0_route)
add_dependencies(all_qlf_k6n10_tests_adder    bram-gf12-mode1_route)
add_dependencies(all_qlf_k6n10_tests_adder    bram-gf12-mode2_route)
add_dependencies(all_qlf_k6n10_tests_adder    bram-gf12-mode3_route)
