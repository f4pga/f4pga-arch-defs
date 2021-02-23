add_file_target(FILE const.v)

add_simple_test(
  NAME 0-const
  SOURCES const.v
  BOARDS ${BOARDS}
  DEFINES USE_LUT_CONSTANTS=1
  EXPLICIT_ADD_FILE_TARGET
  )

add_simple_test(
  NAME 0-const
  SOURCES const.v
  BOARDS ${QL_OPENFPGA_BOARDS}
  ROUTE_ONLY
  EXPLICIT_ADD_FILE_TARGET
  )
