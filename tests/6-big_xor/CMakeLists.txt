add_file_target(FILE big_xor.v)

add_simple_test(
  NAME 6-big_xor
  SOURCES big_xor.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 6-big_xor
  SOURCES big_xor.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)

