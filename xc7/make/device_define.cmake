add_conda_pip(
  NAME textx
  NO_EXE
)

function(ADD_XC7_DEVICE_DEFINE_TYPE)
  set(options)
  set(oneValueArgs ARCH DEVICE ROI_DIR ROI_PART NAME PART)
  set(multiValueArgs TILE_TYPES)
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
  set(ROI_PART ${ADD_XC7_DEVICE_DEFINE_TYPE_ROI_PART})
  set(TILE_TYPES ${ADD_XC7_DEVICE_DEFINE_TYPE_TILE_TYPES})
  set(NAME ${ADD_XC7_DEVICE_DEFINE_TYPE_NAME})
  set(PART ${ADD_XC7_DEVICE_DEFINE_TYPE_PART})

  add_custom_target(${ARCH}_${DEVICE}_${NAME})
  if(PART)
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES PART ${PART}
      )
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES BIT_TO_BIN_EXTRA_ARGS " \
    --part_name ${PART} \
    --part_file ${PRJXRAY_DB_DIR}/${ARCH}/${PART}.yaml \
  ")
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES BIT_TO_V_EXTRA_ARGS " \
    --part ${PART}
    --connection_database ${CMAKE_CURRENT_BINARY_DIR}/channels.db
  ")

  project_xray_arch(
    PART ${ARCH}
    DEVICE ${DEVICE}
    TILE_TYPES ${TILE_TYPES}
    )
  elseif(ROI_PART)
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES PART ${ROI_PART}
      )
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES FASM_TO_BIT_EXTRA_ARGS " \
    --roi ${ROI_DIR}/design.json \
  ")
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES BIT_TO_BIN_EXTRA_ARGS " \
    --part_name ${ROI_PART} \
    --part_file ${PRJXRAY_DB_DIR}/${ARCH}/${ROI_PART}.yaml \
  ")
  set_target_properties(${ARCH}_${DEVICE}_${NAME}
      PROPERTIES BIT_TO_V_EXTRA_ARGS " \
    --part ${ROI_PART}
    --connection_database ${CMAKE_CURRENT_BINARY_DIR}/channels.db
  ")

  project_xray_arch(
    PART ${ARCH}
    DEVICE ${DEVICE}
    TILE_TYPES ${TILE_TYPES}
    USE_ROI ${ROI_DIR}/design.json
    )
  endif()

  set(SDF_TIMING_DIRECTORY ${PRJXRAY_DB_DIR}/${ARCH}/timings)
  set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
  set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
  set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/xc7/bels.json)

  set(TIMING_IMPORT "${PYTHON3} ${UPDATE_ARCH_TIMINGS} --sdf_dir ${SDF_TIMING_DIRECTORY} --bels_map ${BELS_MAP} --out_arch /dev/stdout --input_arch /dev/stdin")
  set(TIMING_DEPS "")

  if(ROI_PART)
    set(DEVICE ${DEVICE}-roi)
  endif()

  define_device_type(
    DEVICE_TYPE ${DEVICE}-virt
    ARCH ${ARCH}
    ARCH_XML arch.xml
    SCRIPT_OUTPUT_NAME timing
    SCRIPTS ${TIMING_IMPORT}
    SCRIPT_DEPS TIMING_DEPS
    )
  add_dependencies(${ARCH}_${DEVICE}-virt_arch arch_import_timing_deps)
  get_target_property_required(VIRT_DEVICE_MERGED_FILE ${DEVICE}-virt DEVICE_MERGED_FILE)
  get_file_target(DEVICE_MERGED_FILE_TARGET ${VIRT_DEVICE_MERGED_FILE})
  add_dependencies(${DEVICE_MERGED_FILE_TARGET} arch_import_timing_deps)
endfunction()

