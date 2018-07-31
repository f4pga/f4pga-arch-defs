cmake_minimum_required (VERSION 3.0)
project (symbiflow-arch-defs)

function(SETUP_ENV)
  add_custom_target(env)

  set(OTHER_BINARIES inkscape)
  set(MAYBE_CONDA_BINARIES yosys vpr xsltproc pytest yapf node npm iverilog python3 pip cocotb)

  # FIXME: Add target to configure conda.
  set(ENV_DIR ${symbiflow-arch-defs_SOURCE_DIR}/env)
  if(IS_DIRECTORY ${ENV_DIR})
    set(CONDA_DIR ${ENV_DIR}/conda)

    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set_target_properties(
        env
        PROPERTIES
        ${binary_upper} ${CONDA_DIR}/bin/${binary}
        )
    endforeach()
  else()
    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set_target_properties(
        env
        PROPERTIES
        ${binary_upper} ${binary}
        )
    endforeach()
  endif()

  foreach(binary ${OTHER_BINARIES})
    string(TOUPPER ${binary} binary_upper)
    set_target_properties(
      env
      PROPERTIES
      ${binary_upper} ${binary}
      )
  endforeach()
endfunction()

SETUP_ENV()

function(GET_FILE_TARGET var path)
  if(${path} MATCHES "^/")
    set(SOURCE_LOCATION ${path})
  else()
    set(SOURCE_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/${path})
  endif()
  string(REPLACE "/" "_" TARGET_PATH ${SOURCE_LOCATION})
  set(${var} file_${TARGET_PATH} PARENT_SCOPE)
endfunction()

function(GET_FILE_LOCATION var src_file)
  GET_FILE_TARGET(SRC_TARGET ${src_file})
  get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
  if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
    message(FATAL_ERROR "File ${src_file} is not a valid verilog target, missing LOCATION.")
  endif()

  set(${var} ${SRC_LOCATION} PARENT_SCOPE)
endfunction()

function(APPEND_FILE_DEPENDENCY var src_file)
  GET_FILE_TARGET(SRC_TARGET ${src_file})
  get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
  if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
    message(FATAL_ERROR "File ${src_file} is not a valid verilog target, missing LOCATION.")
  endif()

  list(APPEND ${var} ${SRC_TARGET})
  list(APPEND ${var} ${SRC_LOCATION})
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(APPEND_FILE_INCLUDES var src_file)
  GET_FILE_TARGET(SRC_TARGET ${src_file})
  get_target_property(SRC_INCLUDES ${SRC_TARGET} INCLUDES)
  if("${SRC_INCLUDES}" STREQUAL "NOT_FOUND")
    message(FATAL_ERROR "File ${SRC} is not a valid verilog target, missing INCLUDES list.")
  endif()

  list(APPEND ${var} ${SRC_INCLUDES})
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(GET_VERILOG_INCLUDES var file)
  execute_process(
    COMMAND grep "^`include" "${file}"
    COMMAND cut -d \" -f 2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE INCLUDES)

  string(REPLACE "\n" ";" INCLUDES_LIST "${INCLUDES}")
  foreach(INCLUDE ${INCLUDES_LIST})
    string(STRIP ${INCLUDE} INCLUDE)
    if(NOT "${INCLUDE}" STREQUAL "")
      get_filename_component(ABS_PATH_TO_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/${INCLUDE}
        ABSOLUTE
        BASE_DIR ${symbiflow-arch-defs_SOURCE_DIR})
      list(APPEND ${var} ${ABS_PATH_TO_INCLUDE})
    endif()
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(GET_XML_INCLUDES var file)
  get_target_property_required(PYTHON3 env PYTHON3)
  execute_process(
    COMMAND ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/deps_xml.py --file_per_line ${CMAKE_CURRENT_SOURCE_DIR}/${file}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}
    OUTPUT_VARIABLE INCLUDES)

  string(REPLACE "\n" ";" INCLUDES_LIST "${INCLUDES}")
  foreach(INCLUDE ${INCLUDES_LIST})
    string(STRIP ${INCLUDE} INCLUDE)
    if(NOT "${INCLUDE}" STREQUAL "")
      get_filename_component(ABS_PATH_TO_INCLUDE ${INCLUDE}
        ABSOLUTE
        BASE_DIR ${symbiflow-arch-defs_SOURCE_DIR})
      list(APPEND ${var} ${ABS_PATH_TO_INCLUDE})
    endif()
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(MAKE_FILE_TARGET)
  set(options GENERATED)
  set(oneValueArgs FILE SCANNER_TYPE)
  set(multiValueArgs)
  cmake_parse_arguments(MAKE_FILE_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  GET_FILE_TARGET(TARGET_NAME ${MAKE_FILE_TARGET_FILE})

  SET(INCLUDE_FILES "")
  if(NOT ${MAKE_FILE_TARGET_GENERATED})
    if("${MAKE_FILE_TARGET_SCANNER_TYPE}" STREQUAL "")
    elseif("${MAKE_FILE_TARGET_SCANNER_TYPE}" STREQUAL "verilog")
      GET_VERILOG_INCLUDES(INCLUDE_FILES ${MAKE_FILE_TARGET_FILE})
    elseif("${MAKE_FILE_TARGET_SCANNER_TYPE}" STREQUAL "xml")
      GET_XML_INCLUDES(INCLUDE_FILES ${MAKE_FILE_TARGET_FILE})
    else()
      message(FATAL_ERROR "Unknown SCANNER_TYPE=${MAKE_FILE_TARGET_SCANNER_TYPE}.")
    endif()
  endif()

  SET(INCLUDE_FILES_TARGETS "")
  foreach(INCLUDE ${INCLUDE_FILES})
    APPEND_FILE_DEPENDENCY(INCLUDE_FILES_TARGETS ${INCLUDE})
  endforeach()

  if(NOT ${MAKE_FILE_TARGET_GENERATED})
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${MAKE_FILE_TARGET_FILE}
        COMMAND ${CMAKE_COMMAND} -E copy
          ${CMAKE_CURRENT_SOURCE_DIR}/${MAKE_FILE_TARGET_FILE}
          ${CMAKE_CURRENT_BINARY_DIR}/${MAKE_FILE_TARGET_FILE}
          DEPENDS ${INCLUDE_FILES_TARGETS}
          )
  endif()

  add_custom_target(${TARGET_NAME}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${MAKE_FILE_TARGET_FILE} ${INCLUDE_FILES_TARGETS})

  set_target_properties(${TARGET_NAME} PROPERTIES LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${MAKE_FILE_TARGET_FILE})
  set_target_properties(${TARGET_NAME} PROPERTIES INCLUDES "")
