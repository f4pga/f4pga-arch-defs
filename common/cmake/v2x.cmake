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
  # utilities in <root>/ ./third_party/../python-symbiflow-v2x/v2x/vlog_to_<x>.
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
  list(APPEND DEPENDS_LIST ${PYTHON3})

  get_target_property_required(YOSYS env YOSYS)
  list(APPEND DEPENDS_LIST ${YOSYS})

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
    COMMAND
    ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}
      ${PYTHON3} -m v2x --mode=pb_type ${TOP_ARG}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.pb_type.xml ${FIRST_SOURCE}
      ${INCLUDE_ARG}
  )
  add_file_target(FILE "${V2X_NAME}.pb_type.xml" GENERATED)
  get_file_target(SRC_TARGET_NAME "${V2X_NAME}.pb_type.xml")
  set_target_properties(${SRC_TARGET_NAME} PROPERTIES INCLUDE_FILES "${PB_TYPE_INCLUDE_FILES}")

  add_custom_command(
    OUTPUT "${V2X_NAME}.model.xml"
    DEPENDS
      ${DEPENDS_LIST}
    COMMAND
    ${CMAKE_COMMAND} -E env YOSYS=${YOSYS}
      ${PYTHON3} -m v2x --mode=model ${TOP_ARG}
      -o ${CMAKE_CURRENT_BINARY_DIR}/${V2X_NAME}.model.xml ${FIRST_SOURCE}
      ${INCLUDE_ARG}
  )
  add_file_target(FILE "${V2X_NAME}.model.xml" GENERATED)
  get_file_target(SRC_TARGET_NAME "${V2X_NAME}.model.xml")
  set_target_properties(${SRC_TARGET_NAME} PROPERTIES INCLUDE_FILES "${MODEL_INCLUDE_FILES}")

  get_rel_target(REL_V2X_NAME v2x ${V2X_NAME})
  add_custom_target(
    ${REL_V2X_NAME}
    DEPENDS
        "${V2X_NAME}.model.xml"
        "${V2X_NAME}.pb_type.xml"
  )

endfunction(V2X)

