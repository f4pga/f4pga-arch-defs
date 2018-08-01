# This CMake include defines the following functions:
#
# DEFINE_ARCH - Define an FPGA architecture and tools to use that architecture.
# DEFINE_DEVICE_TYPE - Define a device type within an FPGA architecture.
# DEFINE_DEVICE - Define a device and packaging for a specific device type
#                 and FPGA architecture.
# DEFINE_BOARD - Define a board that uses specific device and package.
# ADD_FPGA_TARGET - Creates a FPGA image build against a specific board.

function(DEFINE_ARCH)
  #  DEFINE_ARCH(
  #    ARCH <arch>
  #    YOSYS_SCRIPT <yosys_script>
  #    BITSTREAM_EXTENSION <ext>
  #    RR_PATCH_TOOL <path to rr_patch tool>
  #    RR_PATCH_CMD <command to run RR_PATCH_TOOL>
  #    PLACE_TOOL <path to place tool>
  #    PLACE_TOOL_CMD <command to run PLACE_TOOL>
  #    CELLS_SIM <path to verilog file used for simulation>
  #    EQUIV_CHECK_SCRIPT <yosys to script verify two bitstreams gold and gate>
  #    HLC_TO_BIT <path to HLC to bitstream converter>
  #    HLC_TO_BIT_CMD <command to run HLC_TO_BIT>
  #   )
  #
  #  DEFINE_ARCH defines an FPGA architecture. All arguments are required.
  #
  #  RR_PATCH_CMD, PLACE_TOOL_CMD and HLC_TO_BIT_CMD will all be called with
  #  string(CONFIGURE) to substitute variables.
  #
  #  RR_PATCH_CMD variables:
  #    RR_PATCH_TOOL - Value of RR_PATCH_TOOL property of <arch>.
  #    DEVICE - What device is being patch (see DEFINE_DEVICE).
  #    OUT_RRXML_VIRT - Input virtual rr_graph file for device.
  #    OUT_RRXML_REAL - Out real rr_graph file for device.
  #
  #  PLACE_TOOL_CMD variables:
  #    PLACE_TOOL - Value of PLACE_TOOL property of <arch>.
  #    PINMAP - Path to pinmap file.  This file will be retrieved from the
  #             ${PACKAGE}_PINMAP property of the ${DEVICE}.  ${DEVICE} and
  #             ${PACKAGE} will be defined by the BOARD being used.
  #             See DEFINE_BOARD.
  #    OUT_EBLIF - Input path to EBLIF file.
  #    INPUT_IO_FILE - Path to input io file, as specified by ADD_FPGA_TARGET.
  #
  #  HLC_TO_BIT_CMD variables:
  #    HLC_TO_BIT - Value of HLC_TO_BIT property of <arch>.
  #    OUT_HLC - Input path to HLC file.
  #    OUT_BITSTREAM - Output path to bitstream file.
  set(options)
  set(oneValueArgs ARCH YOSYS_SCRIPT BITSTREAM_EXTENSION RR_PATCH_TOOL RR_PATCH_CMD PLACE_TOOL PLACE_TOOL_CMD CELLS_SIM EQUIV_CHECK_SCRIPT HLC_TO_BIT HLC_TO_BIT_CMD)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_ARCH "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_ARCH_ARCH})
  foreach(ARG YOSYS_SCRIPT BITSTREAM_EXTENSION RR_PATCH_TOOL RR_PATCH_CMD PLACE_TOOL PLACE_TOOL_CMD CELLS_SIM EQUIV_CHECK_SCRIPT HLC_TO_BIT HLC_TO_BIT_CMD)
    if("${DEFINE_ARCH_${ARG}}" STREQUAL "")
      message(FATAL_ERROR "Required argument ${ARG} is the empty string.")
    endif()
    set_target_properties(${DEFINE_ARCH_ARCH}
      PROPERTIES ${ARG} "${DEFINE_ARCH_${ARG}}")
  endforeach()
endfunction()

