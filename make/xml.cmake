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
  #
  # This function provides targets to sort the XML file in input according to the `xmlsrot.xsl` script.
  # It appends all the dependencies necessary to produce the desired OUTPUT (e.g. verilog to XML translation through the tools).
  #
  # NAME is used to give a name to the target.
  # FILE is the input file that needs to be processed by xmlsort
  # OUTPUT is the name of the output file

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
  set(DEPS "")
  append_file_dependency(DEPS ${XML_SORT_FILE})

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
      ${XSLTPROC}
      --nomkdir
      --nonet
      --xinclude
      --output ${CMAKE_CURRENT_BINARY_DIR}/${XML_SORT_OUTPUT}
      ${XML_SORT_XSL}
      ${XML_SORT_INPUT_LOCATION}
  )
  add_file_target(FILE ${XML_SORT_OUTPUT} GENERATED)
  add_custom_target(
    ${XML_SORT_NAME}
    DEPENDS ${XML_SORT_OUTPUT}
  )
endfunction(XML_SORT)
