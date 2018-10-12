function(V2X_TEST)
  # ~~~
  # V2X_TEST(
  #   NAME name
  #   SRC src
  #   TOP_MODULE name
  #   GOLDEN_PB_TYPE_XML file
  #   GOLDEN_MODEL_XML file
  #   )
  # ~~~
  #
  set(oneValueArgs NAME SRC TOP_MODULE GOLDEN_PB_TYPE_XML GOLDEN_MODEL_XML)
  cmake_parse_arguments(
    V2X_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  add_file_target(FILE ${V2X_TEST_SRC} SCANNER_TYPE verilog)
  v2x(NAME ${V2X_TEST_NAME} SRCS ${V2X_TEST_SRC} TOP_MODULE ${V2X_TEST_TOP_MODULE})

  # pb_type checking
  set(V2X_TEST_ACTUAL_PB_TYPE_XML ${V2X_TEST_NAME}.pb_type.xml)
  add_file_target(FILE ${V2X_TEST_GOLDEN_PB_TYPE_XML} SCANNER_TYPE xml)
  xml_sort(NAME ${V2X_TEST_NAME}_pb_type_golden_sort FILE ${V2X_TEST_GOLDEN_PB_TYPE_XML} OUTPUT ${V2X_TEST_NAME}.pb_type.golden.xml)
  xml_sort(NAME ${V2X_TEST_NAME}_pb_type_actual_sort FILE ${V2X_TEST_ACTUAL_PB_TYPE_XML} OUTPUT ${V2X_TEST_NAME}.pb_type.actual.xml)
  diff(NAME ${V2X_TEST_NAME}_pb_type_diff GOLDEN ${V2X_TEST_GOLDEN_PB_TYPE_XML} ACTUAL ${V2X_TEST_ACTUAL_PB_TYPE_XML})

  # model checking
  set(V2X_TEST_ACTUAL_MODEL_XML ${V2X_TEST_NAME}.model.xml)
  add_file_target(FILE ${V2X_TEST_GOLDEN_MODEL_XML} SCANNER_TYPE xml)
  xml_sort(NAME ${V2X_TEST_NAME}_model_golden_sort FILE ${V2X_TEST_GOLDEN_MODEL_XML} OUTPUT ${V2X_TEST_NAME}.model.golden.xml)
  xml_sort(NAME ${V2X_TEST_NAME}_model_actual_sort FILE ${V2X_TEST_ACTUAL_MODEL_XML} OUTPUT ${V2X_TEST_NAME}.model.actual.xml)
  diff(NAME ${V2X_TEST_NAME}_model_diff GOLDEN ${V2X_TEST_GOLDEN_MODEL_XML} ACTUAL ${V2X_TEST_ACTUAL_MODEL_XML})

  add_custom_target(${V2X_TEST_NAME}_diff ALL DEPENDS ${V2X_TEST_NAME}_pb_type_diff ${V2X_TEST_NAME}_model_diff)
endfunction(V2X_TEST)
