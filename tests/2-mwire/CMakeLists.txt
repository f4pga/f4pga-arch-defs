add_file_target(FILE mwire.v)

add_simple_test(
  NAME 2-mwire
  SOURCES mwire.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 2-mwire
  SOURCES mwire.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
)
