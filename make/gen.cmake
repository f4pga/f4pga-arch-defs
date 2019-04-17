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
    endforeach()
  endforeach()

  list(GET V2X_SRCS 0 FIRST_SOURCE_FILE)
  get_file_location(FIRST_SOURCE ${FIRST_SOURCE_FILE})

  set(TOP_ARG "")
  if(NOT ${V2X_TOP_MODULE} STREQUAL "")
    set(TOP_ARG "--top=${TOP_MODULE}")
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

  add_custom_target(
    ${V2X_NAME}
    DEPENDS "${V2X_NAME}.model.xml" "${V2X_NAME}.pb_type.xml"
  )
endfunction(V2X)

function(MUX_GEN)
  # ~~~
  # MUX_GEN(
  #   NAME <name>
  #   TYPE "routing"|"logic"
  #   MUX_NAME <name of mux>
  #   WIDTH <mux width>
  #   [SPLIT_INPUTS]
  #   [INPUTS <comma seperate list of inputs>]
  #   [SPLIT_SELECTS]
  #   [SELECTS <comma seperate list of selects>]
  #   [SUBCKT <subckt>]
  #   [COMMENT <comment>]
  #   [OUTPUT <mux output name>]
  #   [DATA_WIDTH <data width>]
  #   [NTEMPLATE_PREFIXES <list of prefixes>]
  #   )
  # ~~~
  #
  # Generate <name>.sim.v, <name>.pb_type.xml, and <name>.model.xml for mux with
  # given parameters using <root>/utils/mux_gen.py. A target <name> will be
  # created that will generate all outputs.
  #
  # If <name> starts with "ntemplate.", NTEMPLATE_PREFIXES can be used to call
  # N_TEMPLATE function on each output with the specified prefixes.
  #
  # For other mux arguments, see <root>/utils/mux_gen.py for details.
  set(options SPLIT_INPUTS SPLIT_SELECTS)
  set(
    oneValueArgs
    NAME
    MUX_NAME
    TYPE
    WIDTH
    INPUTS
    SELECTS
    SUBCKT
    COMMENT
    OUTPUT
    DATA_WIDTH
  )
  set(multiValueArgs NTEMPLATE_PREFIXES)
  cmake_parse_arguments(
    MUX_GEN
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if("${MUX_GEN_TYPE}" STREQUAL "routing")
    if(NOT "${MUX_GEN_SUBCKT}" STREQUAL "")
      message(
        FATAL_ERROR "Can not use SUBCKT=${MUX_GEN_SUBCKT} with routing mux."
      )
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
  list(
    APPEND
      OUTPUTS
      "${MUX_GEN_NAME}.sim.v"
      "${MUX_GEN_NAME}.pb_type.xml"
      "${MUX_GEN_NAME}.model.xml"
  )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  add_custom_command(
    OUTPUT ${OUTPUTS}
    DEPENDS
      ${PYTHON3} ${PYTHON3_TARGET}
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py
      ${symbiflow-arch-defs_SOURCE_DIR}/vpr/muxes/logic/mux${MUX_GEN_WIDTH}/mux${MUX_GEN_WIDTH}.sim.v
    COMMAND ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/mux_gen.py ${MUX_GEN_ARGS}
  )

  add_file_target(FILE "${MUX_GEN_NAME}.sim.v" GENERATED)
  add_file_target(FILE "${MUX_GEN_NAME}.pb_type.xml" GENERATED)
  add_file_target(FILE "${MUX_GEN_NAME}.model.xml" GENERATED)

  add_custom_target(${MUX_GEN_NAME} DEPENDS ${OUTPUTS})

  if(NOT "${MUX_GEN_NTEMPLATE_PREFIXES}" STREQUAL "")
    foreach(OUTPUT ${OUTPUTS})
      string(
        REPLACE
          "ntemplate."
          ""
          N_TEMPLATE_NAME
          ${OUTPUT}
      )
      n_template(
        NAME ${N_TEMPLATE_NAME}
        PREFIXES ${MUX_GEN_NTEMPLATE_PREFIXES}
        SRCS ${OUTPUT}
      )
    endforeach()
  endif()
endfunction(MUX_GEN)

function(N_TEMPLATE)
  # ~~~
  # N_TEMPLATE(
  #   NAME <name>
  #   SRCS <list of sources>
  #   PREFIXES <list of prefixes>
  #   [APPLY_V2X]
  #   [APPLY_VERILOG_IMAGE_GEN]
  #   )
  # ~~~
  #
  # N_TEMPLATE converts files with prefix ntemplate.<rest> to <rest> and applies
  # the template prefix, converting all N's to <prefix>.
  #
  # If APPLY_V2X is set, V2X will be invoked with NAME = <prefix><name> and the
  # output of the templating process.
  #
  # If APPLY_VERILOG_IMAGE_GEN, ADD_VERILOG_IMAGE_GEN will be invoked with each
  # output file.
  set(options APPLY_V2X APPLY_VERILOG_IMAGE_GEN)
  set(oneValueArgs NAME)
  set(multiValueArgs SRCS PREFIXES)
  cmake_parse_arguments(
    N_TEMPLATE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(OUTPUTS "")
  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  foreach(PREFIX ${N_TEMPLATE_PREFIXES})
    foreach(SRC ${N_TEMPLATE_SRCS})
      set(REAL_INCLUDE_FILES "")
      string(
        REPLACE
          "ntemplate."
          ""
          SRC_NO_NTEMPLATE
          ${SRC}
      )
      string(
        REPLACE
          "N"
          ${PREFIX}
          SRC_WITH_PREFIX
          ${SRC_NO_NTEMPLATE}
      )
      get_file_target(SRC_TARGET_NAME ${SRC})
      get_target_property(SRC_INCLUDE_FILES ${SRC_TARGET_NAME} INCLUDE_FILES)
      foreach(INC ${SRC_INCLUDE_FILES})
        get_filename_component(INC_FILE ${INC} NAME)
        get_filename_component(INC_DIR ${INC} DIRECTORY)
        # template all the include files
        string(
          REPLACE
            "ntemplate."
            ""
            INC_NO_NTEMPLATE
            ${INC_FILE}
        )
        string(
          REPLACE
            "N"
            ${PREFIX}
            INC_WITH_PREFIX
            ${INC_NO_NTEMPLATE}
        )
        list(APPEND REAL_INCLUDE_FILES ${INC_DIR}/${INC_WITH_PREFIX})
      endforeach()
      get_file_location(SRC_LOCATION ${SRC})
      set(DEPS "")
      append_file_dependency(DEPS ${SRC})
      add_custom_command(
        OUTPUT ${SRC_WITH_PREFIX}
        DEPENDS
          ${PYTHON3} ${PYTHON3_TARGET}
          ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py ${SRC_LOCATION}
          ${DEPS}
        COMMAND
          ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/n.py ${PREFIX} ${SRC_LOCATION}
          ${CMAKE_CURRENT_BINARY_DIR}/${SRC_WITH_PREFIX}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )

      add_file_target(FILE ${SRC_WITH_PREFIX} GENERATED)
      get_file_target(SRC_TARGET_NAME ${SRC_WITH_PREFIX})
      set_target_properties(${SRC_TARGET_NAME} PROPERTIES INCLUDE_FILES "${REAL_INCLUDE_FILES}")

      list(APPEND OUTPUTS ${SRC_WITH_PREFIX})

      if(${N_TEMPLATE_APPLY_V2X})
        get_filename_component(V2X_NAME ${SRC_WITH_PREFIX} NAME_WE)
        v2x(NAME ${V2X_NAME} SRCS ${SRC_WITH_PREFIX})
      endif()
      if(${N_TEMPLATE_APPLY_VERILOG_IMAGE_GEN})
      endif()
    endforeach(SRC)
  endforeach(PREFIX)

  add_custom_target(${N_TEMPLATE_NAME} ALL DEPENDS ${OUTPUTS})
endfunction(N_TEMPLATE)
