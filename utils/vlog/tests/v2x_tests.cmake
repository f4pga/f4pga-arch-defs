# Creating new target to call all the added tests
add_custom_target(all_v2x_tests ALL)

function(V2X_GENERIC_TEST)
  # ~~~
  # V2X_GENERIC_TEST(
  #   NAME name
  #   TOP_MODULE name
  #   TYPE pb_type | model
  #   )
  # ~~~
  #
  # This function is used to create targets to perform a test on generic TYPE (pb_type or model).
  # There are some tests which require only pb_types XMLs to be checked and others who require only models XMLs to be checked.
  # Therefore, this function is used to generalize and perform the desired test.
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  # TYPE type of test that has to be performed (model or pb_type generation).
  #
  # In addition it adds the newly created target to the `all_v2x_tests` dependencies. (all tests will be performed with `make all_v2x_tests`)
  #
  # Usage: v2x_generic_test(NAME <test_name> TOP_MODULE <top_module.v> TYPE <model|pb_type>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE TYPE)
  cmake_parse_arguments(
    V2X_GENERIC_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )


  # pb_type checking
  set(V2X_GENERIC_TEST_GOLDEN_XML golden.${V2X_GENERIC_TEST_TYPE}.xml)
  add_file_target(FILE ${V2X_GENERIC_TEST_GOLDEN_XML} SCANNER_TYPE xml)
  xml_sort(NAME ${V2X_GENERIC_TEST_NAME}_${V2X_GENERIC_TEST_TYPE}_golden_sort FILE ${V2X_GENERIC_TEST_GOLDEN_XML} OUTPUT ${V2X_GENERIC_TEST_NAME}.${V2X_GENERIC_TEST_TYPE}.golden.xml)

  set(V2X_GENERIC_TEST_ACTUAL_XML ${V2X_GENERIC_TEST_NAME}.${V2X_GENERIC_TEST_TYPE}.xml)
  xml_sort(NAME ${V2X_GENERIC_TEST_NAME}_${V2X_GENERIC_TEST_TYPE}_actual_sort FILE ${V2X_GENERIC_TEST_ACTUAL_XML} OUTPUT ${V2X_GENERIC_TEST_NAME}.${V2X_GENERIC_TEST_TYPE}.actual.xml)

  diff(NAME ${V2X_GENERIC_TEST_NAME}_${V2X_GENERIC_TEST_TYPE}_diff GOLDEN ${V2X_GENERIC_TEST_NAME}.${V2X_GENERIC_TEST_TYPE}.golden.xml ACTUAL ${V2X_GENERIC_TEST_NAME}.${V2X_GENERIC_TEST_TYPE}.actual.xml)

  add_dependencies(all_v2x_tests ${V2X_GENERIC_TEST_NAME}_${V2X_GENERIC_TEST_TYPE}_diff)
endfunction(V2X_GENERIC_TEST)

function(V2X_TEST_MODEL)
  # ~~~
  # V2X_TEST_MODEL(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test only the model XML generation. It will call V2X_GENERIC_TEST with the field TYPE set to `model`.
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE TYPE)
  cmake_parse_arguments(
    V2X_TEST_MODEL
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(V2X_TEST_MODEL_SRC ${V2X_TEST_MODEL_NAME}.sim.v)
  add_file_target(FILE ${V2X_TEST_MODEL_SRC} SCANNER_TYPE verilog)
  v2x(NAME ${V2X_TEST_MODEL_NAME} SRCS ${V2X_TEST_MODEL_SRC} TOP_MODULE ${V2X_TEST_MODEL_TOP_MODULE})

  v2x_generic_test(NAME ${V2X_TEST_MODEL_NAME} TOP_MODULE ${V2X_TEST_MODEL_TOP_MODULE} TYPE model)

  add_custom_target(${V2X_TEST_MODEL_NAME}_diff ALL DEPENDS ${V2X_TEST_MODEL_NAME}_model_diff)
endfunction(V2X_TEST_MODEL)

function(V2X_TEST_PB_TYPE)
  # ~~~
  # V2X_TEST_PB_TYPE(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test only the pb_type XML generation. It will call V2X_GENERIC_TEST with the field TYPE set to `pb_type`
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE TYPE)
  cmake_parse_arguments(
    V2X_TEST_PB_TYPE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(V2X_TEST_PB_TYPE_SRC ${V2X_TEST_PB_TYPE_NAME}.sim.v)
  add_file_target(FILE ${V2X_TEST_PB_TYPE_SRC} SCANNER_TYPE verilog)
  v2x(NAME ${V2X_TEST_PB_TYPE_NAME} SRCS ${V2X_TEST_PB_TYPE_SRC} TOP_MODULE ${V2X_TEST_PB_TYPE_TOP_MODULE})

  v2x_generic_test(NAME ${V2X_TEST_PB_TYPE_NAME} TOP_MODULE ${V2X_TEST_PB_TYPE_TOP_MODULE} TYPE pb_type)

  add_custom_target(${V2X_TEST_PB_TYPE_NAME}_diff ALL DEPENDS ${V2X_TEST_PB_TYPE_NAME}_pb_type_diff)
endfunction(V2X_TEST_PB_TYPE)

function(V2X_TEST_BOTH)
  # ~~~
  # V2X_TEST_BOTH(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test both the pb_type XML generation. It will call V2X_GENERIC_TEST multiple times first with the field TYPE set to `pb_type`
  # then with `model`
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE TYPE)
  cmake_parse_arguments(
    V2X_TEST_BOTH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(V2X_TEST_BOTH_SRC ${V2X_TEST_BOTH_NAME}.sim.v)
  add_file_target(FILE ${V2X_TEST_BOTH_SRC} SCANNER_TYPE verilog)
  v2x(NAME ${V2X_TEST_BOTH_NAME} SRCS ${V2X_TEST_BOTH_SRC} TOP_MODULE ${V2X_TEST_BOTH_TOP_MODULE})

  v2x_generic_test(NAME ${V2X_TEST_BOTH_NAME} TOP_MODULE ${V2X_TEST_BOTH_TOP_MODULE} TYPE pb_type)
  v2x_generic_test(NAME ${V2X_TEST_BOTH_NAME} TOP_MODULE ${V2X_TEST_BOTH_TOP_MODULE} TYPE model)

  add_custom_target(${V2X_TEST_BOTH_NAME}_diff ALL DEPENDS ${V2X_TEST_BOTH_NAME}_pb_type_diff ${V2X_TEST_BOTH_NAME}_model_diff)
endfunction(V2X_TEST_BOTH)