function(VPR_TEST_PB_TYPE)
  # ~~~
  # VPR_TEST_PB_TYPE(
  #   NAME name
  #   TOP_MODULE name
  #   )
  # ~~~
  #
  # Run the pb_type.xml file through vpr to check it is valid.
  set(options)
  set(oneValueArgs NAME TOP_MODULE)
  set(multiValueArgs)
  cmake_parse_arguments(
    VPR_TEST_PB_TYPE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(XMLLINT env XMLLINT)

  set(DEPENDS_ARCH "")
  append_file_dependency(DEPENDS_ARCH "${symbiflow-arch-defs_SOURCE_DIR}/utils/template.arch.xml")
  append_file_dependency(DEPENDS_ARCH "${VPR_TEST_PB_TYPE_NAME}.pb_type.xml")
  append_file_dependency(DEPENDS_ARCH "${VPR_TEST_PB_TYPE_NAME}.model.xml")
  add_custom_command(
    OUTPUT "${VPR_TEST_PB_TYPE_NAME}.arch.xml"
    DEPENDS
      ${PYTHON3}
      ${XMLLINT}
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_pbtype_arch_wrapper.py
      ${DEPENDS_ARCH}
    COMMAND
      ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vpr_pbtype_arch_wrapper.py
      --pb_type ${CMAKE_CURRENT_BINARY_DIR}/${VPR_TEST_PB_TYPE_NAME}.pb_type.xml
      --output  ${CMAKE_CURRENT_BINARY_DIR}/${VPR_TEST_PB_TYPE_NAME}.arch.xml
      --xmllint ${XMLLINT}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils
  )
  add_file_target(FILE "${VPR_TEST_PB_TYPE_NAME}.arch.xml" GENERATED)

  set(DEPENDS_EBLIF "")
  append_file_dependency(DEPENDS_EBLIF "${VPR_TEST_PB_TYPE_NAME}.sim.v")
  set(TECHMAP_DEP "")
  append_file_dependency(TECHMAP_DEP "${VPR_TEST_PB_TYPE_NAME}.techmap.merged.v")

  set(PB_TYPE_VERILOG "${VPR_TEST_PB_TYPE_NAME}.sim.v")
  set(PB_TYPE_TECHMAP "${VPR_TEST_PB_TYPE_NAME}.techmap.merged.v")
  set(YOSYS_OUTPUT_BLIF "${VPR_TEST_PB_TYPE_NAME}.test.eblif")

  get_target_property_required(YOSYS env YOSYS)
  add_custom_command(
    OUTPUT "${YOSYS_OUTPUT_BLIF}"
    DEPENDS
      ${YOSYS}
      ${DEPENDS_EBLIF} ${TECHMAP_DEP}
    COMMAND
    ${YOSYS} -p "read_verilog ${PB_TYPE_VERILOG}\; hierarchy -top ${VPR_TEST_PB_TYPE_TOP_MODULE}\; techmap -map ${PB_TYPE_TECHMAP}\; flatten\; proc\; opt\; write_blif ${YOSYS_OUTPUT_BLIF}"
    WORKING_DIRECTORY
      ${CMAKE_CURRENT_BINARY_DIR}
  )
  add_file_target(FILE "${VPR_TEST_PB_TYPE_NAME}.test.eblif" GENERATED)

  set(ARCH_MERGED_XML "${VPR_TEST_PB_TYPE_NAME}.arch.merged.xml")
  set(ARCH_TILES_XML "${VPR_TEST_PB_TYPE_NAME}.arch.tiles.xml")
  set(ARCH_TIMINGS_XML "${VPR_TEST_PB_TYPE_NAME}.arch.timings.xml")

  set(update_arch_tiles_py "${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_tiles.py")

  xml_canonicalize_merge(
    NAME ${VPR_TEST_PB_TYPE_NAME}_arch_merged
    FILE ${VPR_TEST_PB_TYPE_NAME}.arch.xml
    OUTPUT ${ARCH_MERGED_XML}
  )

  add_file_target(FILE ${ARCH_TILES_XML} GENERATED)
  add_custom_command(
    OUTPUT "${ARCH_TILES_XML}"
    DEPENDS
      ${PYTHON3}
      ${ARCH_MERGED_XML}
      ${update_arch_tiles_py}
    COMMAND
      ${PYTHON3} ${update_arch_tiles_py}
        --in_xml ${ARCH_MERGED_XML}
        --out_xml ${ARCH_TILES_XML}
  )

  update_arch_timings(INPUT ${ARCH_TILES_XML} OUTPUT ${ARCH_TIMINGS_XML})

  get_target_property_required(VPR env VPR)
  get_target_property_required(QUIET_CMD env QUIET_CMD)
  set(OUT_LOCAL_REL test_${VPR_TEST_PB_TYPE_NAME})
  set(OUT_LOCAL ${CMAKE_CURRENT_BINARY_DIR}/${OUT_LOCAL_REL})

  set(DEPENDS_TEST "")
  append_file_dependency(DEPENDS_TEST ${ARCH_TIMINGS_XML})
  append_file_dependency(DEPENDS_TEST ${VPR_TEST_PB_TYPE_NAME}.test.eblif)
  add_custom_command(
    OUTPUT
      ${OUT_LOCAL_REL}/vpr.stdout
    DEPENDS
      ${QUIET_CMD}
      ${VPR}
      ${DEPENDS_TEST}
    COMMAND
      ${CMAKE_COMMAND} -E make_directory ${OUT_LOCAL}
    COMMAND
      ${CMAKE_COMMAND} -E chdir ${OUT_LOCAL}
      ${QUIET_CMD} ${VPR}
      ${CMAKE_CURRENT_BINARY_DIR}/${ARCH_TIMINGS_XML}
      ${CMAKE_CURRENT_BINARY_DIR}/${VPR_TEST_PB_TYPE_NAME}.test.eblif
      --echo_file on
      --pack
      --pack_verbosity 100
      --place
      --route
      --device device
      --target_ext_pin_util 1.0,1.0
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )
  add_file_target(FILE "${OUT_LOCAL_REL}/vpr.stdout" GENERATED)

  get_rel_target(VPR_TEST_REL_NAME test ${VPR_TEST_PB_TYPE_NAME})
  add_custom_target(
    ${VPR_TEST_REL_NAME}
    DEPENDS
        "${OUT_LOCAL_REL}/vpr.stdout"
  )

  add_dependencies(all_vpr_test_pbtype ${VPR_TEST_REL_NAME})

endfunction(VPR_TEST_PB_TYPE)