function(ADD_XC7_DEVICE_DEFINE)
  set(options)
  set(oneValueArgs ARCH)
  set(multiValueArgs DEVICES PARTS)
  cmake_parse_arguments(
    ADD_XC7_DEVICE_DEFINE
     "${options}"
     "${oneValueArgs}"
     "${multiValueArgs}"
     ${ARGN}
   )

  set(ARCH ${ADD_XC7_DEVICE_DEFINE_ARCH})
  set(DEVICES ${ADD_XC7_DEVICE_DEFINE_DEVICES})
  set(PARTS ${ADD_XC7_DEVICE_DEFINE_PARTS})

  list(LENGTH DEVICES DEVICE_COUNT)
  math(EXPR DEVICE_COUNT_N_1 "${DEVICE_COUNT} - 1")
  foreach(INDEX RANGE ${DEVICE_COUNT_N_1})
    list(GET DEVICES ${INDEX} DEVICE)
    list(GET PARTS ${INDEX} PART)

    add_subdirectory(${DEVICE}-virt)

    if(${DEVICE} MATCHES ".*-roi$")

      string(REPLACE "-roi" "" DEVICE ${DEVICE})

      # SYNTH_TILES used in ROI.
      set(CHANNELS ${CMAKE_CURRENT_SOURCE_DIR}/${DEVICE}-roi-virt/channels.db)
      set(SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/${DEVICE}-roi-virt/synth_tiles.json)
      get_file_location(SYNTH_TILES_LOCATION ${SYNTH_TILES})
      get_file_location(CHANNELS_LOCATIONS ${CHANNELS})

      # Clear variable before adding deps for next device
      set(DEVICE_RR_PATCH_DEPS "")

      append_file_dependency(DEVICE_RR_PATCH_DEPS ${CHANNELS})
      append_file_dependency(DEVICE_RR_PATCH_DEPS ${SYNTH_TILES})

      list(APPEND DEVICE_RR_PATCH_DEPS intervaltree textx)

      define_device(
        DEVICE ${DEVICE}
        ARCH ${ARCH}
        DEVICE_TYPE ${DEVICE}-roi-virt
        PACKAGES test
        RR_PATCH_EXTRA_ARGS --synth_tiles ${SYNTH_TILES_LOCATION} --connection_database ${CHANNELS_LOCATIONS}
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
          --astar_fac 0.75
          --bb_factor 100
        )

      get_target_property_required(PYTHON3 env PYTHON3)
      get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

      set(SYNTH_TILES_TO_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_synth_tiles_to_pinmap_csv.py)
      set(PINMAP_CSV ${DEVICE}-roi-virt/synth_tiles_pinmap.csv)

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

      add_file_target(FILE ${PINMAP_CSV} GENERATED)

      set_target_properties(
        ${DEVICE}
        PROPERTIES
          test_PINMAP
          ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
      )

    else() # no ROI

      set(CHANNELS ${CMAKE_CURRENT_SOURCE_DIR}/${DEVICE}-virt/channels.db)
      get_file_location(CHANNELS_LOCATIONS ${CHANNELS})

      # Clear variable before adding deps for next device
      set(DEVICE_RR_PATCH_DEPS "")

      append_file_dependency(DEVICE_RR_PATCH_DEPS ${CHANNELS})

      list(APPEND DEVICE_RR_PATCH_DEPS intervaltree textx)

      define_device(
        DEVICE ${DEVICE}
        ARCH ${ARCH}
        DEVICE_TYPE ${DEVICE}-virt
        PACKAGES test
        RR_PATCH_EXTRA_ARGS --connection_database ${CHANNELS_LOCATIONS}
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
          --astar_fac 0.75
          --bb_factor 100
        )

      get_target_property_required(PYTHON3 env PYTHON3)
      get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

      set(CREATE_PINMAP_CSV ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_create_pinmap_csv.py)
      set(PINMAP_CSV ${DEVICE}-virt/pinmap.csv)

      set(PINMAP_CSV_DEPS ${PYTHON3} ${PYTHON3_TARGET} ${CREATE_PINMAP_CSV})
      append_file_dependency(SYNTH_TILESPINMAP_CSV_DEPS ${CHANNELS})
      add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
        COMMAND ${PYTHON3} ${CREATE_PINMAP_CSV}
          --connection_database ${CHANNELS}
          --package_pins ${PRJXRAY_DB_DIR}/${ARCH}/${PART}_package_pins.csv
          --output ${CMAKE_CURRENT_BINARY_DIR}/${PINMAP_CSV}
          DEPENDS ${PINMAP_CSV_DEPS}
          )

      add_file_target(FILE ${PINMAP_CSV} GENERATED)

      set_target_properties(
        ${DEVICE}
        PROPERTIES
          test_PINMAP
          ${CMAKE_CURRENT_SOURCE_DIR}/${PINMAP_CSV}
      )

    endif()

  endforeach()
endfunction()