function(DEFINE_DEVICE_TYPE)
  # DEFINE_DEVICE_TYPE(
  #   DEVICE_TYPE <device_type>
  #   ARCH <arch>
  #   ARCH_XML <arch.xml>
  #   )
  #
  # Defines a device type with the specified architecture.  ARCH_XML argument
  # must be a file target (see MAKE_FILE_TARGET).
  #
  # DEFINE_DEVICE_TYPE defines a dummy target <arch>_<device_type>_arch that
  # will build the merged architecture file for the device type.
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
  set(DEVICE_MERGED_FILE arch.merged.xml)

  set(MERGE_XML_XSL ${symbiflow-arch-defs_SOURCE_DIR}/common/xml/xmlsort.xsl)
  set(MERGE_XML_INPUT ${CMAKE_CURRENT_BINARY_DIR}/${DEFINE_DEVICE_TYPE_ARCH_XML})
  GET_FILE_TARGET(MERGE_XML_INPUT_TARGET ${DEFINE_DEVICE_TYPE_ARCH_XML})
  set(MERGE_XML_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${DEVICE_MERGED_FILE})

  get_target_property_required(XSLTPROC env XSLTPROC)
  add_custom_command(
    OUTPUT ${MERGE_XML_OUTPUT}
    DEPENDS ${MERGE_XML_XSL} ${MERGE_XML_INPUT} ${MERGE_XML_INPUT_TARGET}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${OUT_DEVICE_DIR}
    COMMAND ${XSLTPROC} --nomkdir --nonet --xinclude --output ${MERGE_XML_OUTPUT} ${MERGE_XML_XSL} ${MERGE_XML_INPUT}
    )
  add_custom_target(
    ${DEFINE_DEVICE_TYPE_ARCH}_${DEFINE_DEVICE_TYPE_DEVICE_TYPE}_arch
    DEPENDS ${DEVICE_MERGED_FILE})

  MAKE_FILE_TARGET(
    FILE ${DEVICE_MERGED_FILE} GENERATED
    )

  set_target_properties(${DEFINE_DEVICE_TYPE_DEVICE_TYPE}
    PROPERTIES DEVICE_MERGED_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${DEVICE_MERGED_FILE})

endfunction()

