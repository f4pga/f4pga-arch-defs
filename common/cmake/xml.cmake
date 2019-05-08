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

  get_rel_target(REL_XML_LINT_NAME lint ${XML_LINT_NAME})
  add_custom_target(
    ${REL_XML_LINT_NAME}
    DEPENDS ${XML_LINT_LINT_OUTPUT}
    )
  add_dependencies(all_xml_lint ${REL_XML_LINT_NAME})

endfunction(XML_LINT)

set(XML_CANONICALIZE_MERGE_SH
  common/xml/convert_and_merge_composable_fpga_architecture.sh
  )
set(XML_CANONICALIZE_MERGE_FILES
  ${XML_CANONICALIZE_MERGE_SH}
  common/xml/identity.xsl
  common/xml/convert-port-tag.xsl
  common/xml/convert-prefix-port.xsl
  common/xml/convert-pb_type-attributes.xsl
  common/xml/pack-patterns.xsl
  common/xml/remove-duplicate-models.xsl
  common/xml/attribute-fixes.xsl
  common/xml/sort-tags.xsl
  )

set(XML_CANONICALIZE_DEPS "")
foreach(SRC ${XML_CANONICALIZE_MERGE_FILES})
  add_file_target(FILE ${SRC})
  append_file_dependency(XML_CANONICALIZE_DEPS ${SRC})
endforeach()

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

  get_target_property_required(XSLTPROC env XSLTPROC)
  get_target_property(XSLTPROC_TARGET env XSLTPROC_TARGET)

  set(DEPS "")
  append_file_dependency(DEPS ${XML_CANONICALIZE_MERGE_FILE})

  add_custom_command(
    OUTPUT ${XML_CANONICALIZE_MERGE_OUTPUT}
    DEPENDS
      ${XML_CANONICALIZE_DEPS} ${DEPS}
      ${XSLTPROC} ${XSLTPROC_TARGET}
    COMMAND
      ${CMAKE_COMMAND} -E env XSLTPROC="${XSLTPROC}" XSLTPROC_PARAMS="${XML_CANONICALIZE_MERGE_EXTRA_ARGUMENTS}"
      ${symbiflow-arch-defs_SOURCE_DIR}/${XML_CANONICALIZE_MERGE_SH}
      ${XML_CANONICALIZE_MERGE_FILE}
      > ${CMAKE_CURRENT_BINARY_DIR}/${XML_CANONICALIZE_MERGE_OUTPUT}
  )
  add_file_target(FILE ${XML_CANONICALIZE_MERGE_OUTPUT} GENERATED)

  get_rel_target(REL_XML_CANONICALIZE_MERGE_FILE merge ${XML_CANONICALIZE_MERGE_FILE})
  add_custom_target(
    ${REL_XML_CANONICALIZE_MERGE_FILE}
    DEPENDS ${XML_CANONICALIZE_MERGE_OUTPUT}
    )
endfunction(XML_CANONICALIZE_MERGE)