endfunction(MAKE_FILE_TARGET)

function(V2X)
  set(options)
  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs SRCS)
  cmake_parse_arguments(V2X "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(INCLUDES "")
  list(APPEND INCLUDES "${CMAKE_CURRENT_BINARY_DIR}")
  list(APPEND INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}")
  list(APPEND INCLUDES "${symbiflow-arch-defs_SOURCE_DIR}")

  set(DEPENDS_LIST "")
  set(REAL_SOURCE_LIST "")
  foreach(SRC ${V2X_SRCS})
    if(NOT "${SRC}" MATCHES "\\.sim\\.v$")
      message(FATAL_ERROR "File ${SRC} does not end with .sim.v")
    endif()

    APPEND_FILE_DEPENDENCY(DEPENDS_LIST ${SRC})
    APPEND_FILE_INCLUDES(INCLUDES ${SRC})
  endforeach()

  list(GET V2X_SRCS 0 FIRST_SOURCE_FILE)
  GET_FILE_LOCATION(FIRST_SOURCE ${FIRST_SOURCE_FILE})

  set(TOP_ARG "")
  if(NOT ${V2X_TOP_MODULE} STREQUAL "")
    set(TOP_ARG "--top=${TOP_MODULE}")
  endif()

  string(REPLACE ";" "," INCLUDES_LIST "${INCLUDES}")

  set(INCLUDE_ARG "")
  if(NOT "${INCLUDES_LIST}" STREQUAL "")
    set(INCLUDE_ARG "--includes=${INCLUDES_LIST}")
  endif()

  add_custom_command(
    OUTPUT "${V2X_NAME}.pb_type.xml"
    DEPENDS ${DEPENDS_LIST} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py ${TOP_ARG} -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml ${FIRST_SOURCE} ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
    )

  MAKE_FILE_TARGET(FILE "${V2X_NAME}.pb_type.xml" GENERATED)

  add_custom_command(
    OUTPUT "${V2X_NAME}.model.xml"
    DEPENDS ${DEPENDS_LIST} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_model.py
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_model.py ${TOP_ARG} -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml ${FIRST_SOURCE} ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
    )

  MAKE_FILE_TARGET(FILE "${V2X_NAME}.model.xml" GENERATED)

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
    if(NOT "${MUX_GEN_SUBCKT}" STREQUAL "")
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
    list(APPEND MUX_GEN_ARGS "--comment=\"${MUX_GEN_COMMENT}\"")
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
    DEPENDS ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py ${symbiflow-arch-defs_SOURCE_DIR}/vpr/muxes/logic/mux${MUX_GEN_WIDTH}/mux${MUX_GEN_WIDTH}.sim.v
    COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py ${MUX_GEN_ARGS})

  MAKE_FILE_TARGET(FILE "${MUX_GEN_NAME}.sim.v"
    GENERATED)
  MAKE_FILE_TARGET(FILE "${MUX_GEN_NAME}.pb_type.xml"
    GENERATED)
  MAKE_FILE_TARGET(FILE "${MUX_GEN_NAME}.model.xml"
    GENERATED)

  add_custom_target(${MUX_GEN_NAME} ALL
    DEPENDS ${OUTPUTS}
      )

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
        DEPENDS ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py ${SRC} ${SRC_TARGET}
        COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py ${PREFIX} $<TARGET_PROPERTY:${SRC_TARGET},LOCATION> ${CMAKE_CURRENT_BINARY_DIR}/${SRC_WITH_PREFIX}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )

      MAKE_FILE_TARGET(FILE ${SRC_WITH_PREFIX} GENERATED
        DEPENDS ${SRC}
        )

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

