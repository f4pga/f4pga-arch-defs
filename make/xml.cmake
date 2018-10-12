function(XML_LINT)
  # ~~~
  # XML_LINT(
  # NAME
  # FILE
  # LINT_OUTPUT
  # SCHEMA
  # )
  set(oneValueArgs NAME FILE LINT_OUTPUT SCHEMA)
  cmake_parse_arguments(
    XML_LINT
    ""
    "${oneValueArgs}"
    ""
    ${ARGN}
    )

  get_target_property_required(XMLLINT env XMLLINT)
  get_target_property(XMLLINT_TARGET env XMLLINT_TARGET)

  # For xmllint we use head to shortcircuit failure as it can take a
  # very long time to output all of the errors
  add_custom_command(
    OUTPUT ${XML_LINT_LINT_OUTPUT}
    DEPENDS ${XML_LINT_FILE} ${XML_LINT_SCHEMA} ${XMLLINT} ${XMLLINT_TARGET}
    COMMAND bash -c
    '${XMLLINT}
    --output ${XML_LINT_LINT_OUTPUT}
    --schema ${XML_LINT_SCHEMA}
    ${XML_LINT_FILE} 2>&1 |  head -n10 && exit "$$\{PIPESTATUS[0]\}" '
    )
  add_custom_target(
    ${XML_LINT_NAME}
    DEPENDS ${XML_LINT_LINT_OUTPUT}
    )
  add_dependencies(all_xml_lint ${XML_LINT_NAME})

endfunction(XML_LINT)

function(XML_SORT)
  # ~~~
  # XML_SORT(
  # NAME
  # FILE
  # OUTPUT
  # )
  set(oneValueArgs NAME FILE OUTPUT)
  cmake_parse_arguments(
    XML_SORT
    ""
    "${oneValueArgs}"
    ""
    ${ARGN}
    )

  set(XML_SORT_XSL ${symbiflow-arch-defs_SOURCE_DIR}/common/xml/xmlsort.xsl)

  get_file_location(XML_SORT_INPUT_LOCATION ${XML_SORT_FILE})

  get_file_target(XML_SORT_INPUT_TARGET ${XML_SORT_FILE})
  get_target_property(INCLUDE_FILES ${XML_SORT_INPUT_TARGET} INCLUDE_FILES)
  append_file_dependency(DEPS ${XML_SORT_FILE})
  set(DEPS "")
  foreach(SRC ${INCLUDE_FILES})
    append_file_dependency(DEPS ${SRC})
  endforeach()

  get_target_property_required(XSLTPROC env XSLTPROC)
  get_target_property(XSLTPROC_TARGET env XSLTPROC_TARGET)

  add_custom_command(
    OUTPUT ${XML_SORT_OUTPUT}
    DEPENDS
      ${XML_SORT_XSL}
      ${XML_SORT_INPUT_LOCATION}
      ${XML_SORT_INPUT_TARGET}
      ${DEPS}
      ${XSLTPROC} ${XSLTPROC_TARGET}
    COMMAND
      ${CMAKE_COMMAND} -E make_directory
      ${CMAKE_CURRENT_BINARY_DIR}/${OUT_DEVICE_DIR}
    COMMAND
      ${XSLTPROC}
      --nomkdir
      --nonet
      --xinclude
      --output ${CMAKE_CURRENT_BINARY_DIR}/${XML_SORT_OUTPUT} ${XML_SORT_XSL} ${XML_SORT_INPUT_LOCATION}
  )
  add_file_target(FILE ${XML_SORT_OUTPUT} GENERATED)
  add_custom_target(
    ${XML_SORT_NAME}
    DEPENDS ${XML_SORT_OUTPUT}
  )
endfunction(XML_SORT)

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
