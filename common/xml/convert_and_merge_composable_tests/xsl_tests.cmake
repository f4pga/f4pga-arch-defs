# Creating new target to call all the added tests
add_custom_target(all_xsl_tests ALL)

function(XSL_GOLDEN_TEST)
  # ~~~
  # XSL_GOLDEN_TEST(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test both the pb_type XML generation. It will call V2X_TEST_GENERIC multiple times first with the field TYPE set to `pb_type`
  # then with `model`
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE)
  cmake_parse_arguments(
    XSL_GOLDEN_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${XSL_GOLDEN_TEST_NAME})
  set(TOP_MODULE ${XSL_GOLDEN_TEST_TOP_MODULE})

  set(INPUT_XML ${NAME}.xml)
  add_file_target(FILE ${INPUT_XML} SCANNER_TYPE xml)

  set(ACTUAL_XML ${NAME}.actual.xml)
  xml_canonicalize_merge(NAME merge_${ACTUAL_XML} FILE ${INPUT_XML} OUTPUT ${ACTUAL_XML})

  set(GOLDEN_XML ${NAME}.golden.xml)
  add_file_target(FILE ${GOLDEN_XML} SCANNER_TYPE xml)

  diff(NAME diff_${NAME} GOLDEN ${GOLDEN_XML} ACTUAL ${ACTUAL_XML})

  add_dependencies(all_xsl_tests diff_${NAME})
endfunction(XSL_GOLDEN_TEST)