function(get_target_property_required var target property)
  get_target_property(PROP ${target} ${property})
  if("${PROP}" STREQUAL "PROP-NOTFOUND")
    message(FATAL_ERROR "${property} not set for target ${target}, check target definition.")
  endif()
  if("${PROP}" STREQUAL "")
    message(FATAL_ERROR "${property} is empty for target ${target}, check target definition.")
  endif()
  set(${var} ${PROP} PARENT_SCOPE)
endfunction()

function(DEFINE_ARCH)
  set(options)
  set(oneValueArgs ARCH YOSYS_SCRIPT BITSTREAM_EXTENSION RR_PATCH_TOOL RR_PATCH_CMD)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_ARCH "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_ARCH_ARCH})
  foreach(ARG YOSYS_SCRIPT BITSTREAM_EXTENSION RR_PATCH_TOOL RR_PATCH_CMD)
    if("${DEFINE_ARCH_${ARG}}" STREQUAL "")
      message(FATAL_ERROR "Required argument ${ARG} is the empty string.")
    endif()
    set_target_properties(${DEFINE_ARCH_ARCH}
      PROPERTIES ${ARG} ${DEFINE_ARCH_${ARG}})
  endforeach()
endfunction()

function(DEFINE_DEVICE_TYPE)
  set(options)
  set(oneValueArgs DEVICE_TYPE ARCH ARCH_XML)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_DEVICE_TYPE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_DEVICE_TYPE_DEVICE_TYPE})
  foreach(ARG ARCH)
    if("${DEFINE_DEVICE_TYPE_${ARG}}" STREQUAL "")
      message(FATAL_ERROR "Required argument ${ARG} is the empty string.")
    endif()
    set_target_properties(${DEFINE_DEVICE_TYPE_DEVICE_TYPE}
      PROPERTIES ${ARG} ${DEFINE_DEVICE_TYPE_${ARG}})
  endforeach()

  ##########################################################################
  # Generate a arch.xml for a device.
  ##########################################################################
  set(DEVICE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}/devices)
  set(OUT_DEVICE_DIR ${DEVICE_DIR}/${DEFINE_DEVICE_TYPE_DEVICE_TYPE})
  set(DEVICE_MERGED_FILE ${OUT_DEVICE_DIR}/arch.xml)

  set(MERGE_XML_XSL ${symbiflow-arch-defs_SOURCE_DIR}/common/xml/xmlsort.xsl)
  set(MERGE_XML_INPUT ${CMAKE_CURRENT_BINARY_DIR}/${DEFINE_DEVICE_TYPE_ARCH_XML})
  GET_FILE_TARGET(MERGE_XML_INPUT_TARGET ${DEFINE_DEVICE_TYPE_ARCH_XML})
  set(MERGE_XML_OUTPUT ${DEVICE_MERGED_FILE})

  get_target_property_required(XSLTPROC env XSLTPROC)
  add_custom_command(
    OUTPUT ${MERGE_XML_OUTPUT}
    DEPENDS ${MERGE_XML_XSL} ${MERGE_XML_INPUT} ${MERGE_XML_INPUT_TARGET}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUT_DEVICE_DIR}
    COMMAND ${XSLTPROC} --nomkdir --nonet --xinclude --output ${MERGE_XML_OUTPUT} ${MERGE_XML_XSL} ${MERGE_XML_INPUT}
    )
  add_custom_target(
    ${DEFINE_DEVICE_TYPE_ARCH}_${DEFINE_DEVICE_TYPE_DEVICE_TYPE}_arch
    DEPENDS ${DEVICE_MERGED_FILE})

  MAKE_FILE_TARGET(
    FILE ${DEVICE_MERGED_FILE} GENERATED
    )

  set_target_properties(${DEFINE_DEVICE_TYPE_DEVICE_TYPE}
    PROPERTIES DEVICE_MERGED_FILE ${DEVICE_MERGED_FILE})

  ##########################################################################
  # Generate a rr_graph for a device.
  ##########################################################################

  # Generate the "default" rr_graph.xml we are going to patch using wire.
  set(OUT_RRXML_VIRT ${OUT_DEVICE_DIR}/rr_graph.virt.xml)
  get_target_property_required(VPR env VPR)
  add_custom_command(
    OUTPUT ${OUT_RRXML_VIRT} ${OUT_DEVICE_DIR}/rr_graph.virt.out
    DEPENDS ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif ${DEVICE_MERGED_FILE}
    COMMAND ${VPR}
      ${DEVICE_MERGED_FILE}
      --device ${DEVICE_FULL}
      ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif
      --route_chan_width 100
      --echo_file on
      --min_route_chan_width_hint 1
      --write_rr_graph ${OUT_RRXML_VIRT}
    COMMAND ${CMAKE_COMMAND} -E remove ${OUT_DEVICE_DIR}/wire.{net,place,route}
    COMMAND ${CMAKE_COMMAND} -E move ${OUT_DEVICE_DIR}/vpr_stdout.log ${OUT_DEVICE_DIR}/rr_graph.virt.out
    WORKING_DIRECTORY ${OUT_DEVICE_DIR}
    )

  MAKE_FILE_TARGET(
    FILE ${OUT_RRXML_VIRT} GENERATED
    )

  set_target_properties(${DEFINE_DEVICE_TYPE_DEVICE_TYPE}
    PROPERTIES OUT_RRXML_VIRT ${OUT_RRXML_VIRT})

