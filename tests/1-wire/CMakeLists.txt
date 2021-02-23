add_file_target(FILE wire.v)

add_simple_test(
  NAME 1-wire
  SOURCES wire.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 1-wire
  SOURCES wire.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)

