add_conda_pip(
  NAME textx
  NO_EXE
)

function(ADD_XC7_BOARD)
  # ~~~
  # ADD_XC7_BOARD(
  #   BOARD <board>
  #   DEVICE <device>
  #   PACKAGE <package>
  #   PART <part>
  #   PROG_TOOL <prog_tool>
  #   [PROG_CMD <command to use PROG_TOOL>
  #   )
  # ~~~
  #
  # Defines a target board for a xc7 project.  The listed DEVICE must
  # have been defined using ADD_XC7_DEVICE_DEFINE.  Currently PACKAGE should
  # always be set to test.
  #
  # PART must be defined as the packaging of device.  This is used to defined
  # the package pin names and bitstream .yaml file to use.  To see available
  # parts, browse to third_party/prjxray-db/<arch>/*.yaml.
  #
  # PROG_TOOL should be an executable that will program a bitstream to the
  # specified board. PROG_CMD is an optional command string.  If PROG_CMD is not
  # provided, PROG_CMD will simply be ${PROG_TOOL}.
  #
  set(options)
  set(oneValueArgs BOARD DEVICE PACKAGE PROG_TOOL PROG_CMD PART)
  set(multiValueArgs)
  cmake_parse_arguments(
     ADD_XC7_BOARD
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  define_board(
    BOARD ${ADD_XC7_BOARD_BOARD}
    DEVICE ${ADD_XC7_BOARD_DEVICE}
    PACKAGE ${ADD_XC7_BOARD_PACKAGE}
    PROG_TOOL ${ADD_XC7_BOARD_PROG_TOOL}
    PROG_CMD ${ADD_XC7_BOARD_PROG_PROG_CMD}
    )

  set(DEVICE ${ADD_XC7_BOARD_DEVICE})
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(DEVICE_TYPE ${DEVICE} DEVICE_TYPE)
  get_target_property_required(USE_ROI ${DEVICE_TYPE} USE_ROI)
  set(BOARD ${ADD_XC7_BOARD_BOARD})
  set(PART ${ADD_XC7_BOARD_PART})

  set_target_properties(${BOARD}
    PROPERTIES PART ${PART}
    )
  set_target_properties(${BOARD}
    PROPERTIES BIT_TO_BIN_EXTRA_ARGS " \
    --part_name ${PART} \
    --part_file ${PRJXRAY_DB_DIR}/${ARCH}/${PART}.yaml \
  ")
  get_target_property_required(CHANNELS_DB ${DEVICE_TYPE} CHANNELS_DB)
  get_file_location(CHANNELS_LOCATION ${CHANNELS_DB})
  set_target_properties(${BOARD}
    PROPERTIES BIT_TO_V_EXTRA_ARGS " \
    --part ${PART}
    --connection_database ${CHANNELS_LOCATION}
  ")

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

  if(${USE_ROI})
    get_target_property_required(ROI_DIR ${DEVICE_TYPE} ROI_DIR)

    set_target_properties(${BOARD}
      PROPERTIES FASM_TO_BIT_EXTRA_ARGS " \
      --roi ${ROI_DIR}/design.json \
    ")

    get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
    get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
    set(SYNTH_TILES_TO_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_synth_tiles_to_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_synth_tiles_pinmap.csv)

    set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${SYNTH_TILES_TO_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${SYNTH_TILES})
    add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
    COMMAND ${PYTHON3} ${SYNTH_TILES_TO_PINMAP_CSV}
        --synth_tiles ${SYNTH_TILES_LOCATION}
        --package_pins ${PRJXRAY_DB_DIR}/${ARCH}/${PART}_package_pins.csv
        --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        DEPENDS ${PINMAP_CSV_DEPS}
        )
  else()
    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${CHANNELS_DB})

    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        --connection_database ${CHANNELS_LOCATION}
        --package_pins ${PRJXRAY_DB_DIR}/${ARCH}/${PART}_package_pins.csv
        --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        DEPENDS ${PINMAP_CSV_DEPS}
      )
  endif()

  add_file_target(FILE ${PINMAP_CSV} GENERATED)

  set_target_properties(
    ${BOARD}
    PROPERTIES
      PINMAP
      ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
  )
  set_target_properties(
    dummy_${ARCH}_${DEVICE}_${ADD_XC7_BOARD_PACKAGE}
    PROPERTIES
    PINMAP
    ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV})
