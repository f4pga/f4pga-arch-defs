# ADD_BINARY_TOOLCHAIN_TEST
#
# This function adds a test for installed SymbiFlow toolchain (a.k.a. binary
# toolchain)
#
# Tests added require "make install" to be run upfront to install the toolchain

function(ADD_BINARY_TOOLCHAIN_TEST)

  set(options)
  set(oneValueArgs TEST_NAME DEVICE PINMAP EXTRA_ARGS)
  set(multiValueArgs)

  cmake_parse_arguments(
    ADD_BINARY_TOOLCHAIN_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")

  set(TEST_NAME  ${ADD_BINARY_TOOLCHAIN_TEST_TEST_NAME})
  set(DEVICE     ${ADD_BINARY_TOOLCHAIN_TEST_DEVICE})
  set(PINMAP     ${ADD_BINARY_TOOLCHAIN_TEST_PINMAP})
  set(EXTRA_ARGS ${ADD_BINARY_TOOLCHAIN_TEST_EXTRA_ARGS})

  set(SOURCES "${TEST_NAME}.v")

  set(PCF "${TEST_NAME}.pcf")
  set(SDC "${TEST_NAME}.sdc")

  set(TOOLCHAIN_COMMAND "\
    ql_symbiflow \
    -synth \
    -src ${CMAKE_CURRENT_SOURCE_DIR} \
    -d ${DEVICE} \
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

  set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} ${EXTRA_ARGS}")
  separate_arguments(TOOLCHAIN_COMMAND_LIST NATIVE_COMMAND ${TOOLCHAIN_COMMAND})

  add_test(NAME quicklogic_toolchain_test_${TEST_NAME}_${DEVICE}
    COMMAND
      ${CMAKE_COMMAND} -E env
      PATH=${INSTALLATION_DIR_BIN}:$ENV{PATH}
      ${TOOLCHAIN_COMMAND_LIST}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

endfunction()
