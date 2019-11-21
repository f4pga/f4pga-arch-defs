function(VPR_TEST)
  # ~~~
  # VPR_TEST(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # NAME name of the test.
  # TOP_MODULE name of the top verilog module that has to be tested.
  # TECHMAPS [optional] list of techmaps files to be used when synthesizing the design
  #
  # Usage: vpr_test(NAME <test_name> TOP_MODULE <top_module.v>) (All fields are required)

  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs TECHMAPS)
  cmake_parse_arguments(
    VPR_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${VPR_TEST_NAME})
  set(TOP_MODULE ${VPR_TEST_TOP_MODULE})

  set(MERGED_TECHMAP_FILE "${NAME}.techmap.merged.v")
  set(MERGED_TECHMAP "${MERGED_TECHMAP_FILE}")
  set(TECHMAP_INPUT "")
  set(TECHMAP_DEPS "")
  foreach(MAP ${VPR_TEST_TECHMAPS})
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
  vpr_test_pb_type(NAME ${NAME} TOP_MODULE ${TOP_MODULE})
endfunction(VPR_TEST)