function(DEFINE_DEVICE)
  # DEFINE_DEVICE(
  #   DEVICE <device>
  #   ARCH <arch>
  #   DEVICE_TYPE <device_type>
  #   PACKAGES <list of packages>
  #   )
  #
  #  Defines a device within a specified FPGA architecture.
  #
  #  Creates dummy targets <arch>_<device>_<package>_rrxml_virt and
  #  <arch>_<device>_<package>_rrxml_virt  that generates the the virtual and
  #  real rr_graph for a specific device and package.
  #
  #  In order to use a device with ADD_FPGA_TARGET, the property
  #  ${PACKAGE}_PINMAP on target <device> must be set.
  set(options)
  set(oneValueArgs DEVICE ARCH DEVICE_TYPE PACKAGES)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_DEVICE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  add_custom_target(${DEFINE_DEVICE_DEVICE})
  foreach(ARG ARCH DEVICE_TYPE PACKAGES)
    if("${DEFINE_DEVICE_${ARG}}" STREQUAL "")
      message(FATAL_ERROR "Required argument ${ARG} is the empty string.")
    endif()
    set_target_properties(${DEFINE_DEVICE_DEVICE}
      PROPERTIES ${ARG} ${DEFINE_DEVICE_${ARG}})
  endforeach()

  get_target_property_required(RR_PATCH_TOOL ${DEFINE_DEVICE_ARCH} RR_PATCH_TOOL)
  get_target_property_required(RR_PATCH_CMD ${DEFINE_DEVICE_ARCH} RR_PATCH_CMD)

  get_target_property_required(VIRT_DEVICE_MERGED_FILE ${DEFINE_DEVICE_DEVICE_TYPE} DEVICE_MERGED_FILE)
  GET_FILE_TARGET(DEVICE_MERGED_FILE_TARGET ${VIRT_DEVICE_MERGED_FILE})
  GET_FILE_LOCATION(DEVICE_MERGED_FILE ${VIRT_DEVICE_MERGED_FILE})
  get_target_property_required(VPR env VPR)

  set(DEVICE ${DEFINE_DEVICE_DEVICE})
  foreach(PACKAGE ${DEFINE_DEVICE_PACKAGES})
    set(DEVICE_FULL ${DEVICE}-${PACKAGE})
    set(OUT_RRXML_VIRT_FILENAME rr_graph_${DEVICE}_${PACKAGE}.rr_graph.virt.xml)
    set(OUT_RRXML_REAL_FILENAME rr_graph_${DEVICE}_${PACKAGE}.rr_graph.real.xml)
    set(OUT_RRXML_VIRT ${CMAKE_CURRENT_BINARY_DIR}/${OUT_RRXML_VIRT_FILENAME})
    set(OUT_RRXML_REAL ${CMAKE_CURRENT_BINARY_DIR}/${OUT_RRXML_REAL_FILENAME})

    ##########################################################################
    # Generate a rr_graph for a device.
    ##########################################################################

    # Generate the "default" rr_graph.xml we are going to patch using wire.
    add_custom_command(
      OUTPUT ${OUT_RRXML_VIRT} rr_graph_${DEVICE}_${PACKAGE}.virt.out
      DEPENDS ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif ${DEVICE_MERGED_FILE} ${DEVICE_MERGED_FILE_TARGET}
      COMMAND ${VPR}
        ${DEVICE_MERGED_FILE}
        --device ${DEVICE}-${PACKAGE}
        ${symbiflow-arch-defs_SOURCE_DIR}/common/wire.eblif
        --route_chan_width 100
        --echo_file on
        --min_route_chan_width_hint 1
        --write_rr_graph ${OUT_RRXML_VIRT}
      COMMAND ${CMAKE_COMMAND} -E remove wire.{net,place,route}
      COMMAND ${CMAKE_COMMAND} -E copy vpr_stdout.log rr_graph_${DEVICE}_${PACKAGE}.virt.out
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      )
    add_custom_target(
      ${DEFINE_DEVICE_ARCH}_${DEFINE_DEVICE_DEVICE}_${PACKAGE}_rrxml_virt
      DEPENDS ${OUT_RRXML_VIRT})

    MAKE_FILE_TARGET(
      FILE ${OUT_RRXML_VIRT_FILENAME} GENERATED
      )

    set_target_properties(${DEFINE_DEVICE_DEVICE}
      PROPERTIES OUT_RRXML_VIRT ${CMAKE_CURRENT_SOURCE_DIR}/${OUT_RRXML_VIRT_FILENAME})

    set(RR_PATCH_DEPS "")
    list(APPEND RR_PATCH_DEPS ${DEVICE_MERGED_FILE})
    list(APPEND RR_PATCH_DEPS ${DEVICE_MERGED_FILE_TARGET})

    # Generate the "real" rr_graph.xml from the default rr_graph.xml file
    string(CONFIGURE ${RR_PATCH_CMD} RR_PATCH_CMD_FOR_TARGET)
    separate_arguments(RR_PATCH_CMD_FOR_TARGET_LIST UNIX_COMMAND ${RR_PATCH_CMD_FOR_TARGET})
    add_custom_command(
      OUTPUT ${OUT_RRXML_REAL}
      DEPENDS ${RR_PATCH_DEPS} ${RR_PATCH_TOOL} ${OUT_RRXML_VIRT}
      COMMAND ${RR_PATCH_CMD_FOR_TARGET_LIST}
      VERBATIM
      )

    MAKE_FILE_TARGET(
      FILE ${OUT_RRXML_REAL_FILENAME} GENERATED
      )

    set_target_properties(${DEFINE_DEVICE_DEVICE}
      PROPERTIES ${PACKAGE}_OUT_RRXML_REAL ${CMAKE_CURRENT_SOURCE_DIR}/${OUT_RRXML_REAL_FILENAME})

    add_custom_target(
      ${DEFINE_DEVICE_ARCH}_${DEFINE_DEVICE_DEVICE}_${PACKAGE}_rrxml_real
      DEPENDS ${OUT_RRXML_REAL}
      )
  endforeach()
endfunction()

