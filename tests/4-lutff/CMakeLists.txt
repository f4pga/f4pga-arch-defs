add_simple_test(
  NAME 4-lutff
  SOURCES lutff.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/yosys/equiv_simple_clk2fflogic.ys
  )