endfunction()

function(DEFINE_DEVICE)
  set(options)
  set(oneValueArgs DEVICE ARCH DEVICE_TYPE ARCH_XML PACKAGES)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_DEVICE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_DEVICE_DEVICE})
  foreach(ARG ARCH DEVICE_TYPE)
    if("${DEFINE_DEVICE_${ARG}}" STREQUAL "")
      message(FATAL_ERROR "Required argument ${ARG} is the empty string.")
    endif()
    set_target_properties(${DEFINE_DEVICE_DEVICE}
      PROPERTIES ${ARG} ${DEFINE_DEVICE_${ARG}})
  endforeach()

  get_target_property_required(RR_PATCH_TOOL ${DEFINE_DEVICE_ARCH} RR_PATCH_TOOL)
  get_target_property_required(RR_PATCH_CMD ${DEFINE_DEVICE_ARCH} RR_PATCH_CMD)

  set(DEVICE ${DEFINE_DEVICE_DEVICE})
  get_target_property_required(OUT_RRXML_VIRT ${DEFINE_DEVICE_DEVICE_TYPE} OUT_RRXML_VIRT)
  set(OUT_RRXML_REAL ${OUT_DEVICE_DIR}/${DEFINE_DEVICE_DEVICE}_rr_graph.real.xml)
  string(CONFIGURE ${RR_PATCH_CMD} RR_PATCH_CMD_FOR_TARGET)

  set(RR_PATCH_DEPS "")
  foreach(IN ${OUT_RRXML_VIRT} ${DEVICE_MERGED_FILE})
    list(APPEND RR_PATCH_DEPS ${IN})
    GET_FILE_TARGET(IN_TARGET ${IN})
    list(APPEND RR_PATCH_DEPS ${IN_TARGET})
  endforeach()

  # Generate the "real" rr_graph.xml from the default rr_graph.xml file
  add_custom_command(
    OUTPUT ${OUT_RRXML_REAL}
    DEPENDS ${RR_PATCH_DEPS} ${RR_PATCH_TOOL}
    COMMAND ${RR_PATCH_CMD_FOR_TARGET}
    )

  MAKE_FILE_TARGET(
    FILE ${OUT_RRXML_REAL} GENERATED
    )

  set_target_properties(${DEFINE_DEVICE_DEVICE}
    PROPERTIES OUT_RRXML_REAL ${OUT_RRXML_REAL})
