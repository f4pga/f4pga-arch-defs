# Creating new target to call all the added tests
add_custom_target(all_v2x_tests ALL)

function(V2X_TEST_GENERIC)
  # ~~~
  # V2X_TEST_GENERIC(
  #   NAME name
  #   TYPE pb_type | model
  #   )
  # ~~~
  #
  # This function is used to create targets to perform a test on generic TYPE (pb_type or model).
  # There are some tests which require only pb_types XMLs to be checked and others who require only models XMLs to be checked.
  # Therefore, this function is used to generalize and perform the desired test.
  #
  # NAME name of the test.
  # TYPE type of test that has to be performed (model or pb_type generation).
  #
  # In addition it adds the newly created target to the `all_v2x_tests` dependencies. (all tests will be performed with `make all_v2x_tests`)
  #
  # Usage: v2x_test_generic(NAME <test_name> TYPE <model|pb_type>) (All fields are required)

  set(oneValueArgs NAME TYPE)
  cmake_parse_arguments(
    V2X_TEST_GENERIC
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(TYPE ${V2X_TEST_GENERIC_TYPE})
  set(NAME ${V2X_TEST_GENERIC_NAME})

  # pb_type checking
  set(GOLDEN_XML golden.${TYPE}.xml)
  add_file_target(FILE ${GOLDEN_XML} SCANNER_TYPE xml)
  xml_canonicalize_merge(
    NAME ${NAME}_${TYPE}
    FILE ${GOLDEN_XML}
    OUTPUT ${NAME}.${TYPE}.golden.xml
    EXTRA_ARGUMENTS "-param" "strip_comments" "1"
    )

  set(ACTUAL_XML ${NAME}.${TYPE}.xml)
  xml_canonicalize_merge(
    NAME ${NAME}_${TYPE}
    FILE ${ACTUAL_XML}
    OUTPUT ${NAME}.${TYPE}.actual.xml
    EXTRA_ARGUMENTS "-param" "strip_comments" "1"
    )

  get_rel_target(REL_DIFF_NAME diff ${NAME}.${TYPE}.xml)
  diff(NAME ${REL_DIFF_NAME} GOLDEN ${NAME}.${TYPE}.golden.xml ACTUAL ${NAME}.${TYPE}.actual.xml)

  add_dependencies(all_v2x_tests ${REL_DIFF_NAME})

  set(FILE_DEPS "")
  append_file_dependency(FILE_DEPS ${ACTUAL_XML})

  # update golden model/pb_type target
  get_rel_target(REL_GOLDEN_XML update ${GOLDEN_XML})
  add_custom_target(${REL_GOLDEN_XML})
  add_custom_command(
    TARGET ${REL_GOLDEN_XML}
    DEPENDS ${FILE_DEPS}
    POST_BUILD
    COMMAND cp ${ACTUAL_XML} ${CMAKE_CURRENT_SOURCE_DIR}/golden.${TYPE}.xml
    )
endfunction(V2X_TEST_GENERIC)

function(V2X_TEST_MODEL)
  # ~~~
  # V2X_TEST_MODEL(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test only the model XML generation. It will call V2X_TEST_GENERIC with the field TYPE set to `model`.
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE)
  cmake_parse_arguments(
    V2X_TEST_MODEL
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${V2X_TEST_MODEL_NAME})
  set(TOP_MODULE ${V2X_TEST_MODEL_TOP_MODULE})

  set(SRC ${NAME}.sim.v)
  v2x(NAME ${NAME} SRCS ${SRC} TOP_MODULE ${TOP_MODULE})

  v2x_test_generic(NAME ${NAME} TYPE model)

  get_rel_target(REL_DIFF_NAME diff ${NAME})
  add_custom_target(${REL_DIFF_NAME} ALL DEPENDS ${REL_DIFF_NAME}.model.xml)
endfunction(V2X_TEST_MODEL)

function(V2X_TEST_PB_TYPE)
  # ~~~
  # V2X_TEST_PB_TYPE(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # This function is to test only the pb_type XML generation. It will call V2X_TEST_GENERIC with the field TYPE set to `pb_type`
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE)
  cmake_parse_arguments(
    V2X_TEST_PB_TYPE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${V2X_TEST_MODEL_NAME})
  set(TOP_MODULE ${V2X_TEST_MODEL_TOP_MODULE})

  set(SRC ${NAME}.sim.v)
  v2x(NAME ${NAME} SRCS ${SRC} TOP_MODULE ${TOP_MODULE})

  v2x_test_generic(NAME ${NAME} TYPE pb_type)

  get_rel_target(REL_DIFF_NAME diff ${NAME})
  add_custom_target(${REL_DIFF_NAME} ALL DEPENDS ${REL_DIFF_NAME}.pb_type.xml)
endfunction(V2X_TEST_PB_TYPE)

function(V2X_TEST_BOTH)
  # ~~~
  # V2X_TEST_BOTH(
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
  # TECHMAPS [optional] list of techmaps files to be used when synthesizing the design
  #
  # Usage: v2x_test_model(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs TECHMAPS)
  cmake_parse_arguments(
    V2X_TEST_BOTH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${V2X_TEST_BOTH_NAME})
  set(TOP_MODULE ${V2X_TEST_BOTH_TOP_MODULE})

  set(SRC ${NAME}.sim.v)
  v2x(NAME ${NAME} SRCS ${SRC} TOP_MODULE ${TOP_MODULE})

  set(MERGED_TECHMAP_FILE "${NAME}.techmap.merged.v")
  set(MERGED_TECHMAP "${MERGED_TECHMAP_FILE}")
  set(TECHMAP_INPUT "")
  set(TECHMAP_DEPS "")
  foreach(MAP ${V2X_TEST_BOTH_TECHMAPS})
    list(
      APPEND
      TECHMAP_INPUT
      ${MAP}
    )
    append_file_dependency(TECHMAP_DEPS ${MAP})
  endforeach()

  if(TECHMAP_INPUT)
    add_custom_command(
      OUTPUT "${MERGED_TECHMAP}"
      DEPENDS ${TECHMAP_DEPS}
      COMMAND
      cat ${TECHMAP_INPUT} > ${MERGED_TECHMAP}
      WORKING_DIRECTORY
        ${CMAKE_CURRENT_BINARY_DIR}
    )
  else()
    # if there are no techmaps to merge, create an empty .v file so Yosys is happy
    add_custom_command(
      OUTPUT "${MERGED_TECHMAP}"
      COMMAND
        touch ${MERGED_TECHMAP}
      WORKING_DIRECTORY
        ${CMAKE_CURRENT_BINARY_DIR}
    )
  endif()

  add_file_target(FILE "${MERGED_TECHMAP}" GENERATED)

  v2x_test_generic(NAME ${NAME} TYPE pb_type)
  v2x_test_generic(NAME ${NAME} TYPE model)
  vpr_test_pb_type(NAME ${NAME} TOP_MODULE ${TOP_MODULE})
  get_rel_target(TEST_REL_NAME test ${NAME})
  add_dependencies(all_v2x_tests ${TEST_REL_NAME})

  get_rel_target(REL_DIFF_NAME diff ${NAME})
  add_custom_target(${REL_DIFF_NAME} ALL DEPENDS ${REL_DIFF_NAME}.pb_type.xml ${REL_DIFF_NAME}.model.xml)
endfunction(V2X_TEST_BOTH)
