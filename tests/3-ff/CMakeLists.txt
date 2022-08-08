add_simple_test(
  NAME 3-ff
  SOURCES ff.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${f4pga-arch-defs_SOURCE_DIR}/common/yosys/equiv_simple_clk2fflogic.ys
  )

