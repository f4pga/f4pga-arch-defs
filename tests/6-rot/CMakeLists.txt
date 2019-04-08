add_simple_test(
  NAME 6-rot
  SOURCES rot.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/yosys/miter_and_tempinduct_skip_1.ys
  DEFINES USE_LUT_CONSTANTS=1
  )

