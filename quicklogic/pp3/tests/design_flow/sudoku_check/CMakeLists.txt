set(DESIGN_DIR ${QL_DESIGNS_DIR}/sudoku_check)

add_fpga_target(
  NAME sudoku_check-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/fifo.v
    ${DESIGN_DIR}/pll.v
    ${DESIGN_DIR}/puz_bank3.v
    ${DESIGN_DIR}/sudoku.v
    ${DESIGN_DIR}/sudoku_ans.v
    ${DESIGN_DIR}/sudoku_bin2hex.v
    ${DESIGN_DIR}/sudoku_check.v
    ${DESIGN_DIR}/sudoku_core.v
    ${DESIGN_DIR}/sudoku_hex2bin.v
    ${DESIGN_DIR}/sudoku_mask.v
    ${DESIGN_DIR}/sudoku_mask_stg2.v
    ${DESIGN_DIR}/sudoku_partials.v
    ${DESIGN_DIR}/sudoku_solution.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT sudoku_check-ql-chandalar
)

add_openocd_output(
  PARENT sudoku_check-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  sudoku_check-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  sudoku_check-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   sudoku_check-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v sudoku_check-ql-chandalar_bit_v)

add_dependencies(sudoku_check-ql-chandalar_analysis sudoku_check-ql-chandalar_bit_v)
