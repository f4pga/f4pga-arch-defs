function(ADD_XC_BOARD)
  # ~~~
  # ADD_XC_BOARD(
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
  # have been defined using ADD_XC_DEVICE_DEFINE.  Currently PACKAGE should
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
     ADD_XC_BOARD
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  define_board(
    BOARD ${ADD_XC_BOARD_BOARD}
    DEVICE ${ADD_XC_BOARD_DEVICE}
    PACKAGE ${ADD_XC_BOARD_PACKAGE}
    PROG_TOOL ${ADD_XC_BOARD_PROG_TOOL}
    PROG_CMD ${ADD_XC_BOARD_PROG_CMD}
    )

  set(DEVICE ${ADD_XC_BOARD_DEVICE})
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(PRJRAY_ARCH ${ARCH} PRJRAY_ARCH)
  get_target_property_required(DEVICE_TYPE ${DEVICE} DEVICE_TYPE)
  get_target_property_required(USE_ROI ${DEVICE_TYPE} USE_ROI)
  set(BOARD ${ADD_XC_BOARD_BOARD})
  set(PART ${ADD_XC_BOARD_PART})

  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})
  set(DB_ROOT "${PRJRAY_DB_DIR}/${PRJRAY_ARCH}")

  set_target_properties(${BOARD}
    PROPERTIES PART ${PART}
    )
  set_target_properties(${BOARD}
    PROPERTIES PART_JSON ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/part.json
    )

  get_target_property_required(CHANNELS_DB ${DEVICE_TYPE} CHANNELS_DB)
  get_file_location(CHANNELS_LOCATION ${CHANNELS_DB})

  get_target_property_required(VPR_GRID_MAP ${DEVICE_TYPE} VPR_GRID_MAP)
  get_file_location(VPR_GRID_MAP_LOCATION ${VPR_GRID_MAP})

  set_target_properties(${BOARD}
    PROPERTIES BIT_TO_V_EXTRA_ARGS " \
    --part ${PART}
    --connection_database ${CHANNELS_LOCATION}
    --vpr_grid_map ${VPR_GRID_MAP_LOCATION}
  ")

  get_target_property(USE_OVERLAY ${DEVICE_TYPE} USE_OVERLAY)
  get_target_property_required(PYTHON3 env PYTHON3)


  if(${USE_ROI})
    get_target_property_required(ROI_DIR ${DEVICE_TYPE} ROI_DIR)

    get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
    get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})

    set_target_properties(${BOARD}
      PROPERTIES FASM_TO_BIT_EXTRA_ARGS " \
      --roi ${ROI_DIR}/design.json \
      --part ${PART} \
      --part_file ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/part.yaml \
    ")

    set_target_properties(${BOARD}
      PROPERTIES PLACE_CONSTR_TOOL_EXTRA_ARGS " \
      --vpr_grid_map ${VPR_GRID_MAP_LOCATION} \
      --roi
    ")

    get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
    get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${CREATE_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${CHANNELS_DB})
    append_file_dependency(PINMAP_CSV_DEPS ${SYNTH_TILES})

    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        --db_root ${DB_ROOT}
        --part ${PART}
        --connection_database ${CHANNELS_LOCATION}
        --synth_tiles ${SYNTH_TILES_LOCATION}
        --package_pins ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/package_pins.csv
        --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        DEPENDS ${PINMAP_CSV_DEPS}
    )
  elseif(${USE_OVERLAY})
    set_target_properties(${BOARD}
      PROPERTIES FASM_TO_BIT_EXTRA_ARGS " \
      --part ${PART} \
      --part_file ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/part.yaml \
    ")

    set_target_properties(${BOARD}
      PROPERTIES PLACE_CONSTR_TOOL_EXTRA_ARGS " \
      --vpr_grid_map ${VPR_GRID_MAP_LOCATION}
    ")

    get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
    get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${CREATE_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${CHANNELS_DB})
    append_file_dependency(PINMAP_CSV_DEPS ${SYNTH_TILES})

    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        --db_root ${DB_ROOT}
        --part ${PART}
        --connection_database ${CHANNELS_LOCATION}
        --synth_tiles ${SYNTH_TILES_LOCATION}
        --package_pins ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/package_pins.csv
        --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        --overlay
        DEPENDS ${PINMAP_CSV_DEPS}
      )
  else()
    set_target_properties(${BOARD}
      PROPERTIES FASM_TO_BIT_EXTRA_ARGS " \
      --part ${PART} \
      --part_file ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/part.yaml \
    ")

    set_target_properties(${BOARD}
      PROPERTIES PLACE_CONSTR_TOOL_EXTRA_ARGS " \
      --vpr_grid_map ${VPR_GRID_MAP_LOCATION}
    ")

    set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_pinmap_csv.py)
    set(PINMAP_CSV ${BOARD}_pinmap.csv)
    set(PINMAP_CSV_DEPS ${PYTHON3} ${CREATE_PINMAP_CSV})
    append_file_dependency(PINMAP_CSV_DEPS ${CHANNELS_DB})

    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
      COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
        --db_root ${DB_ROOT}
        --part ${PART}
        --connection_database ${CHANNELS_LOCATION}
        --package_pins ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/package_pins.csv
        --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        DEPENDS ${PINMAP_CSV_DEPS}
      )
  endif()

  get_target_property(GRAPH_LIMIT ${DEVICE_TYPE} GRAPH_LIMIT)
  if(NOT "${GRAPH_LIMIT}" STREQUAL "GRAPH_LIMIT-NOTFOUND")
    set_property(
      TARGET ${BOARD}
      APPEND_STRING PROPERTY PLACE_CONSTR_TOOL_EXTRA_ARGS "--graph_limit ${GRAPH_LIMIT}"
    )
  endif()

  add_file_target(FILE ${PINMAP_CSV} GENERATED)

  set_target_properties(
    ${BOARD}
    PROPERTIES
      PINMAP
      ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
  )

  get_target_property_required(VPR_GRID_MAP ${DEVICE_TYPE} VPR_GRID_MAP)
  get_file_location(VPR_GRID_MAP_LOCATION ${VPR_GRID_MAP})

  set_target_properties(
    dummy_${ARCH}_${DEVICE}_${ADD_XC_BOARD_PACKAGE}
    PROPERTIES
    PLACE_CONSTR_TOOL_EXTRA_ARGS "--vpr_grid_map ${VPR_GRID_MAP_LOCATION} --roi"
    PINMAP
    ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV})

  define_xc_pinmap_csv_install_target(
    PART ${PART}
    BOARD ${BOARD}
    DEVICE_TYPE ${DEVICE_TYPE}
    DEVICE ${ADD_XC_BOARD_DEVICE}
    PACKAGE ${ADD_XC_BOARD_PACKAGE}
    )