endfunction()

function(ADD_XC7_DEVICE_DEFINE_TYPE)
  set(options)
  set(oneValueArgs ARCH DEVICE ROI_DIR GRAPH_LIMIT)
  set(multiValueArgs TILE_TYPES PB_TYPES)
  cmake_parse_arguments(
    ADD_XC7_DEVICE_DEFINE_TYPE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  set(ARCH ${ADD_XC7_DEVICE_DEFINE_TYPE_ARCH})
  set(DEVICE ${ADD_XC7_DEVICE_DEFINE_TYPE_DEVICE})
  set(ROI_DIR ${ADD_XC7_DEVICE_DEFINE_TYPE_ROI_DIR})
  set(TILE_TYPES ${ADD_XC7_DEVICE_DEFINE_TYPE_TILE_TYPES})

  if(NOT "${ROI_DIR}" STREQUAL "")
    set(ROI_ARGS USE_ROI ${ROI_DIR}/design.json)
    set(DEVICE_TYPE ${DEVICE}-roi-virt)
  elseif(NOT "${ADD_XC7_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}" STREQUAL "")
    set(DEVICE_TYPE ${DEVICE}-virt)
    set(ROI_ARGS GRAPH_LIMIT ${ADD_XC7_DEVICE_DEFINE_TYPE_GRAPH_LIMIT})
  else()
    set(DEVICE_TYPE ${DEVICE}-virt)
    set(ROI_ARGS "")
  endif()

  set(PB_TYPE_ARGS "")
  if(NOT "${ADD_XC7_DEVICE_DEFINE_TYPE_PB_TYPES}" STREQUAL "")
      set(PB_TYPE_ARGS PB_TYPES ${ADD_XC7_DEVICE_DEFINE_TYPE_PB_TYPES})
  endif()

  project_xray_arch(
    PART ${ARCH}
    DEVICE ${DEVICE}
    TILE_TYPES ${TILE_TYPES}
    ${ROI_ARGS}
    ${PB_TYPE_ARGS}
    )

  set(SDF_TIMING_DIRECTORY ${PRJXRAY_DB_DIR}/${ARCH}/timings)
  set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
  set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
  set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/xc7/bels.json)

  set(TIMING_IMPORT "${PYTHON3} ${UPDATE_ARCH_TIMINGS} --sdf_dir ${SDF_TIMING_DIRECTORY} --bels_map ${BELS_MAP} --out_arch /dev/stdout --input_arch /dev/stdin")
  set(TIMING_DEPS "")

  define_device_type(
    DEVICE_TYPE ${DEVICE_TYPE}
    ARCH ${ARCH}
    ARCH_XML arch.xml
    SCRIPT_OUTPUT_NAME timing
    SCRIPTS ${TIMING_IMPORT}
    SCRIPT_DEPS TIMING_DEPS
    )
  add_dependencies(${ARCH}_${DEVICE_TYPE}_arch arch_import_timing_deps)
  get_target_property_required(VIRT_DEVICE_MERGED_FILE ${DEVICE_TYPE} DEVICE_MERGED_FILE)
  get_file_target(DEVICE_MERGED_FILE_TARGET ${VIRT_DEVICE_MERGED_FILE})
  add_dependencies(${DEVICE_MERGED_FILE_TARGET} arch_import_timing_deps)
  if(NOT "${ROI_DIR}" STREQUAL "")
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_ROI TRUE
      ROI_DIR ${ROI_DIR}
      CHANNELS_DB ${CMAKE_CURRENT_SOURCE_DIR}/channels.db
      SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json
      )
  else()
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_ROI FALSE
      CHANNELS_DB ${CMAKE_CURRENT_SOURCE_DIR}/channels.db
      )
  endif()

  if(NOT "${ADD_XC7_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}" STREQUAL "")
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_GRAPH_LIMIT TRUE
      GRAPH_LIMIT "${ADD_XC7_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}"
      )
  else()
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_GRAPH_LIMIT FALSE
      )
  endif()
