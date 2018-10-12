function(V2X_TEST)
  # ~~~
  # V2X(
  #   NAME name
  #   SRC src
  #   GOLDEN_PB_TYPE_XML file
  #   GOLDEN_MODEL_XML file
  #   )
  # ~~~
  #
  set(oneValueArgs NAME SRC GOLDEN_PB_TYPE_XML GOLDEN_MODEL_XML)
  cmake_parse_arguments(
    V2X_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  add_file_target(FILE ${V2X_TEST_SRC} SCANNER_TYPE verilog)
  v2x(NAME ${NAME} SRCS ${V2X_TEST_SRC})

  #get_file_location(SRC_LOCATION ${SRC})
  #set(ACTUAL_PB_TYPE_XML )

  # pb_type checking
  add_file_target(FILE ${GOLDEN_PB_TYPE_XML} SCANNER_TYPE xml)
  xml_sort(NAME ${NAME}_pb_type_golden_sort FILE ${GOLDEN_PB_TYPE_XML} OUTPUT ${NAME}.pb_type.golden.xml)
  xml_sort(NAME ${NAME}_pb_type_actual_sort FILE ${ACTUAL_PB_TYPE_XML} OUTPUT ${NAME}.pb_type.actual.xml)
  diff(NAME ${NAME}_pb_type_diff GOLDEN ${GOLDEN_PB_TYPE_XML} ACTUAL ${ACTUAL_PB_TYPE_XML})

  # model checking
  add_file_target(FILE ${GOLDEN_PB_MODEL_XML} SCANNER_TYPE xml)
  xml_sort(NAME ${NAME}_model_golden_sort FILE ${GOLDEN_PB_MODEL_XML} OUTPUT ${NAME}.model.golden.xml)
  xml_sort(NAME ${NAME}_model_actual_sort FILE ${ACTUAL_PB_MODEL_XML} OUTPUT ${NAME}.model.actual.xml)
  diff(NAME ${NAME}_model_diff GOLDEN ${GOLDEN_PB_MODEL_XML} ACTUAL ${ACTUAL_PB_MODEL_XML})

  add_custom_target(${NAME}_diff ALL DEPENDS ${NAME}_pb_type_diff ${NAME}_model_diff)
endfunction(V2X_TEST)
