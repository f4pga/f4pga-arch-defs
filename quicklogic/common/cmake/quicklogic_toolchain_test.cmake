# ADD_BINARY_TOOLCHAIN_TEST
#
# This function adds a test for installed SymbiFlow toolchain (a.k.a. binary
# toolchain)
#
# Tests added require "make install" to be run upfront to install the toolchain

function(ADD_BINARY_TOOLCHAIN_TEST)

  set(options CHECK_CONSTRAINTS)
  set(oneValueArgs TEST_NAME DIRECTIVE DEVICE PINMAP PCF SDC EXTRA_ARGS ASSERT_USAGE ASSERT_TIMING)
  set(multiValueArgs SOURCES ASSERT_EXISTS)

  cmake_parse_arguments(
    ADD_BINARY_TOOLCHAIN_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(INSTALLATION_DIR_BIN "${CMAKE_INSTALL_PREFIX}/bin")

  set(TEST_NAME  ${ADD_BINARY_TOOLCHAIN_TEST_TEST_NAME})
  set(SOURCES    ${ADD_BINARY_TOOLCHAIN_TEST_SOURCES})
  set(DIRECTIVE  ${ADD_BINARY_TOOLCHAIN_TEST_DIRECTIVE})
  set(DEVICE     ${ADD_BINARY_TOOLCHAIN_TEST_DEVICE})
  set(PINMAP     ${ADD_BINARY_TOOLCHAIN_TEST_PINMAP})
  set(PCF        ${ADD_BINARY_TOOLCHAIN_TEST_PCF})
  set(SDC        ${ADD_BINARY_TOOLCHAIN_TEST_SDC})
  set(EXTRA_ARGS ${ADD_BINARY_TOOLCHAIN_TEST_EXTRA_ARGS})

  string(REPLACE " " ";" SOURCES "${SOURCES}")
  if("${SOURCES}" STREQUAL "")
      set(SOURCES "${TEST_NAME}.v")
  endif()

  if("${PCF}" STREQUAL "")
    set(PCF "${TEST_NAME}.pcf")
  endif()

  if("${SDC}" STREQUAL "")
    set(SDC "${TEST_NAME}.sdc")
  endif()

  if("${DIRECTIVE}" STREQUAL "")
    set(DIRECTIVE "compile")
  endif()

  set(TOOLCHAIN_COMMAND "\
    ql_symbiflow \
    -${DIRECTIVE} \
    -src ${CMAKE_CURRENT_SOURCE_DIR} \
    -d ${DEVICE} \
    -t top \
    -v ${SOURCES} \
    -P ${PINMAP} "
  )

  set(REF_PCF "")
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${PCF}")
    set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} -p \"${PCF}\"")
    if(${ADD_BINARY_TOOLCHAIN_TEST_CHECK_CONSTRAINTS})
        file(REAL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${PCF}" REF_PCF)
    endif()
  endif()
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${SDC}")
    set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} -s \"${SDC}\"")
  endif()

  set(BUILD_DIR_REL "build.${TEST_NAME}")
  set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} -build_dir \"${BUILD_DIR_REL}\"")

  set(BUILD_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR_REL})

  # Build a list of files which existence is to be checked after the toolchain
  # is executed.
  set(ASSERT_EXISTS "")
  list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.eblif")

  if("${DIRECTIVE}" STREQUAL "compile")
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.net")
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.place")
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.fasm")
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.bit")
  endif()

  # qlf* architectures use repacker hence the "top.route" name is
  # different.
  if("${DEVICE}" MATCHES "qlf_.*")
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.repacked.route")
  else()
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/top.route")
  endif()

  foreach(FILE ${ADD_BINARY_TOOLCHAIN_TEST_ASSERT_EXISTS})
    list(APPEND ASSERT_EXISTS "${BUILD_DIR}/${FILE}")
  endforeach()

  string(REPLACE ";" "," ASSERT_EXISTS "${ASSERT_EXISTS}")

  # Add the test
  set(TOOLCHAIN_COMMAND "${TOOLCHAIN_COMMAND} ${EXTRA_ARGS}")
  add_test(NAME quicklogic_toolchain_test_${TEST_NAME}_${DEVICE}
    COMMAND
      ${CMAKE_COMMAND}
        -DTOOLCHAIN_COMMAND=${TOOLCHAIN_COMMAND}
        -DSYMBIFLOW_DIR=${symbiflow-arch-defs_SOURCE_DIR}
        -DINSTALLATION_DIR=${CMAKE_INSTALL_PREFIX}
        -DBUILD_DIR=${BUILD_DIR}
        -DASSERT_USAGE=${ADD_BINARY_TOOLCHAIN_TEST_ASSERT_USAGE}
        -DASSERT_TIMING=${ADD_BINARY_TOOLCHAIN_TEST_ASSERT_TIMING}
        -DASSERT_EXISTS=${ASSERT_EXISTS}
        -DREF_PCF=${REF_PCF}
        -P ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/cmake/run_toolchain_test.cmake
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

endfunction()