endfunction()

function(DEFINE_BOARD)
  set(options)
  set(oneValueArgs BOARD DEVICE PACKAGE PROG_TOOL PROG_CMD)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_BOARD "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_BOARD_BOARD})
  foreach(ARG DEVICE PACKAGE PROG_TOOL PROG_CMD)
    set_target_properties(${DEFINE_BOARD_BOARD}
      PROPERTIES ${ARG} "${DEFINE_BOARD_${ARG}}")
  endforeach()
endfunction()

function(ADD_FPGA_TARGET)
  set(options)
  set(oneValueArgs NAME TOP BOARD INPUT_IO_FILE)
  set(multiValueArgs SOURCES TESTBENCH_SOURCES)
  cmake_parse_arguments(ADD_FPGA_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(TOP "top")
  if(NOT ${ADD_FPGA_TARGET_TOP} STREQUAL "")
    set(TOP ${ADD_FPGA_TARGET_TOP})
  endif()

  set(BOARD ${ADD_FPGA_TARGET_BOARD})
  get_target_property_required(DEVICE ${BOARD} DEVICE)
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(DEVICE_TYPE ${DEVICE} DEVICE_TYPE)
  get_target_property_required(PACKAGE ${BOARD} PACKAGE)

  get_target_property_required(BITSTREAM_EXTENSION ${ARCH} BITSTREAM_EXTENSION)
  get_target_property_required(YOSYS_SCRIPT ${ARCH} YOSYS_SCRIPT)

  get_target_property_required(DEVICE_MERGED_FILE ${DEVICE_TYPE} DEVICE_MERGED_FILE)
  get_target_property_required(OUT_RRXML_REAL ${DEVICE} OUT_RRXML_REAL)

  set(DEVICE_FULL ${DEVICE}-${PACKAGE})
  set(FQDN ${ARCH}-${DEVICE_TYPE}-${DEVICE})
  set(OUT_LOCAL ${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${FQDN})
  set(NAME ${ADD_FPGA_TARGET_NAME})
  set(VPR_ROUTE_CHAN_WIDTH 100)
  set(VPR_ROUTE_CHAN_MINWIDTH_HINT ${VPR_ROUTE_CHAN_WIDTH})

  ##########################################################################
  # Generate BLIF as start of vpr input.
  ##########################################################################
  set(OUT_EBLIF ${OUT_LOCAL}/${TOP}.eblif)

  set(SOURCE_FILES ${ADD_FPGA_TARGET_SOURCES})
  set(SOURCE_INPUT "")

  add_custom_command(
    OUTPUT ${OUT_EBLIF}
    DEPENDS ${SOURCE_FILES}
    COMMAND ${YOSYS} -p "${YOSYS_SCRIPT}; write_blif -attr -cname -param ${OUT_EBLIF}" ${SOURCE_FILES}
    )
  add_custom_target(
    ${NAME}_eblif
    DEPENDS ${OUT_EBLIF})
  add_custom_target(
    ${NAME}_synth
    DEPENDS ${OUT_EBLIF})

  # Generate routing and generate HLC.
  set(OUT_ROUTE $(OUT_LOCAL)/${TOP}.route)
  set(OUT_HLC ${OUT_LOCAL}/${TOP}.hlc)

  set(VPR_DEPS "")
  list(APPEND VPR_DEPS ${OUT_EBLIF})

  foreach(DEVICE_SRC ${DEVICE_MERGED_FILE} ${OUT_RRXML_REAL})
    list(APPEND VPR_DEPS ${DEVICE_SRCS})
    GET_FILE_TARGET(DEVICE_SRC_TARGET ${DEVICE_SRC})
    list(APPEND VPR_DEPS ${DEVICE_SRC_TARGET})
  endforeach()

  get_target_property_required(VPR env VPR)
  set(VPR_CMD
    ${VPR}
      ${DEVICE_MERGED_FILE}
      ${OUT_EBLIF}
      --device ${DEVICE_FULL}
      --min_route_chan_width_hint ${VPR_ROUTE_CHAN_MINWIDTH_HINT}
      --route_chan_width ${VPR_ROUTE_CHAN_WIDTH}
      --read_rr_graph ${OUT_RRXML_REAL}
      --verbose_sweep on
      --allow_unrelated_clustering off
      --max_criticality 0.0
      --target_ext_pin_util 0.7
      --max_router_iterations 500
      --routing_failure_predictor off
      --clock_modeling route
      --constant_net_method route)

  # Generate IO constraints file.
  #-------------------------------------------------------------------------
  set(OUT_IO "")
  if(NOT ${ADD_FPGA_TARGET_INPUT_IO_FILE} STREQUAL "")
    set(INPUT_IO_FILE ${ADD_FPGA_TARGET_INPUT_IO_FILE})
    get_target_property_required(PLACE_TOOL ${ARCH} PLACE_TOOL)
    get_target_property_required(PLACE_TOOL_CMD ${ARCH} PLACE_TOOL_CMD)
    set(OUT_IO ${OUT_LOCAL}/io.place)
    string(CONFIGURE ${PLACE_TOOL_CMD} PLACE_TOOL_CMD_FOR_TARGET)
    add_custom_command(
      OUTPUT ${OUT_IO}
      DEPENDS ${OUT_EBLIF} ${ADD_FPGA_TARGET_INPUT_IO_FILE} ${VPR_DEPS}
      COMMAND ${PLACE_TOOL_CMD} --out ${OUT_IO}
      COMMAND ${CMAKE_COMMAND} -E copy ${OUT_LOCAL}/vpr_stdout.log ${OUT_LOCAL}/io.log
      WORKING_DIRECTORY ${OUT_LOCAL}
      )

    set(VPR_CMD ${VPR_CMD} --fix_pins ${OUT_IO})
  endif()

  # Generate packing.
  #-------------------------------------------------------------------------
  set(OUT_NET ${OUT_LOCAL}/${TOP}.net)
  add_custom_command(
    OUTPUT ${OUT_NET}
    DEPENDS ${OUT_EBLIF} ${OUT_IO} ${VPR_DEPS}
    COMMAND ${VPR_CMD} --pack --place
    COMMAND ${CMAKE_COMMAND} -E copy ${OUT_LOCAL}/vpr_stdout.log ${OUT_LOCAL}/pack.log
    WORKING_DIRECTORY ${OUT_LOCAL}
    )

  # Generate placement.
  #-------------------------------------------------------------------------
  set(OUT_PLACE ${OUT_LOCAL}/${TOP}.place)
  add_custom_command(
    OUTPUT ${OUT_PLACE}
    DEPENDS ${OUT_NET} ${OUT_IO} ${VPR_DEPS}
    COMMAND ${VPR_CMD} --place
    COMMAND ${CMAKE_COMMAND} -E copy ${OUT_LOCAL}/vpr_stdout.log ${OUT_LOCAL}/place.log
    )

  # Generate routing.
  #-------------------------------------------------------------------------
  add_custom_command(
    OUTPUT ${OUT_ROUTE} ${OUT_HLC}
    DEPENDS ${OUT_PLACE} ${OUT_IO} ${VPR_DEPS}
    COMMAND ${VPR_CMD} --route
    WORKING_DIRECTORY ${OUT_LOCAL}
    )

  add_custom_target(
    ${NAME}_route
    DEPENDS ${OUT_ROUTE})

  # Generate bitstream
  #-------------------------------------------------------------------------
  set(OUT_BITSTREAM ${OUT_LOCAL}/${TOP}.${BITSTREAM_EXTENSION})
  string(CONFIGURE ${HLC_TO_BIT_CMD} HLC_TO_BIT_CMD_FOR_TARGET)
  add_custom_command(
    OUTPUT ${OUT_BITSTREAM}
    DEPENDS ${OUT_HLC} ${HLC_TO_BIT_CMD}
    COMMAND ${HLC_TO_BIT_CMD_FOR_TARGET}
    )
endfunction()



add_subdirectory(vpr)
add_subdirectory(artix7)
add_subdirectory(ice40)
add_subdirectory(testarch)