endfunction()

function(ADD_XC_DEVICE_DEFINE_TYPE)
  set(options)
  set(oneValueArgs ARCH PART DEVICE ROI_DIR GRAPH_LIMIT OVERLAY_DIR)
  set(multiValueArgs TILE_TYPES PB_TYPES PRIMITIVES_WITH_DIRECT_IO)
  cmake_parse_arguments(
    ADD_XC_DEVICE_DEFINE_TYPE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
    )

  set(ARCH ${ADD_XC_DEVICE_DEFINE_TYPE_ARCH})
  set(DEVICE ${ADD_XC_DEVICE_DEFINE_TYPE_DEVICE})
  set(ROI_DIR ${ADD_XC_DEVICE_DEFINE_TYPE_ROI_DIR})
  set(OVERLAY_DIR ${ADD_XC_DEVICE_DEFINE_TYPE_OVERLAY_DIR})
  set(TILE_TYPES ${ADD_XC_DEVICE_DEFINE_TYPE_TILE_TYPES})
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})

  get_target_property_required(PRJRAY_ARCH ${ARCH} PRJRAY_ARCH)

  if(NOT "${ROI_DIR}" STREQUAL "")
    set(ROI_ARGS USE_ROI ${ROI_DIR}/design.json)
    set(DEVICE_TYPE ${DEVICE}-roi-virt)
  elseif(NOT "${ADD_XC_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}" STREQUAL "")
    set(DEVICE_TYPE ${DEVICE}-virt)
    set(ROI_ARGS GRAPH_LIMIT ${ADD_XC_DEVICE_DEFINE_TYPE_GRAPH_LIMIT})
  elseif(NOT "${OVERLAY_DIR}" STREQUAL "")
    set(DEVICE_TYPE ${DEVICE}-virt)
    set(ROI_ARGS USE_OVERLAY ${OVERLAY_DIR}/design.json)
  else()
    set(DEVICE_TYPE ${DEVICE}-virt)
    set(ROI_ARGS "")
  endif()

  set(PB_TYPE_ARGS "")
  if(NOT "${ADD_XC_DEVICE_DEFINE_TYPE_PB_TYPES}" STREQUAL "")
      set(PB_TYPE_ARGS PB_TYPES ${ADD_XC_DEVICE_DEFINE_TYPE_PB_TYPES})
  endif()

  set(PRIMITIVES_WITH_DIRECT_IO "")
  if(NOT "${ADD_XC_DEVICE_DEFINE_TYPE_PRIMITIVES_WITH_DIRECT_IO}" STREQUAL "")
      string(REPLACE ";" "," PRIMITIVES_WITH_DIRECT_IO_COMMA "${ADD_XC_DEVICE_DEFINE_TYPE_PRIMITIVES_WITH_DIRECT_IO}")
      set(PRIMITIVES_WITH_DIRECT_IO ${PRIMITIVES_WITH_DIRECT_IO_COMMA})
  endif()

  project_ray_arch(
    ARCH ${ARCH}
    PART ${PART}
    DEVICE ${DEVICE}
    TILE_TYPES ${TILE_TYPES}
    ${ROI_ARGS}
    ${PB_TYPE_ARGS}
    )

  set(SDF_TIMING_DIRECTORY ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/timings)
  set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
  set(UPDATE_PACK_PATTERNS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/add_pack_patterns.py)
  set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
  set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/bels.json)

  set(ADD_PACK_PATTERN "${PYTHON3} ${UPDATE_PACK_PATTERNS} --in_arch /dev/stdin")

  get_file_target(UPDATE_PACK_PATTERNS_TARGET ${UPDATE_PACK_PATTERNS})
  set(PACK_PATTERN_DEPS ${UPDATE_PACK_PATTERNS_TARGET})

  set(TIMING_IMPORT "${PYTHON3} ${UPDATE_ARCH_TIMINGS} --sdf_dir ${SDF_TIMING_DIRECTORY} --bels_map ${BELS_MAP} --out_arch /dev/stdout --input_arch /dev/stdin")

  get_file_target(BELS_MAP_TARGET ${BELS_MAP})
  get_file_target(UPDATE_ARCH_TIMINGS_TARGET ${UPDATE_ARCH_TIMINGS})
  set(TIMING_DEPS ${BELS_MAP_TARGET} ${UPDATE_ARCH_TIMINGS_TARGET})

  define_device_type(
    DEVICE_TYPE ${DEVICE_TYPE}
    ARCH ${ARCH}
    ARCH_XML arch.xml
    SCRIPT_OUTPUT_NAME pack_patterns timing
    SCRIPTS ADD_PACK_PATTERN TIMING_IMPORT
    SCRIPT_DEPS PACK_PATTERN_DEPS TIMING_DEPS
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
      PRIMITIVES_WITH_DIRECT_IO "${PRIMITIVES_WITH_DIRECT_IO}"
      CHANNELS_DB ${CMAKE_CURRENT_SOURCE_DIR}/channels.db
      SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json
      VPR_GRID_MAP ${CMAKE_CURRENT_SOURCE_DIR}/vpr_grid_map.csv
      )
  else()
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_ROI FALSE
      PRIMITIVES_WITH_DIRECT_IO "${PRIMITIVES_WITH_DIRECT_IO}"
      CHANNELS_DB ${CMAKE_CURRENT_SOURCE_DIR}/channels.db
      VPR_GRID_MAP ${CMAKE_CURRENT_SOURCE_DIR}/vpr_grid_map.csv
      )
  endif()

  if(NOT "${ADD_XC_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}" STREQUAL "")
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      LIMIT_GRAPH_TO_DEVICE TRUE
      GRAPH_LIMIT "${ADD_XC_DEVICE_DEFINE_TYPE_GRAPH_LIMIT}"
      )
  else()
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      LIMIT_GRAPH_TO_DEVICE FALSE
      )
  endif()

  if(NOT "${OVERLAY_DIR}" STREQUAL "")
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_OVERLAY TRUE
      OVERLAY_DIR ${OVERLAY_DIR}
      SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json
      )
  else()
    set_target_properties(
      ${DEVICE_TYPE}
      PROPERTIES
      USE_OVERLAY FALSE
      )
  endif()
