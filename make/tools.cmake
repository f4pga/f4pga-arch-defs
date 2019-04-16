function(DIFF)
  # ~~~
  # DIFF(
  # NAME
  # GOLDEN
  # ACTUAL
  # )
  set(oneValueArgs NAME GOLDEN ACTUAL)
  cmake_parse_arguments(
    DIFF
    ""
    "${oneValueArgs}"
    ""
    ${ARGN}
    )

  set(DIFF_FILE_A ${DIFF_GOLDEN})
  set(DIFF_FILE_B ${DIFF_ACTUAL})

  append_file_dependency(DIFF_FILE_A_DEP ${DIFF_FILE_A})
  append_file_dependency(DIFF_FILE_B_DEP ${DIFF_FILE_B})
  get_file_location(DIFF_FILE_A_LOCATION ${DIFF_FILE_A})
  get_file_location(DIFF_FILE_B_LOCATION ${DIFF_FILE_B})

  set(DIFF_OUTPUT ${DIFF_NAME}.diff)
  add_custom_command(
    OUTPUT ${DIFF_OUTPUT}
    DEPENDS
      ${DIFF_FILE_A_LOCATION}
      ${DIFF_FILE_A_DEP}
      ${DIFF_FILE_B_LOCATION}
      ${DIFF_FILE_B_DEP}
    COMMAND
      diff -u ${DIFF_FILE_A_LOCATION} ${DIFF_FILE_B_LOCATION} > ${DIFF_OUTPUT} || true
    COMMAND
      diff -u ${DIFF_FILE_A_LOCATION} ${DIFF_FILE_B_LOCATION}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
  add_file_target(FILE ${DIFF_OUTPUT} GENERATED)
  add_custom_target(
    ${DIFF_NAME}
    DEPENDS ${DIFF_OUTPUT}
  )
endfunction(DIFF)
