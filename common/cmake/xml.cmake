function(XML_LINT)
  # ~~~
  # XML_LINT(
  # NAME
  # FILE
  # LINT_OUTPUT
  # SCHEMA
  # )
  set(options)
  set(oneValueArgs NAME FILE LINT_OUTPUT SCHEMA)
  set(multiValueArgs)
  cmake_parse_arguments(
    XML_LINT
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  get_target_property_required(XMLLINT env XMLLINT)

  # For xmllint we use head to shortcircuit failure as it can take a
  # very long time to output all of the errors
  add_custom_command(
    OUTPUT ${XML_LINT_LINT_OUTPUT}
    DEPENDS ${XML_LINT_FILE} ${XML_LINT_SCHEMA} ${XMLLINT}
    COMMAND bash -c
    '${XMLLINT}
    --output ${XML_LINT_LINT_OUTPUT}
    --schema ${XML_LINT_SCHEMA}
    ${XML_LINT_FILE} 2>&1 |  head -n10 && exit "$$\{PIPESTATUS[0]\}" '
    )

  get_rel_target(REL_XML_LINT_NAME lint ${XML_LINT_NAME})
  add_custom_target(
    ${REL_XML_LINT_NAME}
    DEPENDS ${XML_LINT_LINT_OUTPUT}
    )
  add_dependencies(all_xml_lint ${REL_XML_LINT_NAME})

endfunction(XML_LINT)

function(XML_CANONICALIZE_MERGE)
  # ~~~
  # XML_CANONICALIZE_MERGE(
  # NAME
  # FILE
  # OUTPUT
  # {EXTRA_ARGUMENTS}
  # )
  #
  # This function provides targets to sort the XML file in input according to the `convert_and_merge_composable_fpga_architecture.xsl` script.
  # It appends all the dependencies necessary to produce the desired OUTPUT (e.g. verilog to XML translation through the tools).
  #
  # NAME is used to give a name to the target.
  # FILE is the input file that needs to be processed by xsl script.
  # OUTPUT is the name of the output file
  # EXTRA_ARGUMENTS is the extra arguments to give to xsltproc when running the xsl script.

  set(options)
  set(oneValueArgs NAME FILE OUTPUT)
  set(multiValueArgs EXTRA_ARGUMENTS)
  cmake_parse_arguments(
    XML_CANONICALIZE_MERGE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  set(DEPS "")
  append_file_dependency(DEPS ${XML_CANONICALIZE_MERGE_FILE})

  add_custom_command(
    OUTPUT ${XML_CANONICALIZE_MERGE_OUTPUT}
    DEPENDS
      ${DEPS}
      ${PYTHON3}
    COMMAND
      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/third_party/vtr-xml-utils/:${PYTHONPATH}
      ${PYTHON3} -m vtr_xml_utils
        ${XML_CANONICALIZE_MERGE_FILE}
        -o ${CMAKE_CURRENT_BINARY_DIR}/${XML_CANONICALIZE_MERGE_OUTPUT}
  )

  add_file_target(FILE ${XML_CANONICALIZE_MERGE_OUTPUT} GENERATED)

  get_rel_target(REL_XML_CANONICALIZE_MERGE_FILE merge ${XML_CANONICALIZE_MERGE_FILE})
  add_custom_target(
    ${REL_XML_CANONICALIZE_MERGE_FILE}
    DEPENDS ${XML_CANONICALIZE_MERGE_OUTPUT}
    )
endfunction(XML_CANONICALIZE_MERGE)
