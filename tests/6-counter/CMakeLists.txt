add_file_target(FILE counter.v)

add_simple_test(
  NAME 6-counter
  SOURCES counter.v
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
)

add_simple_test(
  NAME 6-counter
  SOURCES counter.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  ROUTE_ONLY
  DEFINES SYNTH_OPTS=-adder
)

