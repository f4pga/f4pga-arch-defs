add_simple_test(
  NAME 3-ff
  SOURCES ff.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/yosys/equiv_simple_clk2fflogic.ys
  )