function(DEFINE_BOARD)
  # DEFINE_BOARD(
  #   BOARD <board>
  #   DEVICE <device>
  #   PACKAGE <package>
  #   PROG_TOOL <prog_tool>
  #   [PROG_CMD <command to use PROG_TOOL>
  #   )
  #
  # Defines a target board for a project.  The listed device and package must
  # have been defined using DEFINE_DEVICE.
  #
  # PROG_TOOL should be an executable that will program a bitstream to the
  # specified board. PROG_CMD is an optional command string.  If PROG_CMD is
  # not provided, PROG_CMD will simply be ${PROG_TOOL}.
  #
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
  # ADD_FPGA_TARGET(
  #   NAME <name>
  #   TOP <top>
  #   BOARD <board>
  #   SOURCES <source list>
  #   TESTBENCH_SOURCES <testbench source list>
  #   [INPUT_IO_FILE <input_io_file>]
  #   [EXPLICIT_MAKE_FILE_TARGET]
  #   )
  #
  # ADD_FPGA_TARGET defines a FPGA build targetting a specific board.  By
  # default input files (SOURCES, TESTBENCH_SOURCES, INPUT_IO_FILE) will be
  # implicitly passed to MAKE_FILE_TARGET.  If EXPLICIT_MAKE_FILE_TARGET is
  # supplied, this behavior is supressed.
  #
  # The SOURCES file list will be used to synthesize the FPGA images.
  # INPUT_IO_FILE is required to define an io map.
  # TESTBENCH_SOURCES will be used to run test benches.
  #
  # Targets generated:
  #   <name>_eblif - Generate eblif file.
  #   <name>_synth - Alias of <name>_eblif.
  #   <name>_route - Generate place and routing synthesized design.
  #   <name>_bit - Generate output bitstream.
  #
  # Naming conventions:
  #
  #  Outputs for this target will all be located in
  # ${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${ARCH}-${DEVICE_TYPE}-${DEVICE}-${PACKAGE}
  #
  #  Output files:
  #    ${TOP}.eblif - Synthesized design
  #    ${TOP}_io.place - IO placement.
  #    ${TOP}.route - Place and routed design
  #    ${TOP}.hlc - Place and routed design
  #    ${TOP}.${BITSTREAM_EXTENSION} - Place and routed design
  #
  set(options EXPLICIT_MAKE_FILE_TARGET)
  set(oneValueArgs NAME TOP BOARD INPUT_IO_FILE)
  set(multiValueArgs SOURCES TESTBENCH_SOURCES)
  cmake_parse_arguments(ADD_FPGA_TARGET "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(TOP "top")
  if(NOT ${ADD_FPGA_TARGET_TOP} STREQUAL "")
    set(TOP ${ADD_FPGA_TARGET_TOP})
  endif()

  set(BOARD ${ADD_FPGA_TARGET_BOARD})
  if(${BOARD} STREQUAL "")
    message(FATAL_ERROR "BOARD is a required parameters.")
  endif()

  get_target_property_required(DEVICE ${BOARD} DEVICE)
  get_target_property_required(PACKAGE ${BOARD} PACKAGE)

  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(DEVICE_TYPE ${DEVICE} DEVICE_TYPE)

  get_target_property_required(BITSTREAM_EXTENSION ${ARCH} BITSTREAM_EXTENSION)
  get_target_property_required(YOSYS env YOSYS)
  get_target_property_required(YOSYS_SCRIPT ${ARCH} YOSYS_SCRIPT)

  get_target_property_required(DEVICE_MERGED_FILE ${DEVICE_TYPE} DEVICE_MERGED_FILE)
  get_target_property_required(OUT_RRXML_REAL ${DEVICE} ${PACKAGE}_OUT_RRXML_REAL)

  set(DEVICE_FULL ${DEVICE}-${PACKAGE})
  set(FQDN ${ARCH}-${DEVICE_TYPE}-${DEVICE}-${PACKAGE})
  set(OUT_LOCAL ${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${FQDN})
  set(DIRECTORY_TARGET ${NAME}-${FQDN}-make-directory)
  add_custom_target(${DIRECTORY_TARGET} ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUT_LOCAL})

  set(NAME ${ADD_FPGA_TARGET_NAME})
  set(VPR_ROUTE_CHAN_WIDTH 100)
  set(VPR_ROUTE_CHAN_MINWIDTH_HINT ${VPR_ROUTE_CHAN_WIDTH})

  if(NOT ${ADD_FPGA_TARGET_EXPLICIT_MAKE_FILE_TARGET})
    foreach(SRC ${ADD_FPGA_TARGET_SOURCES})
      MAKE_FILE_TARGET(
        FILE ${SRC}
        SCANNER_TYPE verilog
        )
    endforeach()
    foreach(SRC ${ADD_FPGA_TARGET_TESTBENCH_SOURCES})
      MAKE_FILE_TARGET(
        FILE ${SRC}
        SCANNER_TYPE verilog
        )
    endforeach()

    MAKE_FILE_TARGET(
      FILE ${ADD_FPGA_TARGET_INPUT_IO_FILE}
      )

  endif()

  ##########################################################################
  # Generate BLIF as start of vpr input.
  ##########################################################################
  set(OUT_EBLIF ${OUT_LOCAL}/${TOP}.eblif)

  set(SOURCE_FILES_DEPS "")
  set(SOURCE_FILES "")
  foreach(SRC ${ADD_FPGA_TARGET_SOURCES})
    GET_FILE_LOCATION(SRC_LOCATION ${SRC})
    GET_FILE_TARGET(SRC_TARGET ${SRC})
    list(APPEND SOURCE_FILES ${SRC_LOCATION})
    list(APPEND SOURCE_FILES_DEPS ${SRC_TARGET})
  endforeach()

  SET(COMPLETE_YOSYS_SCRIPT "${YOSYS_SCRIPT} $<SEMICOLON> write_blif -attr -cname -param ${OUT_EBLIF}")

  add_custom_command(
    OUTPUT ${OUT_EBLIF}
    DEPENDS ${SOURCE_FILES} ${SOURCE_FILES_DEPS} ${DIRECTORY_TARGET}
    COMMAND ${YOSYS} -p "${COMPLETE_YOSYS_SCRIPT}" ${SOURCE_FILES}
    VERBATIM
    )
  add_custom_target(
    ${NAME}_eblif
    DEPENDS ${OUT_EBLIF})
  add_custom_target(
    ${NAME}_synth
    DEPENDS ${OUT_EBLIF})

  # Generate routing and generate HLC.
  set(OUT_ROUTE ${OUT_LOCAL}/${TOP}.route)
  set(OUT_HLC ${OUT_LOCAL}/${TOP}.hlc)

  set(VPR_DEPS "")
  list(APPEND VPR_DEPS ${OUT_EBLIF})

  GET_FILE_LOCATION(OUT_RRXML_REAL_LOCATION ${OUT_RRXML_REAL})
  GET_FILE_LOCATION(DEVICE_MERGED_FILE_LOCATION ${DEVICE_MERGED_FILE})

  foreach(SRC ${DEVICE_MERGED_FILE} ${OUT_RRXML_REAL})
    GET_FILE_LOCATION(SRC_LOCATION ${SRC})
    GET_FILE_TARGET(SRC_TARGET ${SRC})
    list(APPEND VPR_DEPS ${SRC_LOCATION})
    list(APPEND VPR_DEPS ${SRC_TARGET})
  endforeach()

  get_target_property_required(VPR env VPR)
  set(VPR_CMD
    ${VPR}
      ${DEVICE_MERGED_FILE_LOCATION}
      ${OUT_EBLIF}
      --device ${DEVICE_FULL}
      --min_route_chan_width_hint ${VPR_ROUTE_CHAN_MINWIDTH_HINT}
      --route_chan_width ${VPR_ROUTE_CHAN_WIDTH}
      --read_rr_graph ${OUT_RRXML_REAL_LOCATION}
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
    GET_FILE_LOCATION(INPUT_IO_FILE ${ADD_FPGA_TARGET_INPUT_IO_FILE})
    GET_FILE_TARGET(INPUT_IO_FILE_TARGET ${ADD_FPGA_TARGET_INPUT_IO_FILE})
    get_target_property_required(PLACE_TOOL ${ARCH} PLACE_TOOL)
    get_target_property_required(PLACE_TOOL_CMD ${ARCH} PLACE_TOOL_CMD)
    get_target_property_required(PINMAP_FILE ${DEVICE} ${PACKAGE}_PINMAP)
    GET_FILE_LOCATION(PINMAP ${PINMAP_FILE})
    GET_FILE_TARGET(PINMAP_TARGET ${PINMAP_FILE})
    set(OUT_IO ${OUT_LOCAL}/${TOP}_io.place)
    string(CONFIGURE ${PLACE_TOOL_CMD} PLACE_TOOL_CMD_FOR_TARGET)
    separate_arguments(PLACE_TOOL_CMD_FOR_TARGET_LIST UNIX_COMMAND ${PLACE_TOOL_CMD_FOR_TARGET})
    add_custom_command(
      OUTPUT ${OUT_IO}
      DEPENDS ${OUT_EBLIF} ${INPUT_IO_FILE} ${INPUT_IO_FILE_TARGET} ${PINMAP} ${PINMAP_TARGET} ${VPR_DEPS}
      COMMAND ${PLACE_TOOL_CMD_FOR_TARGET_LIST} --out ${OUT_IO}
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
    WORKING_DIRECTORY ${OUT_LOCAL}
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

  get_target_property_required(HLC_TO_BIT ${ARCH} HLC_TO_BIT)
  get_target_property_required(HLC_TO_BIT_CMD ${ARCH} HLC_TO_BIT_CMD)
  string(CONFIGURE ${HLC_TO_BIT_CMD} HLC_TO_BIT_CMD_FOR_TARGET)
  separate_arguments(HLC_TO_BIT_CMD_FOR_TARGET_LIST UNIX_COMMAND ${HLC_TO_BIT_CMD_FOR_TARGET})
  add_custom_command(
    OUTPUT ${OUT_BITSTREAM}
    DEPENDS ${OUT_HLC} ${HLC_TO_BIT}
    COMMAND ${HLC_TO_BIT_CMD_FOR_TARGET_LIST}
    )

  add_custom_target(
    ${NAME}_bit ALL
    DEPENDS ${OUT_BITSTREAM}
    )
endfunction()