endfunction()

function(ADD_XC7_DEVICE_DEFINE)
  set(options USE_ROI)
  set(oneValueArgs ARCH)
  set(multiValueArgs DEVICES)
  cmake_parse_arguments(
    ADD_XC7_DEVICE_DEFINE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  set(USE_ROI ${ADD_XC7_DEVICE_DEFINE_USE_ROI})
  set(ARCH ${ADD_XC7_DEVICE_DEFINE_ARCH})
  set(DEVICES ${ADD_XC7_DEVICE_DEFINE_DEVICES})

  list(LENGTH DEVICES DEVICE_COUNT)
  math(EXPR DEVICE_COUNT_N_1 "${DEVICE_COUNT} - 1")
  foreach(INDEX RANGE ${DEVICE_COUNT_N_1})
    list(GET DEVICES ${INDEX} DEVICE)

    if(${USE_ROI})
        set(DEVICE_TYPE ${DEVICE}-roi-virt)
    else()
        set(DEVICE_TYPE ${DEVICE}-virt)
    endif()

    add_subdirectory(${DEVICE_TYPE})

    get_target_property_required(CHANNELS_DB ${DEVICE_TYPE} CHANNELS_DB)
    get_file_location(CHANNELS_LOCATION ${CHANNELS_DB})
    set(RR_PATCH_EXTRA_ARGS  --connection_database ${CHANNELS_LOCATION})

    # Clear variable before adding deps for next device
    set(DEVICE_RR_PATCH_DEPS "")
    list(APPEND DEVICE_RR_PATCH_DEPS intervaltree textx)
    append_file_dependency(DEVICE_RR_PATCH_DEPS ${CHANNELS_DB})

    if(${USE_ROI})
        # SYNTH_TILES used in ROI.
        get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
        get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
        append_file_dependency(DEVICE_RR_PATCH_DEPS ${SYNTH_TILES})
        set(RR_PATCH_EXTRA_ARGS --synth_tiles ${SYNTH_TILES_LOCATION} ${RR_PATCH_EXTRA_ARGS})
    endif()

    get_target_property_required(USE_GRAPH_LIMIT ${DEVICE_TYPE} USE_GRAPH_LIMIT)

    if(${USE_GRAPH_LIMIT})
        get_target_property_required(GRAPH_LIMIT ${DEVICE_TYPE} GRAPH_LIMIT)
        set(RR_PATCH_EXTRA_ARGS --graph_limit ${GRAPH_LIMIT} ${RR_PATCH_EXTRA_ARGS})
    endif()

    define_device(
      DEVICE ${DEVICE}
      ARCH ${ARCH}
      DEVICE_TYPE ${DEVICE_TYPE}
      PACKAGES test
      RR_PATCH_EXTRA_ARGS ${RR_PATCH_EXTRA_ARGS}
      RR_PATCH_DEPS ${DEVICE_RR_PATCH_DEPS}
      CACHE_PLACE_DELAY
      CACHE_LOOKAHEAD
      CACHE_ARGS
        --constant_net_method route
        --clock_modeling route
        --place_delay_model delta_override
        --router_lookahead connection_box_map
        --disable_errors check_unbuffered_edges:check_route:check_place
        --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R
        --route_chan_width 500
        --base_cost_type delay_normalized_length_bounded
        --allowed_tiles_for_delay_model BLK-TL-SLICEL,BLK-TL-SLICEM
      )
  endforeach()
endfunction()
