# Creating new target to call all the added tests
add_custom_target(all_xsl_tests ALL)

function(XSL_GOLDEN_TEST)
  # ~~~
  # XSL_GOLDEN_TEST(
  #   NAME name
  #   )
  # ~~~
  #
  # This function is to test the xml_canonicalize_merge function which uses the
  # convert_and_merge_composable_fpga_architecture.xsl script correctly
  # transforms XML by comparing against a golden output file.
  #
  # NAME name of the test.
  #
  # Usage: xsl_golden_testl(NAME <test_name>)

  set(options "")
  set(oneValueArgs NAME)
  set(multiValueArgs "")
  cmake_parse_arguments(
    XSL_GOLDEN_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${XSL_GOLDEN_TEST_NAME})

  set(INPUT_XML ${NAME}.xml)
  add_file_target(FILE ${INPUT_XML} SCANNER_TYPE xml)

  set(ACTUAL_XML ${NAME}.actual.xml)
  xml_canonicalize_merge(
    NAME merge_${ACTUAL_XML}
    FILE ${INPUT_XML}
    OUTPUT ${ACTUAL_XML}
    EXTRA_ARGUMENTS "-param" "strip_comments" "1"
    )

  set(GOLDEN_XML ${NAME}.golden.xml)
  add_file_target(FILE ${GOLDEN_XML} SCANNER_TYPE xml)

  diff(NAME diff_${NAME} GOLDEN ${GOLDEN_XML} ACTUAL ${ACTUAL_XML})

  add_dependencies(all_xsl_tests diff_${NAME})
endfunction(XSL_GOLDEN_TEST)
