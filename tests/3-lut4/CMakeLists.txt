add_file_target(FILE lut4.v)

add_simple_test(
  NAME 3-lut4
  SOURCES lut4.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 3-lut4
  SOURCES lut4.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)
