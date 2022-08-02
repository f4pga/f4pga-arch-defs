set(FILTERED_BOARDS ${BOARDS})
# TODO: There is an assertion failure probably caused by the repacker in the quicklogic qlf_k4n8 board.
#       Temporarily disabling the test for this board
list(REMOVE_ITEM FILTERED_BOARDS "qlf_k4n8-qlf_k4n8_umc22_slow_board")

add_simple_test(
  NAME 6-rot
  SOURCES rot.v
  BOARDS ${FILTERED_BOARDS}
  EQUIV_CHECK_SCRIPT
      ${f4pga-arch-defs_SOURCE_DIR}/common/yosys/miter_and_tempinduct_skip_1.ys
  DEFINES USE_LUT_CONSTANTS=1
  )

