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
  # SORT_OUTPUT
  # SCHEMA
  # )
  set(oneValueArgs NAME FILE SORT_OUTPUT SCHEMA)
  cmake_parse_arguments(
    XML_SORT
    ""
    "${oneValueArgs}"
    ""
    ${ARGN}
    )

  set(XML_SORT_XSL ${symbiflow-arch-defs_SOURCE_DIR}/common/xml/xmlsort.xsl)
  set(
    XML_SORT_INPUT ${CMAKE_CURRENT_BINARY_DIR}/${XML_SORT_FILE}
  )
  get_file_target(XML_SORT_INPUT_TARGET ${XML_SORT_FILE})
  get_target_property(INCLUDE_FILES ${XML_SORT_INPUT_TARGET} INCLUDE_FILES)
  set(DEPS "")
  foreach(SRC ${INCLUDE_FILES})
    append_file_dependency(DEPS ${SRC})
  endforeach()
  set(XML_SORT_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${XML_SORT_FILE})

  get_target_property_required(XSLTPROC env XSLTPROC)
  get_target_property(XSLTPROC_TARGET env XSLTPROC_TARGET)

  add_custom_command(
    OUTPUT ${XML_SORT_OUTPUT}
    DEPENDS
      ${XML_SORT_XSL}
      ${XML_SORT_INPUT}
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
      --output ${XML_SORT_OUTPUT} ${XML_SORT_XSL} ${XML_SORT_INPUT}
  )

endfunction(XML_SORT)
