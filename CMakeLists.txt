cmake_minimum_required (VERSION 3.0)
project (symbiflow-arch-defs)

function(GET_FILE_TARGET var path)
  set(SOURCE_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/${path})
  string(REPLACE "/" "_" TARGET_PATH ${SOURCE_LOCATION})
  set(${var} file_${TARGET_PATH} PARENT_SCOPE)
endfunction()

function(MAKE_FILE_TARGET)
  set(options GENERATED)
  set(oneValueArgs FILE)
  set(multiValueArgs)
  cmake_parse_arguments(MAKE_FILE_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  GET_FILE_TARGET(TARGET_NAME ${MAKE_FILE_TARGET_FILE})

  add_custom_target(${TARGET_NAME} DEPENDS ${MAKE_FILE_TARGET_FILE})
  if(${MAKE_FILE_TARGET_GENERATED})
    set_target_properties(${TARGET_NAME} PROPERTIES LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${MAKE_FILE_TARGET_FILE})
  else()
    set_target_properties(${TARGET_NAME} PROPERTIES LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/${MAKE_FILE_TARGET_FILE})
  endif()
  set_target_properties(${TARGET_NAME} PROPERTIES INCLUDES "")
endfunction(MAKE_FILE_TARGET)

function(V2X)
  set(options)
  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs SRCS)
  cmake_parse_arguments(V2X "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(INCLUDES "")
  set(REAL_SOURCE_LIST "")
  foreach(SRC ${V2X_SRCS})
    if(NOT "${SRC}" MATCHES "\\.sim\\.v$")
      message(FATAL_ERROR "File ${SRC} does not end with .sim.v")
    endif()

    GET_FILE_TARGET(SRC_TARGET ${SRC})
    get_target_property(SRC_INCLUDES ${SRC_TARGET} INCLUDES)
    get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
    if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
      message(FATAL_ERROR "File ${SRC} did is not a valid verilog target, missing LOCATION.")
    endif()
    if("${SRC_INCLUDES}" STREQUAL "NOT_FOUND")
      message(FATAL_ERROR "File ${SRC} did is not a valid verilog target, missing INCLUDES list.")
    endif()

    list(APPEND INCLUDES ${SRC_INCLUDES})
    list(APPEND REAL_SOURCE_LIST ${SRC_LOCATION})
  endforeach()

  set(TOP_ARG "")
  if(NOT ${TOP_MODULE} STREQUAL "")
    set(TOP_ARG "--top=${TOP_MODULE}")
  endif()

  list(GET REAL_SOURCE_LIST 0 FIRST_SOURCE)

  list(APPEND INCLUDES "${CMAKE_CURRENT_BINARY_DIR}")
  list(APPEND INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}")
  list(APPEND INCLUDES "${symbiflow-arch-defs_SOURCE_DIR}")

  string(REPLACE ";" "," INCLUDES_LIST "${INCLUDES}")

  set(INCLUDE_ARG "")
  if(NOT "${INCLUDES_LIST}" STREQUAL "")
    set(INCLUDE_ARG "--includes=${INCLUDES_LIST}")
  endif()

  add_custom_command(
    OUTPUT "${V2X_NAME}.pb_type.xml"
    DEPENDS ${REAL_SOURCE_LIST} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py ${TOP_ARG} -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml ${FIRST_SOURCE} ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
    )

  MAKE_FILE_TARGET(FILE "${V2X_NAME}.pb_type.xml" GENERATED)

  add_custom_command(
    OUTPUT "${V2X_NAME}.model.xml"
    DEPENDS ${REAL_SOURCE_LIST} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_model.py ${TOP_ARG} -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml ${FIRST_SOURCE} ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
    )

  MAKE_FILE_TARGET(FILE "${V2X_NAME}.model.xml" GENERATED)

  message(STATUS "Test ${V2X_NAME}")
  add_custom_target(${V2X_NAME} ALL
    DEPENDS
      "${V2X_NAME}.model.xml"
      "${V2X_NAME}.pb_type.xml"
      )
endfunction(V2X)

function(MUX_GEN)
  set(options SPLIT_INPUTS SPLIT_SELECTS)
  set(oneValueArgs NAME MUX_NAME TYPE WIDTH INPUTS SELECTS SUBCKT COMMENT OUTPUT DATA_WIDTH)
  set(multiValueArgs NTEMPLATE_PREFIXES)
  cmake_parse_arguments(MUX_GEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if("${MUX_GEN_TYPE}" STREQUAL "routing")
    if("${MUX_GEN_SUBCKT}" STREQUAL "")
      message(FATAL_ERROR "Can not use SUBCKT=${MUX_GEN_SUBCKT} with routing mux.")
    endif()
  elseif("${MUX_GEN_TYPE}" STREQUAL "logic")
  else()
    message(FATAL_ERROR "MUX_GEN type must be \"routing\" or \"logic\".")
  endif()

  set(MUX_GEN_ARGS "")
  list(APPEND MUX_GEN_ARGS "--outdir=${CMAKE_CURRENT_BINARY_DIR}")
  list(APPEND MUX_GEN_ARGS "--outfilename=${MUX_GEN_NAME}")
  list(APPEND MUX_GEN_ARGS "--type=${MUX_GEN_TYPE}")
  list(APPEND MUX_GEN_ARGS "--width=${MUX_GEN_WIDTH}")
  list(APPEND MUX_GEN_ARGS "--name-mux=${MUX_GEN_MUX_NAME}")

  if(NOT "${MUX_GEN_COMMENT}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--command=${MUX_GEN_COMMENT}")
  endif()

  if(NOT "${MUX_GEN_OUTPUT}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--name-out=${MUX_GEN_OUTPUT}")
  endif()

  if(${MUX_GEN_SPLIT_INPUTS})
    list(APPEND MUX_GEN_ARGS "--split-inputs=1")
  endif()

  if(NOT "${MUX_GEN_INPUTS}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--name-inputs=${MUX_GEN_INPUTS}")
  endif()

  if(${MUX_GEN_SPLIT_SELECTS})
    list(APPEND MUX_GEN_ARGS "--split-selects=1")
  endif()

  if(NOT "${MUX_GEN_SELECTS}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--name-selects=${MUX_GEN_SELECTS}")
  endif()

  if(NOT "${MUX_GEN_SUBCKT}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--subckt=${MUX_GEN_SUBCKT}")
  endif()

  if(NOT "${MUX_GEN_DATA_WIDTH}" STREQUAL "")
    list(APPEND MUX_GEN_ARGS "--data-width=${MUX_GEN_DATA_WIDTH}")
  endif()

  set(OUTPUTS "")
  list(APPEND OUTPUTS
    "${MUX_GEN_NAME}.sim.v"
    "${MUX_GEN_NAME}.pb_type.xml"
    "${MUX_GEN_NAME}.model.xml"
    )

  add_custom_command(
    OUTPUT ${OUTPUTS}
    DEPENDS ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py ${MUX_GEN_ARGS})

  foreach(OUTPUT ${OUTPUTS})
    MAKE_FILE_TARGET(FILE ${OUTPUT} GENERATED)
  endforeach()

  GET_FILE_TARGET(SRC_TARGET "${MUX_GEN_NAME}.sim.v")

  add_custom_target(
    ${MUX_GEN_NAME} ALL
    DEPENDS ${OUTPUTS})

  if(NOT "${MUX_GEN_NTEMPLATE_PREFIXES}" STREQUAL "")
    foreach(OUTPUT ${OUTPUTS})
      string(REPLACE "ntemplate." "" N_TEMPLATE_NAME ${OUTPUT})
      N_TEMPLATE(
        NAME ${N_TEMPLATE_NAME}
        PREFIXES ${MUX_GEN_NTEMPLATE_PREFIXES}
        SRCS ${OUTPUT}
        )
    endforeach()
  endif()
endfunction(MUX_GEN)

function(N_TEMPLATE)
  set(options APPLY_V2X)
  set(oneValueArgs NAME)
  set(multiValueArgs SRCS PREFIXES)
  cmake_parse_arguments(N_TEMPLATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(OUTPUTS "")

  foreach(PREFIX ${N_TEMPLATE_PREFIXES})
    foreach(SRC ${N_TEMPLATE_SRCS})
      string(REPLACE "ntemplate." "" SRC_NO_NTEMPLATE ${SRC})
      string(REPLACE "N" ${PREFIX} SRC_WITH_PREFIX ${SRC_NO_NTEMPLATE})
      GET_FILE_TARGET(SRC_TARGET ${SRC})
      add_custom_command(
        OUTPUT ${SRC_WITH_PREFIX}
        DEPENDS ${SRC} ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py
        COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py ${PREFIX} $<TARGET_PROPERTY:${SRC_TARGET},LOCATION> ${CMAKE_CURRENT_BINARY_DIR}/${SRC_WITH_PREFIX}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )

      MAKE_FILE_TARGET(FILE ${SRC_WITH_PREFIX} GENERATED)

      list(APPEND OUTPUTS ${SRC_WITH_PREFIX})

      if(${APPLY_V2X})
        V2X(NAME ${PREFIX}${NAME} SRCS ${SRC_WITH_PREFIX})
      endif()
    endforeach(SRC)
  endforeach(PREFIX)

  add_custom_target(
    ${N_TEMPLATE_NAME} ALL
    DEPENDS ${OUTPUTS})
endfunction(N_TEMPLATE)

add_subdirectory(artix7)
