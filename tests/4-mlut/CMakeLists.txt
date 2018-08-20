add_file_target(FILE mlut.eblif)
add_simple_test(
  NAME 4-mlut
  SOURCES mlut.eblif
  BOARDS ${BOARDS}
  EXPLICIT_ADD_FILE_TARGET
  NO_SYNTHESIS
  )