endfunction()

function(ADD_XC_DEVICE_DEFINE)
  set(options USE_ROI USE_OVERLAY)
  set(oneValueArgs ARCH PART)
  set(multiValueArgs DEVICES)
  cmake_parse_arguments(
    ADD_XC_DEVICE_DEFINE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  set(USE_ROI ${ADD_XC_DEVICE_DEFINE_USE_ROI})
  set(USE_OVERLAY ${ADD_XC_DEVICE_DEFINE_USE_OVERLAY})
  set(ARCH ${ADD_XC_DEVICE_DEFINE_ARCH})
  set(PART ${ADD_XC_DEVICE_DEFINE_PART})
  set(DEVICES ${ADD_XC_DEVICE_DEFINE_DEVICES})

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
    append_file_dependency(DEVICE_RR_PATCH_DEPS ${CHANNELS_DB})

    if(${USE_ROI} OR ${USE_OVERLAY})
        # SYNTH_TILES used in ROI.
        get_target_property_required(SYNTH_TILES ${DEVICE_TYPE} SYNTH_TILES)
        get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
        append_file_dependency(DEVICE_RR_PATCH_DEPS ${SYNTH_TILES})
        if(${USE_ROI})
          set(RR_PATCH_EXTRA_ARGS --synth_tiles ${SYNTH_TILES_LOCATION} ${RR_PATCH_EXTRA_ARGS})
        else()
          set(RR_PATCH_EXTRA_ARGS --synth_tiles ${SYNTH_TILES_LOCATION} --overlay ${RR_PATCH_EXTRA_ARGS})
        endif()
    endif()

    get_target_property_required(LIMIT_GRAPH_TO_DEVICE ${DEVICE_TYPE} LIMIT_GRAPH_TO_DEVICE)

    if(${LIMIT_GRAPH_TO_DEVICE})
        get_target_property_required(GRAPH_LIMIT ${DEVICE_TYPE} GRAPH_LIMIT)
        set(RR_PATCH_EXTRA_ARGS --graph_limit ${GRAPH_LIMIT} ${RR_PATCH_EXTRA_ARGS})
    endif()

    define_device(
      DEVICE ${DEVICE}
      ARCH ${ARCH}
      PART ${PART}
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
        --place_delta_delay_matrix_calculation_method dijkstra
        --router_lookahead extended_map
        --disable_errors check_unbuffered_edges:check_route:check_place
        --suppress_warnings sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R
        --route_chan_width 500
        --allowed_tiles_for_delay_model BLK-TL-CLBLL_L,BLK-TL-CLBLL_R,BLK-TL-CLBLM_L,BLK-TL-CLBLM_R
      )
  endforeach()
endfunction()
