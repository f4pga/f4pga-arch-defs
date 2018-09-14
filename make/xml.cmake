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

