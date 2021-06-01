set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")

function(add_binary_test target_name test_name family extra_args)

  set(SOURCES "${test_name}.v")
  set(PINMAP "pinmap_${family}_umc22.csv")

  set(PCF "${test_name}.pcf")
  set(SDC "${test_name}.sdc")

  set(TOOLCHAIN_COMMAND "\
    ql_symbiflow \
    -synth \
    -src ${CMAKE_CURRENT_SOURCE_DIR} \
    -d ${family} \
    -t top \
    -v ${SOURCES} \
    -P ${PINMAP} "
  )

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${PCF}")
    set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} -p \"${PCF}\"")
  endif()
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${SDC}")
    set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} -s \"${SDC}\"")
  endif()

  set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} ${extra_args}")
  separate_arguments(TOOLCHAIN_COMMAND_LIST NATIVE_COMMAND ${TOOLCHAIN_COMMAND})

  add_test(NAME ${target_name}
    COMMAND
      ${CMAKE_COMMAND} -E env
      PATH=${INSTALLATION_DIR_BIN}:$ENV{PATH}
      ${TOOLCHAIN_COMMAND_LIST}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

endfunction()

add_subdirectory(counter_16bit)
add_subdirectory(compile_args)

