function(V2X)
  # ~~~
  # V2X(
  #   NAME <name>
  #   [TOP_MODULE <top module>]
  #   SRCS <src1> <src2>
  #   [DO_NOT_APPLY_VERILOG_IMAGE_GEN]
  #   )
  # ~~~
  #
  # V2X converts SRCS from verilog to .pb_type.xml and .model.xml via the
  # utilities in <root>/util/vlog/vlog_to_<x>.
  #
  # V2X requires all files in SRCS to have a file target via ADD_FILE_TARGET.
  #
  # V2X will generate a dummy target <name> that will build both xml outputs.
  #
  # By default V2X implicitly calls ADD_VERILOG_IMAGE_GEN for the input source
  # files.  DO_NOT_APPLY_VERILOG_IMAGE_GEN suppress this default.
  set(options DO_NOT_APPLY_VERILOG_IMAGE_GEN)
  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs SRCS)
  cmake_parse_arguments(
    V2X
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(INCLUDES "")

  set(DEPENDS_LIST "")
  set(MODEL_INCLUDE_FILES "")
  set(PB_TYPE_INCLUDE_FILES "")
  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)
  list(APPEND DEPENDS_LIST ${PYTHON3} ${PYTHON3_TARGET})

  get_target_property_required(YOSYS env YOSYS)
  get_target_property(YOSYS_TARGET env YOSYS_TARGET)
  list(APPEND DEPENDS_LIST ${YOSYS} ${YOSYS_TARGET})

  set(REAL_SOURCE_LIST "")
  foreach(SRC ${V2X_SRCS})
    if(NOT "${SRC}" MATCHES "\\.sim\\.v$")
      message(FATAL_ERROR "File ${SRC} does not end with .sim.v")
    endif()

    if(NOT ${V2X_DO_NOT_APPLY_VERILOG_IMAGE_GEN})
      add_verilog_image_gen(FILE ${SRC})
    endif()

    append_file_dependency(DEPENDS_LIST ${SRC})
    append_file_includes(INCLUDES ${SRC})

    get_file_target(SRC_TARGET ${SRC})
    get_target_property(INCLUDE_FILES ${SRC_TARGET} INCLUDE_FILES)
    foreach(INCLUDE_SRC ${INCLUDE_FILES})
      get_filename_component(INCLUDE_SRC_DIR ${INCLUDE_SRC} DIRECTORY)
      get_filename_component(INCLUDE_ROOT ${INCLUDE_SRC} NAME_WE)

      append_file_dependency(DEPENDS_LIST ${INCLUDE_SRC_DIR}/${INCLUDE_ROOT}.model.xml)
      append_file_dependency(DEPENDS_LIST ${INCLUDE_SRC_DIR}/${INCLUDE_ROOT}.pb_type.xml)
      list(APPEND MODEL_INCLUDE_FILES ${INCLUDE_SRC_DIR}/${INCLUDE_ROOT}.model.xml)
      list(APPEND PB_TYPE_INCLUDE_FILES ${INCLUDE_SRC_DIR}/${INCLUDE_ROOT}.pb_type.xml)
    endforeach()
  endforeach()

  list(GET V2X_SRCS 0 FIRST_SOURCE_FILE)
  get_file_location(FIRST_SOURCE ${FIRST_SOURCE_FILE})

  set(TOP_ARG "")
  if(NOT ${V2X_TOP_MODULE} STREQUAL "")
    set(TOP_ARG "--top=${V2X_TOP_MODULE}")
  endif()

  string(
    REPLACE
      ";"
      ","
      INCLUDES_LIST
      "${INCLUDES}"
  )

  set(INCLUDE_ARG "")
  if(NOT "${INCLUDES_LIST}" STREQUAL "")
    set(INCLUDE_ARG "--includes=${INCLUDES_LIST}")
  endif()

  add_custom_command(
    OUTPUT "${V2X_NAME}.pb_type.xml"
    DEPENDS
      ${DEPENDS_LIST}
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py
    COMMAND
      ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}  ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py ${TOP_ARG}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml ${FIRST_SOURCE}
      ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
  )
  add_file_target(FILE "${V2X_NAME}.pb_type.xml" GENERATED)
  get_file_target(SRC_TARGET_NAME "${V2X_NAME}.pb_type.xml")
  set_target_properties(${SRC_TARGET_NAME} PROPERTIES INCLUDE_FILES "${PB_TYPE_INCLUDE_FILES}")

  add_custom_command(
    OUTPUT "${V2X_NAME}.model.xml"
    DEPENDS
      ${DEPENDS_LIST}
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_model.py
    COMMAND
      ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}  ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_model.py ${TOP_ARG}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml ${FIRST_SOURCE}
      ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
  )
  add_file_target(FILE "${V2X_NAME}.model.xml" GENERATED)
  get_file_target(SRC_TARGET_NAME "${V2X_NAME}.model.xml")
  set_target_properties(${SRC_TARGET_NAME} PROPERTIES INCLUDE_FILES "${MODEL_INCLUDE_FILES}")

  add_custom_command(
    OUTPUT "${V2X_NAME}.arch.xml"
    DEPENDS
      ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml
      ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_pbtype_arch_wrapper.py
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/template.arch.xml
    COMMAND
      ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}  ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_pbtype_arch_wrapper.py
      --pb_type ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml
      --model   ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml
      --output  ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.arch.xml
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
  )
  add_file_target(FILE "${V2X_NAME}.arch.xml" GENERATED)

  add_custom_command(
    OUTPUT "${V2X_NAME}.test.eblif"
    DEPENDS
      ${DEPENDS_LIST}
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_test_eblif.py
    COMMAND
      ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}  ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_test_eblif.py ${TOP_ARG}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.test.eblif ${FIRST_SOURCE}
      ${INCLUDE_ARG}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/
  )
  add_file_target(FILE "${V2X_NAME}.test.eblif" GENERATED)

  xml_sort(
    NAME ${V2X_NAME}_arch_merged
    FILE ${V2X_NAME}.arch.xml
    OUTPUT ${V2X_NAME}.arch.merged.xml
  )

  get_target_property_required(VPR env VPR)
  get_target_property(VPR_TARGET env VPR_TARGET)

  add_custom_command(
    OUTPUT
      ${V2X_NAME}.vpr.stdout
    DEPENDS
      ${V2X_NAME}.arch.merged.xml
      ${V2X_NAME}.test.eblif
      ${QUIET_CMD} ${QUIET_CMD_TARGET}
      ${VPR} ${VPR_TARGET}
    COMMAND
      ${QUIET_CMD} ${VPR} ${V2X_NAME}.arch.merged.xml
      ${V2X_NAME}.test.eblif
      --route_chan_width 100
      --min_route_chan_width_hint 1
      --outfile_prefix ${V2X_NAME}
      --pack
      --place
      --route
    COMMAND
      ${CMAKE_COMMAND} -E copy vpr_stdout.log
      ${V2X_NAME}.vpr.stdout
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
  add_file_target(FILE "${V2X_NAME}.vpr.stdout" GENERATED)
  add_custom_target(
    ${V2X_NAME}_arch_test
    DEPENDS
     "${V2X_NAME}.vpr.stdout"
  )

  add_custom_target(
    ${V2X_NAME}
    DEPENDS
        "${V2X_NAME}.model.xml"
        "${V2X_NAME}.pb_type.xml"
        "${V2X_NAME}.arch.xml"
        "${V2X_NAME}.test.eblif"
        "${V2X_NAME}.vpr.stdout"
  )

endfunction(V2X)
