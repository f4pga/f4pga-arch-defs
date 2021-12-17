macro(RUN CMD)
  message(STATUS "Running \"${CMD}\"")
  separate_arguments(CMD_LIST NATIVE_COMMAND ${CMD})
  execute_process(
    COMMAND
      ${CMAKE_COMMAND} -E env
      ${CMD_LIST}
    RESULT_VARIABLE
      CMD_RESULT
  )
  if(CMD_RESULT)
    message(FATAL_ERROR "Command \"${CMD}\" failed!")
  endif()
endmacro()

# Remove the build directory
file(REMOVE_RECURSE ${BUILD_DIR})

# Run the toolchain
set(TOOLCHAIN_COMMAND "PATH=${INSTALLATION_DIR}/bin:$ENV{PATH} ${TOOLCHAIN_COMMAND}")
run(${TOOLCHAIN_COMMAND} "")

# Verify that all required output files are generated
message(STATUS "Checking output files...")

string(REPLACE "," ";" ASSERT_EXISTS "${ASSERT_EXISTS}")
set(MISSING_FILES FALSE)

foreach(FILE ${ASSERT_EXISTS})
  file(RELATIVE_PATH FNAME ${BUILD_DIR} ${FILE})
  if(NOT EXISTS "${FILE}")
    message(STATUS "[X] '${FNAME}'")
    set(MISSING_FILES TRUE)
  else()
    message(STATUS "[V] '${FNAME}'")
  endif()
endforeach()

if(MISSING_FILES)
  message(FATAL_ERROR "Some output files are missing!")
endif()

# Assert usage and timing if any
set(PYTHONPATH ${SYMBIFLOW_DIR}/utils)
set(USAGE_UTIL  ${PYTHONPATH}/report_block_usage.py)
set(TIMING_UTIL ${PYTHONPATH}/report_timing.py)

set(PACK_LOG  ${BUILD_DIR}/pack.log)
set(ROUTE_LOG ${BUILD_DIR}/route.log)

if (NOT "${ASSERT_USAGE}" STREQUAL "")
    run("PYTHONPATH=${PYTHONPATH} python3 ${USAGE_UTIL} ${PACK_LOG} --assert_usage ${ASSERT_USAGE}")
endif ()

if (NOT "${ASSERT_TIMING}" STREQUAL "")
    run("PYTHONPATH=${PYTHONPATH} python3 ${TIMING_UTIL} ${ROUTE_LOG} --assert ${ASSERT_TIMING}")
endif ()

# Check if IO constraints has been correctly applied. This is done by verifying
# the original PCF file agains the one produced by fasm2bels. For this to work
# "post_verilog" dump option must be enabled for a test (i.e. provided within
# EXTRA_ARGS).
set(PCF_UTIL ${PYTHONPATH}/pcf_compare.py)
set(OUT_PCF  ${BUILD_DIR}/top.bit.v.pcf)

if (NOT "${REF_PCF}" STREQUAL "")
    run("PYTHONPATH=${PYTHONPATH} python3 ${PCF_UTIL} ${REF_PCF} ${OUT_PCF}")
endif()

# Check if post synthesis verilog has correct format
# We look for verilog escaped identifiers ending with array indexing, e.g. [0]
# POST_SYNTH_NO_SPLIT shouldn't contain such identifiers
set(POST_SYNTH_NO_SPLIT	${BUILD_DIR}/top_post_synthesis.no_split.v)

if (EXISTS "${POST_SYNTH_NO_SPLIT}")
    SET(GREP_ARGS "\\\\\\S*\\[[0-9]*\\]\\s" "${POST_SYNTH_NO_SPLIT}")
    message(STATUS "${GREP_ARGS}")
    EXECUTE_PROCESS(
        COMMAND
        grep ${GREP_ARGS}
        OUTPUT_VARIABLE NO_SPLIT_VAL_OUT
        RESULT_VARIABLE NO_SPLIT_VAL_RES)

    if (${NO_SPLIT_VAL_RES} EQUAL 0 AND NOT "${NO_SPLIT_VAL_OUT}" STREQUAL "")
        MESSAGE(FATAL_ERROR "Found illegal escaped identifiers in ${POST_SYNTH_NO_SPLIT}: ${NO_SPLIT_VAL_OUT}")
    endif()
endif()
