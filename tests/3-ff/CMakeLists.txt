add_file_target(FILE ff.v)

add_simple_test(
  NAME 3-ff
  SOURCES ff.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/common/yosys/equiv_simple_clk2fflogic.ys
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 3-ff
  SOURCES ff.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/common/yosys/equiv_simple_clk2fflogic.ys
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)
