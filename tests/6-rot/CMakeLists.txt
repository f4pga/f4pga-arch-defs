add_file_target(FILE rot.v)

add_simple_test(
  NAME 6-rot
  SOURCES rot.v
  BOARDS ${BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/common/yosys/miter_and_tempinduct_skip_1.ys
  DEFINES USE_LUT_CONSTANTS=1
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 6-rot
  SOURCES rot.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/common/yosys/miter_and_tempinduct_skip_1.ys
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)

