add_file_target(FILE lut_cascade_1.v)

add_simple_test(
  NAME 5-lut_cascade_1
  SOURCES lut_cascade_1.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 5-lut_cascade_1
  SOURCES lut_cascade_1.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)
