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

  get_file_target(DIFF_FILE_A_TARGET ${DIFF_FILE_A})
  get_file_target(DIFF_FILE_B_TARGET ${DIFF_FILE_B})
  get_file_location(DIFF_FILE_A_LOCATION ${DIFF_FILE_A})
  get_file_location(DIFF_FILE_B_LOCATION ${DIFF_FILE_B})

  set(DIFF_OUTPUT ${DIFF_NAME}.diff)
  add_custom_command(
    OUTPUT ${DIFF_OUTPUT}
    DEPENDS
      ${DIFF_FILE_A_LOCATION}
      ${DIFF_FILE_A_TARGET}
      ${DIFF_FILE_B_LOCATION}
      ${DIFF_FILE_B_TARGET}
    COMMAND
      diff -u ${DIFF_FILE_A_LOCATION} ${DIFF_FILE_B_LOCATION} > ${DIFF_OUTPUT} || true
    COMMAND
      diff -u ${DIFF_FILE_A_LOCATION} ${DIFF_FILE_B_LOCATION}
  )
  add_file_target(FILE ${DIFF_OUTPUT} GENERATED)
  add_custom_target(
    ${DIFF_NAME}
    DEPENDS ${DIFF_OUTPUT}
  )
endfunction(DIFF)
