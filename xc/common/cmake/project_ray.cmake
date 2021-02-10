function(get_project_ray_dependencies db_dir var part element)
  list(APPEND ${var} ${db_dir}/Info.md)
  string(TOLOWER ${element} element_LOWER)
  file(GLOB other_sources ${db_dir}/${part}/*${element_LOWER}*.db)
  list(APPEND ${var} ${other_sources})
  file(GLOB other_sources ${db_dir}/${part}/*${element}*.json)
  list(APPEND ${var} ${other_sources})
  set(${var} ${${var}} PARENT_SCOPE)
endfunction()

function(PROJECT_RAY_ARCH)
  set(options)
  set(oneValueArgs ARCH PART USE_ROI DEVICE GRAPH_LIMIT USE_OVERLAY)
  set(multiValueArgs TILE_TYPES PB_TYPES)
  cmake_parse_arguments(
    PROJECT_RAY_ARCH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)

  set(ARCH ${PROJECT_RAY_ARCH_ARCH})
  get_target_property_required(PRJRAY_ARCH ${ARCH} PRJRAY_ARCH)
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})

  set(PART ${PROJECT_RAY_ARCH_PART})
  set(DEVICE ${PROJECT_RAY_ARCH_DEVICE})
  set(ARCH_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_arch_import.py)
  set(CREATE_SYNTH_TILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_synth_tiles.py)
  set(CREATE_EDGES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_edges.py)
  set(GET_FABRIC ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_get_fabric.py)
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${GET_FABRIC}
      --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
      --part ${PART}
      -cmake
    OUTPUT_VARIABLE FABRIC
    )
  string(REPLACE "\n" "" FABRIC "${FABRIC}")
  set(DEPS ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${FABRIC}/tilegrid.json)

  if("${PROJECT_RAY_ARCH_PB_TYPES}" STREQUAL "")
    set(PROJECT_RAY_ARCH_PB_TYPES ${PROJECT_RAY_ARCH_TILE_TYPES})
  endif()

  set(ARCH_INCLUDE_FILES "")
  foreach(TILE_TYPE ${PROJECT_RAY_ARCH_TILE_TYPES})
    string(TOLOWER ${TILE_TYPE} TILE_TYPE_LOWER)
    set(TILE_XML ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${TILE_TYPE_LOWER}/${TILE_TYPE_LOWER}.tile.xml)
    append_file_dependency(DEPS ${TILE_XML})
    get_file_location(TILE_XML_LOCATION ${TILE_XML})

    get_file_target(TILE_TARGET ${TILE_XML})
    get_target_property(INCLUDE_FILES ${TILE_TARGET} INCLUDE_FILES)
    list(APPEND ARCH_INCLUDE_FILES ${TILE_XML} ${INCLUDE_FILES})
  endforeach()

  foreach(PB_TYPE ${PROJECT_RAY_ARCH_PB_TYPES})
    string(TOLOWER ${PB_TYPE} PB_TYPE_LOWER)
    set(PB_TYPE_XML ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.pb_type.xml)
    set(MODEL_XML ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.model.xml)
    append_file_dependency(DEPS ${PB_TYPE_XML})
    append_file_dependency(DEPS ${MODEL_XML})

    get_file_target(PB_TYPE_TARGET ${PB_TYPE_XML})
    get_target_property(INCLUDE_FILES ${PB_TYPE_TARGET} INCLUDE_FILES)
    list(APPEND ARCH_INCLUDE_FILES ${PB_TYPE_XML} ${INCLUDE_FILES})

    get_file_target(MODEL_TARGET ${MODEL_XML})
    get_target_property(INCLUDE_FILES ${MODEL_TARGET} INCLUDE_FILES)
    list(APPEND ARCH_INCLUDE_FILES ${MODEL_XML} ${INCLUDE_FILES})
  endforeach()

  set(ROI_ARG "")
  set(ROI_ARG_FOR_CREATE_EDGES "")

  set(GENERIC_CHANNELS
    ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/channels/${PART}/channels.db)
  get_file_location(GENERIC_CHANNELS_LOCATION ${GENERIC_CHANNELS})
  set(VPR_GRID_MAP
    ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/channels/${PART}/vpr_grid_map.csv)
  get_file_location(VPR_GRID_MAP_LOCATION ${VPR_GRID_MAP})

  if(NOT "${PROJECT_RAY_ARCH_USE_ROI}" STREQUAL "")
    set(SYNTH_DEPS "")
    append_file_dependency(SYNTH_DEPS ${GENERIC_CHANNELS})
    add_custom_command(
      OUTPUT synth_tiles.json
      COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
      ${PYTHON3} ${CREATE_SYNTH_TILES}
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
        --part ${PART}
        --connection_database ${GENERIC_CHANNELS_LOCATION}
        --roi ${PROJECT_RAY_ARCH_USE_ROI}
        --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json
      DEPENDS
        ${CREATE_SYNTH_TILES}
        ${PROJECT_RAY_ARCH_USE_ROI} ${SYNTH_DEPS}
        ${PYTHON3}
        )

    add_file_target(FILE synth_tiles.json GENERATED)
    set_target_properties(${ARCH_TARGET} PROPERTIES USE_ROI TRUE)
    set_target_properties(${ARCH_TARGET} PROPERTIES
        SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json)

    set(ROI_ARG --use_roi ${PROJECT_RAY_ARCH_USE_ROI} --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json)
    append_file_dependency(DEPS synth_tiles.json)
    list(APPEND DEPS ${PROJECT_RAY_ARCH_USE_ROI})

    set(ROI_ARG_FOR_CREATE_EDGES --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json)
    append_file_dependency(CHANNELS_DEPS synth_tiles.json)
  endif()

  if(NOT "${PROJECT_RAY_ARCH_GRAPH_LIMIT}" STREQUAL "")
    set(ROI_ARG_FOR_CREATE_EDGES --graph_limit ${PROJECT_RAY_ARCH_GRAPH_LIMIT})
    set(ROI_ARG --graph_limit ${PROJECT_RAY_ARCH_GRAPH_LIMIT})
  endif()

  if(NOT "${PROJECT_RAY_ARCH_USE_OVERLAY}" STREQUAL "")
    set(SYNTH_DEPS "")
    append_file_dependency(SYNTH_DEPS ${GENERIC_CHANNELS})
    add_custom_command(
      OUTPUT synth_tiles.json
      COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
      ${PYTHON3} ${CREATE_SYNTH_TILES}
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
        --part ${PART}
        --connection_database ${GENERIC_CHANNELS_LOCATION}
        --overlay ${PROJECT_RAY_ARCH_USE_OVERLAY}
        --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json
      DEPENDS
        ${CREATE_SYNTH_TILES}
        ${PROJECT_RAY_ARCH_USE_OVERLAY} ${SYNTH_DEPS}
        ${PYTHON3}
        )

    add_file_target(FILE synth_tiles.json GENERATED)
    set_target_properties(${ARCH_TARGET} PROPERTIES USE_OVERLAY TRUE)
    set_target_properties(${ARCH_TARGET} PROPERTIES
        SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json)

    set(ROI_ARG --use_overlay ${PROJECT_RAY_ARCH_USE_OVERLAY} --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json)
    append_file_dependency(DEPS synth_tiles.json)
    list(APPEND DEPS ${PROJECT_RAY_ARCH_USE_OVERLAY})

    set(ROI_ARG_FOR_CREATE_EDGES --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json --overlay)
    append_file_dependency(CHANNELS_DEPS synth_tiles.json)
  endif()

  append_file_dependency(CHANNELS_DEPS ${GENERIC_CHANNELS})
  append_file_dependency(CHANNELS_DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  list(APPEND CHANNELS_DEPS ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${FABRIC}/tilegrid.json)
  list(APPEND CHANNELS_DEPS ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${FABRIC}/tileconn.json)

  add_custom_command(
    OUTPUT channels.db vpr_grid_map.csv
    COMMAND ${CMAKE_COMMAND} -E copy ${GENERIC_CHANNELS_LOCATION} ${CMAKE_CURRENT_BINARY_DIR}/channels.db
    COMMAND ${CMAKE_COMMAND} -E copy ${VPR_GRID_MAP_LOCATION} ${CMAKE_CURRENT_BINARY_DIR}/vpr_grid_map.csv
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${CREATE_EDGES}
      --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
      --part ${PART}
      --pin_assignments ${PIN_ASSIGNMENTS}
      --connection_database ${CMAKE_CURRENT_BINARY_DIR}/channels.db
      ${ROI_ARG_FOR_CREATE_EDGES}
    DEPENDS
    ${PYTHON3} ${CREATE_EDGES} ${CREATE_EDGES_DEPS} ${CHANNELS_DEPS}
    )

  add_file_target(FILE channels.db GENERATED)
  get_file_target(CHAN channels.db)

  add_file_target(FILE vpr_grid_map.csv GENERATED)

  # Linearize dependency to avoid double builds
  get_file_target(GRID_MAP vpr_grid_map.csv)
  add_dependencies(${GRID_MAP} ${CHAN})

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  append_file_dependency(DEPS channels.db)

  string(REPLACE ";" "," TILE_TYPES_COMMA "${PROJECT_RAY_ARCH_TILE_TYPES}")
  string(REPLACE ";" "," PB_TYPES_COMMA "${PROJECT_RAY_ARCH_PB_TYPES}")

  add_custom_command(
    OUTPUT arch.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${ARCH_IMPORT}
      --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
      --part ${PART}
      --connection_database ${CMAKE_CURRENT_BINARY_DIR}/channels.db
      --output-arch ${CMAKE_CURRENT_BINARY_DIR}/arch.xml
      --tile-types "${TILE_TYPES_COMMA}"
      --pb_types "${PB_TYPES_COMMA}"
      --pin_assignments ${PIN_ASSIGNMENTS}
      --device ${DEVICE}
      ${ROI_ARG}
    DEPENDS
    ${ARCH_IMPORT}
    ${DEPS}
    ${PYTHON3}
    )

  add_file_target(FILE arch.xml GENERATED)
  get_file_target(ARCH_TARGET arch.xml)
  set_target_properties(${ARCH_TARGET} PROPERTIES INCLUDE_FILES "${ARCH_INCLUDE_FILES}")
endfunction()

function(PROJECT_RAY_PREPARE_DATABASE)
  set(options)
  set(oneValueArgs FAMILY PRJRAY_ARCH PRJRAY_DIR PRJRAY_DB_DIR PROTOTYPE_PART)
  set(multiValueArgs PARTS)
  cmake_parse_arguments(
    PROJECT_RAY_PREPARE_DATABASE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)

  set(FAMILY ${PROJECT_RAY_PREPARE_DATABASE_PRJRAY_FAMILY})
  set(PRJRAY_ARCH ${PROJECT_RAY_PREPARE_DATABASE_PRJRAY_ARCH})
  set(PRJRAY_DIR ${PROJECT_RAY_PREPARE_DATABASE_PRJRAY_DIR})
  set(PRJRAY_DB_DIR ${PROJECT_RAY_PREPARE_DATABASE_PRJRAY_DB_DIR})
  set(PROTOTYPE_PART ${PROJECT_RAY_PREPARE_DATABASE_PROTOTYPE_PART})

  set(FORM_CHANNELS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_form_channels.py)
  set(ASSIGN_PINS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_assign_tile_pin_direction.py)
  file(GLOB DEPS ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/*.json)
  file(GLOB DEPS2 ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/${PART}/*.json)
  file(GLOB DEPS3 ${PRJRAY_DIR}/prjxray/*.py)

  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/channels)
  foreach(PART ${PROJECT_RAY_PREPARE_DATABASE_PARTS})
    file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/channels/${PART})
    set(CHANNELS channels/${PART}/channels.db)
    set(VPR_GRID_MAP channels/${PART}/vpr_grid_map.csv)
    add_custom_command(
      OUTPUT ${CHANNELS} ${VPR_GRID_MAP}
      COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
      ${PYTHON3} ${FORM_CHANNELS}
      --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
      --part ${PROTOTYPE_PART}
      --connection_database ${CMAKE_CURRENT_BINARY_DIR}/${CHANNELS}
      --grid_map_output ${CMAKE_CURRENT_BINARY_DIR}/${VPR_GRID_MAP}
      DEPENDS
      ${FORM_CHANNELS}
      ${DEPS} ${DEPS2} ${DEPS3}
      ${PYTHON3}
      )

    add_file_target(FILE ${CHANNELS} GENERATED)
    get_file_target(CHAN ${CHANNELS})

    add_file_target(FILE ${VPR_GRID_MAP} GENERATED)

    # Linearize dependency to avoid double builds
    get_file_target(GRID_MAP ${VPR_GRID_MAP})
    add_dependencies(${GRID_MAP} ${CHAN})

  endforeach()

  set(PROTOTYPE_CHANNELS channels/${PROTOTYPE_PART}/channels.db)
  append_file_dependency(DEPS ${PROTOTYPE_CHANNELS})
  set(PIN_ASSIGNMENTS pin_assignments.json)
  add_custom_command(
    OUTPUT ${PIN_ASSIGNMENTS}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${ASSIGN_PINS}
    --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
    --part ${PROTOTYPE_PART}
    --connection_database ${CMAKE_CURRENT_BINARY_DIR}/${PROTOTYPE_CHANNELS}
    --pin_assignments ${CMAKE_CURRENT_BINARY_DIR}/${PIN_ASSIGNMENTS}
    DEPENDS
    ${ASSIGN_PINS}
    ${DEPS} ${DEPS2} ${DEPS3}
    ${PYTHON3}
    )

  add_file_target(FILE ${PIN_ASSIGNMENTS} GENERATED)
endfunction()

function(PROJECT_RAY_TILE)
  #
  # This function is used to create targets to generate pb_type, model and tile XML definitions.
  #
  # ARCH name of the arch that is considered (e.g. artix7, zynq7, etc.)
  # TILE name of the tile that has to be generated (e.g. CLBLM_R, BRAM_L, etc.)
  # SITE_TYPES list of sites contained in the considered tile (e.g. CLBLM_R contains a SLICEM and SLICEL sites)
  # EQUIVALENT_TILES list of pb_types that can be placed at the tile's location (e.g. SLICEM tile can have both SLICEM and SLICEL pb_types)
  # SITE_AS_TILE option to state if the tile physically is a site, but it needs to be treated as a site
  # USE_DATABASE option enables usage of connection database for tile
  #     definition, instead of using the project X-Ray database.
  # FILTER_X can be supplied to filter to sites that have the given X
  #     coordinate.
  # UNUSED_WIRES: contains a list of wires in site to be dropped
  #
  # Usage:
  # ~~~
  # project_xray_tile(
  #   ARCH <arch_name>
  #   TILE <tile_name>
  #   SITE_TYPES <site_name_1> <site_name_2> ...
  #   EQUIVALENT_SITES <equivalent_site_name_1> <equivalent_site_name_2> ...
  #   SITE_AS_TILE (option)
  #   FUSED_SITES (option)
  #   USE_DATABASE (option)
  #   SITE_COORDS (option)
  #   NO_FASM_PREFIX (option)
  #   [FILTER_X <x_coord>]
  #   UNUSED_WIRES <unused wires>
  #   )
  # ~~~

  set(options FUSED_SITES SITE_AS_TILE USE_DATABASE NO_FASM_PREFIX)
  set(oneValueArgs ARCH TILE FILTER_X SITE_COORDS)
  set(multiValueArgs SITE_TYPES EQUIVALENT_SITES UNUSED_WIRES)
  cmake_parse_arguments(
    PROJECT_RAY_TILE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  string(TOLOWER ${PROJECT_RAY_TILE_TILE} TILE)

  get_target_property_required(PYTHON3 env PYTHON3)

  set(ARCH ${PROJECT_RAY_TILE_ARCH})
  get_target_property_required(PRJRAY_ARCH ${ARCH} PRJRAY_ARCH)
  get_target_property_required(PROTOTYPE_PART ${ARCH} PROTOTYPE_PART)
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})

  set(TILE_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_tile_import.py)
  get_project_ray_dependencies(DEPS ${PRJRAY_DB_DIR} ${PRJRAY_ARCH} ${TILE})

  set(PB_TYPE_INCLUDE_FILES "")
  set(MODEL_INCLUDE_FILES "")
  foreach(SITE_TYPE ${PROJECT_RAY_TILE_SITE_TYPES})
    string(TOLOWER ${SITE_TYPE} SITE_TYPE_LOWER)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}.pb_type.xml)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}.model.xml)
    list(APPEND PB_TYPE_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}.pb_type.xml)
    list(APPEND MODEL_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}.model.xml)
  endforeach()
  string(REPLACE ";" "," SITE_TYPES_COMMA "${PROJECT_RAY_TILE_SITE_TYPES}")

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)

  set(FUSED_SITES_ARGS "")
  if(PROJECT_RAY_TILE_FUSED_SITES)
      set(FUSED_SITES_ARGS "--fused_sites")
  endif()
  if(PROJECT_RAY_TILE_SITE_AS_TILE)
      set(FUSED_SITES_ARGS "--site_as_tile")
  endif()
  if(PROJECT_RAY_TILE_USE_DATABASE)
      set(GENERIC_CHANNELS
        ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/channels/${PROTOTYPE_PART}/channels.db)
      get_file_location(GENERIC_CHANNELS_LOCATION ${GENERIC_CHANNELS})
      append_file_dependency(DEPS ${GENERIC_CHANNELS})
      set(FUSED_SITES_ARGS --connection_database ${GENERIC_CHANNELS_LOCATION})
  endif()

  set(SITE_COORDS_ARGS "")
  if(NOT "${PROJECT_RAY_TILE_SITE_COORDS}" STREQUAL "")
    set(SITE_COORDS_ARGS "--site_coords" ${PROJECT_RAY_TILE_SITE_COORDS})
  endif()

  set(FILTER_X_ARGS "")
  if(NOT "${PROJECT_RAY_TILE_FILTER_X}" STREQUAL "")
      set(FILTER_X_ARGS --filter_x ${PROJECT_RAY_TILE_FILTER_X})
  endif()

  set(FASM_ARGS "")
  if(PROJECT_RAY_TILE_NO_FASM_PREFIX)
    set(FASM_ARGS "--no_fasm_prefix")
  endif()

  set(UNUSED_WIRES "")
  if(PROJECT_RAY_TILE_UNUSED_WIRES)
    string(REPLACE ";" "," UNUSED_WIRES_COMMA "${PROJECT_RAY_TILE_UNUSED_WIRES}")
    set(UNUSED_WIRES "--unused_wires" ${UNUSED_WIRES_COMMA})
  endif()

  string(TOUPPER ${TILE} TILE_UPPER)

  add_custom_command(
    OUTPUT ${TILE}.pb_type.xml ${TILE}.model.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${TILE_IMPORT}
    --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
    --part ${PROTOTYPE_PART}
    --tile ${TILE_UPPER}
    --site_directory ${symbiflow-arch-defs_BINARY_DIR}/xc/common/primitives
    --site_types ${SITE_TYPES_COMMA}
    --pin_assignments ${PIN_ASSIGNMENTS}
    --output-pb-type ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.pb_type.xml
    --output-model ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.model.xml
    ${UNUSED_WIRES}
    ${FUSED_SITES_ARGS}
    ${SITE_COORDS_ARGS}
    ${FASM_ARGS}
    ${FILTER_X_ARGS}
    DEPENDS
    ${TILE_IMPORT}
      ${DEPS}
      ${PYTHON3}
    )

  add_file_target(FILE ${TILE}.pb_type.xml GENERATED)
  get_file_target(PB_TYPE_TARGET ${TILE}.pb_type.xml)
  set_target_properties(${PB_TYPE_TARGET} PROPERTIES INCLUDE_FILES "${PB_TYPE_INCLUDE_FILES}")

  get_file_target(MODEL_TARGET ${TILE}.model.xml)
  add_custom_target(${MODEL_TARGET})

  # Linearize the dependency to prevent double builds.
  add_dependencies(${MODEL_TARGET} ${PB_TYPE_TARGET})
  set_target_properties(${MODEL_TARGET} PROPERTIES
      INCLUDE_FILES "${MODEL_INCLUDE_FILES}"
      LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.model.xml
      )

  # tile tags
  set(PHYSICAL_TILE_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_physical_tile_import.py)
  get_project_ray_dependencies(DEPS ${PRJRAY_DB_DIR} ${PRJRAY_ARCH} ${TILE})

  foreach(EQUIVALENT_SITE ${PROJECT_RAY_TILE_EQUIVALENT_SITES})
    string(TOLOWER ${EQUIVALENT_SITE} EQUIVALENT_SITE_LOWER)
    append_file_dependency(TILES_DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${EQUIVALENT_SITE_LOWER}/${EQUIVALENT_SITE_LOWER}.pb_type.xml)
    list(APPEND EQUIVALENT_SITES_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${EQUIVALENT_SITE_LOWER}/${EQUIVALENT_SITE_LOWER}.pb_type.xml)
  endforeach()
  append_file_dependency(TILES_DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${TILE}/${TILE}.pb_type.xml)
  list(APPEND EQUIVALENT_SITES_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles/${TILE}/${TILE}.pb_type.xml)

  string(REPLACE ";" "," EQUIVALENT_SITES_COMMA "${PROJECT_RAY_TILE_EQUIVALENT_SITES}")

  add_custom_command(
    OUTPUT ${TILE}.tile.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${PHYSICAL_TILE_IMPORT}
    --tile ${TILE_UPPER}
    --tiles-directory ${symbiflow-arch-defs_BINARY_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles
    --equivalent-sites=${EQUIVALENT_SITES_COMMA}
    --pin-prefix=${PIN_PREFIX_COMMA}
    --output-tile ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.tile.xml
    --pin_assignments ${PIN_ASSIGNMENTS}
    DEPENDS
    ${PHYSICAL_TILE_IMPORT}
      ${TILES_DEPS}
      ${PYTHON3}
    )

  add_file_target(FILE ${TILE}.tile.xml GENERATED)
  get_file_target(TILE_TARGET ${TILE}.tile.xml)
  set_target_properties(${TILE_TARGET} PROPERTIES INCLUDE_FILES "${EQUIVALENT_SITES_INCLUDE_FILES}")
endfunction()

function(PROJECT_RAY_EQUIV_TILE)
  #
  # This function is used to create targets to generate pb_type, model and
  # tile XML definitions for tile groups.
  #
  # A tile group is a set of related tiles that share some equivilances.
  #
  # ARCH name of the part that is considered (e.g. artix7, zynq7, etc.)
  # TILES name of the tile that has to be generated (e.g. RIOPAD_M, etc.)
  # PB_TYPES list of pb_types to be generated that map into tiles.
  # PB_TYPE_SITES list of variables containing a list of site types in each
  #     PB_TYPE.
  # SITE_EQUIV list of sites that have an equivalent relationship.
  #
  #     Examples:
  #         SITE_EQUIV IOB33M=IOB33 IOB33S=IOB33
  #
  #         IOB33M can be used as a IOB33
  #         IOB33S can be used as a IOB33.
  #
  #  The length of PB_TYPES and PB_TYPE_SITES should be the same
  #
  # Usage:
  # ~~~
  # project_xray_equiv_tile(
  #   ARCH <part_name>
  #   TILES <tile_name_1> <tile_name_2> ...
  #   PB_TYPES <site_name_1> <site_name_2> ...
  #   PB_TYPE_SITES <list_name_1> <list_name_2> ...
  #   SITE_EQUIV <general_site1>=<specific_site1> ...
  #   )
  # ~~~

  set(options)
  set(oneValueArgs ARCH)
  set(multiValueArgs TILES PB_TYPES PB_TYPE_SITES SITE_EQUIV)
  cmake_parse_arguments(
    PROJECT_RAY_EQUIV_TILE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(ARCH ${PROJECT_RAY_EQUIV_TILE_ARCH})
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  if(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${PROJECT_RAY_EQUIV_TILE_ARCH}/tiles")
      message(FATAL_ERROR "project_xray_equiv_tile can only be invoked from the ARCH tiles directory (xc/${FAMILY}/archs/${PROJECT_RAY_EQUIV_TILE_ARCH}/tiles/), in ${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})

  # This code is using prefixed variables because PB_TYPE_SITES list are
  # variables from parent scope, and prefixing is the canonical CMake way to
  # avoid collisions.
  list(LENGTH PROJECT_RAY_EQUIV_TILE_PB_TYPES      PROJECT_RAY_EQUIV_TILE_NPB_TYPES)
  list(LENGTH PROJECT_RAY_EQUIV_TILE_PB_TYPE_SITES PROJECT_RAY_EQUIV_TILE_NPB_TYPE_SITES)

  if(NOT ${PROJECT_RAY_EQUIV_TILE_NPB_TYPES} EQUAL ${PROJECT_RAY_EQUIV_TILE_NPB_TYPE_SITES})
      message(FATAL_ERROR "Number of pb_types (${PROJECT_RAY_EQUIV_TILE_NPB_TYPES}) != number of pb_type sites (${PROJECT_RAY_EQUIV_TILE_NPB_TYPE_SITES})")
  endif()

  set(PROJECT_RAY_EQUIV_TILE_SITES "")
  set(PROJECT_RAY_EQUIV_TILE_PB_TYPES_ARGS "")
  math(EXPR PROJECT_RAY_EQUIV_TILE_NPB_TYPES_N1 ${PROJECT_RAY_EQUIV_TILE_NPB_TYPES}-1)
  foreach(PROJECT_RAY_EQUIV_TILE_IDX RANGE ${PROJECT_RAY_EQUIV_TILE_NPB_TYPES_N1})
      list(GET PROJECT_RAY_EQUIV_TILE_PB_TYPES ${PROJECT_RAY_EQUIV_TILE_IDX} PROJECT_RAY_EQUIV_TILE_PB_TYPE)
      list(GET PROJECT_RAY_EQUIV_TILE_PB_TYPE_SITES  ${PROJECT_RAY_EQUIV_TILE_IDX} PROJECT_RAY_EQUIV_TILE_PB_SITES)

      # Bring in list from parent scope.
      set(PROJECT_RAY_EQUIV_TILE_PB_SITES ${${PROJECT_RAY_EQUIV_TILE_PB_SITES}})

      foreach(PROJECT_RAY_EQUIV_TILE_SITE ${PROJECT_RAY_EQUIV_TILE_PB_SITES})
        list(APPEND PROJECT_RAY_EQUIV_TILE_SITES ${PROJECT_RAY_EQUIV_TILE_PB_SITES})
      endforeach()

      set(PROJECT_RAY_EQUIV_TILE_ARG "${PROJECT_RAY_EQUIV_TILE_PB_TYPE}=${PROJECT_RAY_EQUIV_TILE_PB_SITES}")
      string(REPLACE ";" "," PROJECT_RAY_EQUIV_TILE_ARG "${PROJECT_RAY_EQUIV_TILE_ARG}")

      list(APPEND PROJECT_RAY_EQUIV_TILE_PB_TYPES_ARGS ${PROJECT_RAY_EQUIV_TILE_ARG})
  endforeach()

  # Done with variables from parent scope, prefix is not longer required.


  get_target_property_required(PYTHON3 env PYTHON3)

  get_target_property(PROTOTYPE_PART ${ARCH} PROTOTYPE_PART)
  set(PB_TYPE_INCLUDE_FILES "")
  set(MODEL_INCLUDE_FILES "")
  list(REMOVE_DUPLICATES PROJECT_RAY_EQUIV_TILE_SITES)
  foreach(SITE_TYPE ${PROJECT_RAY_EQUIV_TILE_SITES})
    string(TOLOWER ${SITE_TYPE} SITE_TYPE_LOWER)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.pb_type.xml)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.model.xml)
    list(APPEND PB_TYPE_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.pb_type.xml)
    list(APPEND MODEL_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.model.xml)
  endforeach()

  set(TILES_ARGS "${PROJECT_RAY_EQUIV_TILE_TILES}")
  string(REPLACE ";" "," TILES_ARGS "${TILES_ARGS}")

  set(EQUIV_ARGS "")
  if(NOT "${PROJECT_RAY_EQUIV_TILE_SITE_EQUIV}" STREQUAL "")
    set(EQUIV_ARGS "${PROJECT_RAY_EQUIV_TILE_SITE_EQUIV}")
    string(REPLACE ";" "," EQUIV_ARGS "${EQUIV_ARGS}")
    set(EQUIV_ARGS --site_equivilances ${EQUIV_ARGS})
  endif()

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)

  set(GENERIC_CHANNELS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/channels/${PROTOTYPE_PART}/channels.db)
  get_file_location(GENERIC_CHANNELS_LOCATION ${GENERIC_CHANNELS})
  append_file_dependency(DEPS ${GENERIC_CHANNELS})

  set(OUTPUTS "")

  foreach(TILE ${PROJECT_RAY_EQUIV_TILE_TILES})
      string(TOLOWER ${TILE} TILE_LOWER)
      list(APPEND OUTPUTS ${TILE_LOWER}/${TILE_LOWER}.tile.xml)
  endforeach()

  foreach(PB_TYPE ${PROJECT_RAY_EQUIV_TILE_PB_TYPES})
      string(TOLOWER ${PB_TYPE} PB_TYPE_LOWER)
      list(APPEND OUTPUTS ${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.pb_type.xml)
      list(APPEND OUTPUTS ${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.model.xml)
  endforeach()

  set(TILE_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_equiv_tiles.py)
  add_custom_command(
    OUTPUT ${OUTPUTS}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${TILE_IMPORT}
    --output_directory ${symbiflow-arch-defs_BINARY_DIR}/xc/${FAMILY}/archs/${ARCH}/tiles
    --site_directory ${symbiflow-arch-defs_BINARY_DIR}/xc/common/primitives
    --connection_database ${GENERIC_CHANNELS_LOCATION}
    --tile_types ${TILES_ARGS}
    --pb_types ${PROJECT_RAY_EQUIV_TILE_PB_TYPES_ARGS}
    ${EQUIV_ARGS}
    --pin_assignments ${PIN_ASSIGNMENTS}
    DEPENDS
      ${TILE_IMPORT}
      ${DEPS}
      ${PYTHON3}
    )

  set(TARGETS "")
  foreach(TILE ${PROJECT_RAY_EQUIV_TILE_TILES})
    string(TOLOWER ${TILE} TILE_LOWER)
    set(FILE_REL ${TILE_LOWER}/${TILE_LOWER}.tile.xml)
    add_file_target(FILE ${FILE_REL} GENERATED)
    get_file_target(TILE_TARGET ${FILE_REL})
    list(APPEND TARGETS ${TILE_TARGET})
  endforeach()

  foreach(PB_TYPE ${PROJECT_RAY_EQUIV_TILE_PB_TYPES})
    string(TOLOWER ${PB_TYPE} PB_TYPE_LOWER)
    set(FILE_REL ${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.pb_type.xml)
    add_file_target(FILE ${FILE_REL} GENERATED)
    get_file_target(PB_TYPE_TARGET ${FILE_REL})
    set_target_properties(${PB_TYPE_TARGET} PROPERTIES
        INCLUDE_FILES "${PB_TYPE_INCLUDE_FILES}")
    list(APPEND TARGETS ${PB_TYPE_TARGET})

    set(FILE_REL ${PB_TYPE_LOWER}/${PB_TYPE_LOWER}.model.xml)
    add_file_target(FILE ${FILE_REL} GENERATED)
    get_file_target(MODEL_TARGET ${FILE_REL})
    set_target_properties(${MODEL_TARGET} PROPERTIES
        INCLUDE_FILES "${MODEL_INCLUDE_FILES}")
    list(APPEND TARGETS ${MODEL_TARGET})
  endforeach()

  # Linearize the dependency to prevent double builds.
  list(GET TARGETS 0 TARGET0)
  list(LENGTH TARGETS NTARGETS)

  math(EXPR NTARGETS_N1 ${NTARGETS}-1)
  foreach(IDX RANGE 1 ${NTARGETS_N1})
    list(GET TARGETS ${IDX} TARGET)
    add_dependencies(${TARGET} ${TARGET0})
  endforeach()
endfunction()

function(PROJECT_RAY_TILE_CAPACITY)
  # ~~~
  # PROJECT_RAY_TILE_CAPACITY(
  #   ARCH <arch>
  #   TILE <tile>
  #   SITE_TYPES <site types>
  #   UNUSED_WIRES <unused wires>
  #   )
  # ~~~
  #
  # SITE_TYPES: contains a list of sites that are used as sub tiles for the specified tile.
  #             The total number of instances of a site type appears as the capacity of the sub tile
  # UNUSED_WIRES: contains a list of wires in site to be dropped

  set(options)
  set(oneValueArgs ARCH TILE)
  set(multiValueArgs SITE_TYPES UNUSED_WIRES)
  cmake_parse_arguments(
    PROJECT_RAY_TILE_CAPACITY
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(DEPS "")
  set(TILE ${PROJECT_RAY_TILE_CAPACITY_TILE})
  set(ARCH ${PROJECT_RAY_TILE_CAPACITY_ARCH})

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(PRJRAY_ARCH ${ARCH} PRJRAY_ARCH)
  get_target_property_required(FAMILY ${ARCH} FAMILY)
  get_target_property_required(PROTOTYPE_PART ${ARCH} PROTOTYPE_PART)
  get_target_property_required(DOC_PRJ ${ARCH} DOC_PRJ)
  get_target_property_required(DOC_PRJ_DB ${ARCH} DOC_PRJ_DB)

  set(PRJRAY_DIR ${DOC_PRJ})
  set(PRJRAY_DB_DIR ${DOC_PRJ_DB})

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/archs/${ARCH}/pin_assignments.json)

  set(TILE_CAPACITY_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_import_tile_capacity.py)

  string(REPLACE ";" "," SITE_TYPES_COMMA "${PROJECT_RAY_TILE_CAPACITY_SITE_TYPES}")

  string(TOLOWER ${TILE} TILE_LOWER)

  set(UNUSED_WIRES "")
  if(PROJECT_RAY_TILE_CAPACITY_UNUSED_WIRES)
    string(REPLACE ";" "," UNUSED_WIRES_COMMA "${PROJECT_RAY_TILE_CAPACITY_UNUSED_WIRES}")
    set(UNUSED_WIRES "--unused_wires" ${UNUSED_WIRES_COMMA})
  endif()

  add_custom_command(
    OUTPUT ${TILE_LOWER}.tile.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${TILE_CAPACITY_IMPORT}
      --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH}/
      --part ${PROTOTYPE_PART}
      --output_directory ${CMAKE_CURRENT_BINARY_DIR}
      --site_directory ${symbiflow-arch-defs_BINARY_DIR}/xc/common/primitives
      --tile_type ${TILE}
      --pb_types ${SITE_TYPES_COMMA}
      --pin_assignments ${PIN_ASSIGNMENTS}
      ${UNUSED_WIRES}
    DEPENDS
      ${TILE_CAPACITY_IMPORT}
      ${DEPS}
      ${PYTHON3}
    )
  add_file_target(FILE ${TILE_LOWER}.tile.xml GENERATED)
endfunction()
