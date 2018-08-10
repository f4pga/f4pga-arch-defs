function(GENERATE_DUMMY)
  set(DUMMY_FILES
    CLBLL_R.xml CLBLM_L.xml CLBLM_R.xml
    INT_L.xml INT_R.xml HCLK_L.xml HCLK_R.xml)

  foreach(FILE ${DUMMY_FILES})
    add_custom_command(
      OUTPUT ${FILE}
      COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/dummy.sh ${CMAKE_CURRENT_BINARY_DIR}/${FILE}
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/dummy.sh
      )
    add_file_target(FILE ${FILE} GENERATED)
  endforeach()
endfunction()

generate_dummy()
