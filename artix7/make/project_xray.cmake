set(PRJXRAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray)
set(PRJXRAY_DB_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db
  CACHE PATH "Path to prjxray database files")

add_conda_pip(
  NAME progressbar2
  NO_EXE
  )

add_conda_pip(
  NAME simplejson
  NO_EXE
  )

function(get_project_xray_dependencies var part element)
  list(APPEND ${var} ${PRJXRAY_DB_DIR}/Info.md)
  string(TOLOWER ${element} element_LOWER)
  file(GLOB other_sources ${PRJXRAY_DB_DIR}/${part}/*${element_LOWER}*.db)
  list(APPEND ${var} ${other_sources})
  file(GLOB other_sources ${PRJXRAY_DB_DIR}/${part}/*${element}*.json)
  list(APPEND ${var} ${other_sources})
  set(${var} ${${var}} PARENT_SCOPE)
endfunction()

function(PROJECT_XRAY_DUMMY_SITE)
  set(options)
  set(oneValueArgs PART SITE)

  cmake_parse_arguments(
    PROJECT_XRAY_DUMMY_SITE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  string(TOLOWER ${PROJECT_XRAY_DUMMY_SITE_SITE} SITE)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(DUMMY_SITE_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray_generate_dummy_site.py)
  get_project_xray_dependencies(DEPS ${PROJECT_XRAY_DUMMY_SITE_PART} ${SITE})

  add_custom_command(
    OUTPUT ${SITE}.pb_type.xml ${SITE}.model.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${DUMMY_SITE_IMPORT}
    --part ${PROJECT_XRAY_DUMMY_SITE_PART}
    --site_type ${PROJECT_XRAY_DUMMY_SITE_SITE}
    --output-pb-type ${CMAKE_CURRENT_BINARY_DIR}/${SITE}.pb_type.xml
    --output-model ${CMAKE_CURRENT_BINARY_DIR}/${SITE}.model.xml
    DEPENDS
    ${DUMMY_SITE_IMPORT}
      ${DEPS}
      ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${SITE}.pb_type.xml GENERATED)
  add_file_target(FILE ${SITE}.model.xml GENERATED)
endfunction()

function(PROJECT_XRAY_TILE)
  set(options)
  set(oneValueArgs PART TILE)
  set(multiValueArgs SITE_TYPES)
  cmake_parse_arguments(
    PROJECT_XRAY_TILE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  string(TOLOWER ${PROJECT_XRAY_TILE_TILE} TILE)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(TILE_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray_tile_import.py)
  get_project_xray_dependencies(DEPS ${PROJECT_XRAY_TILE_PART} ${TILE})

  set(PART ${PROJECT_XRAY_TILE_PART})
  set(PB_TYPE_INCLUDE_FILES "")
  set(MODEL_INCLUDE_FILES "")
  foreach(SITE_TYPE ${PROJECT_XRAY_TILE_SITE_TYPES})
    string(TOLOWER ${SITE_TYPE} SITE_TYPE_LOWER)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.pb_type.xml)
    append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.model.xml)
    list(APPEND PB_TYPE_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.pb_type.xml)
    list(APPEND MODEL_INCLUDE_FILES ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/primitives/${SITE_TYPE_LOWER}/${SITE_TYPE_LOWER}.model.xml)
  endforeach()
  string(REPLACE ";" "," SITE_TYPES_COMMA "${PROJECT_XRAY_TILE_SITE_TYPES}")

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/pin_assignments.json)

  add_custom_command(
    OUTPUT ${TILE}.pb_type.xml ${TILE}.model.xml
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${TILE_IMPORT}
    --part ${PROJECT_XRAY_TILE_PART}
    --tile ${PROJECT_XRAY_TILE_TILE}
    --site_directory ${symbiflow-arch-defs_BINARY_DIR}/${PROJECT_XRAY_TILE_PART}/primitives
    --site_types ${SITE_TYPES_COMMA}
    --pin_assignments ${PIN_ASSIGNMENTS}
    --output-pb-type ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.pb_type.xml
    --output-model ${CMAKE_CURRENT_BINARY_DIR}/${TILE}.model.xml
    DEPENDS
    ${TILE_IMPORT}
      ${DEPS}
      ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${TILE}.pb_type.xml GENERATED)
  get_file_target(PB_TYPE_TARGET ${TILE}.pb_type.xml)
  set_target_properties(${PB_TYPE_TARGET} PROPERTIES INCLUDE_FILES "${PB_TYPE_INCLUDE_FILES}")

  add_file_target(FILE ${TILE}.model.xml GENERATED)
  get_file_target(MODEL_TARGET ${TILE}.model.xml)
  set_target_properties(${MODEL_TARGET} PROPERTIES INCLUDE_FILES "${MODEL_INCLUDE_FILES}")
endfunction()

function(PROJECT_XRAY_ARCH)
  set(options)
  set(oneValueArgs PART USE_ROI)
  set(multiValueArgs TILE_TYPES)
  cmake_parse_arguments(
    PROJECT_XRAY_ARCH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(PART ${PROJECT_XRAY_ARCH_PART})

  set(ARCH_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray_arch_import.py)
  set(DEPS ${PRJXRAY_DB_DIR}/${PART}/tilegrid.json)

  set(ARCH_INCLUDE_FILES "")
  foreach(TILE_TYPE ${PROJECT_XRAY_ARCH_TILE_TYPES})
    string(TOLOWER ${TILE_TYPE} TILE_TYPE_LOWER)
    set(PB_TYPE_XML ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/tiles/${TILE_TYPE_LOWER}/${TILE_TYPE_LOWER}.pb_type.xml)
    set(MODEL_XML ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/tiles/${TILE_TYPE_LOWER}/${TILE_TYPE_LOWER}.model.xml)
    append_file_dependency(DEPS ${PB_TYPE_XML})
    append_file_dependency(DEPS ${MODEL_XML})

    get_file_target(PB_TYPE_TARGET ${PB_TYPE_XML})
    get_target_property(INCLUDE_FILES ${PB_TYPE_TARGET} INCLUDE_FILES)
    list(APPEND ARCH_INCLUDE_FILES ${PB_TYPE_XML} ${INCLUDE_FILES})

    get_file_target(MODEL_TARGET ${MODEL_XML})
    get_target_property(INCLUDE_FILES ${MODEL_TARGET} INCLUDE_FILES)
    list(APPEND ARCH_INCLUDE_FILES ${MODEL_XML} ${INCLUDE_FILES})
  endforeach()

  set(OUTPUTS arch.xml)
  set(ROI_ARG "")
  if(NOT "${PROJECT_XRAY_ARCH_USE_ROI}" STREQUAL "")
    set(OUTPUTS arch.xml synth_tiles.json)
    set(ROI_ARG --use_roi ${PROJECT_XRAY_ARCH_USE_ROI} --synth_tiles ${CMAKE_CURRENT_BINARY_DIR}/synth_tiles.json)
    list(APPEND DEPS ${PROJECT_XRAY_ARCH_USE_ROI})
  endif()

  append_file_dependency(DEPS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/pin_assignments.json)
  get_file_location(PIN_ASSIGNMENTS ${symbiflow-arch-defs_SOURCE_DIR}/${PART}/pin_assignments.json)

  string(REPLACE ";" "," TILE_TYPES_COMMA "${PROJECT_XRAY_ARCH_TILE_TYPES}")

  add_custom_command(
    OUTPUT ${OUTPUTS}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${ARCH_IMPORT}
    --part ${PROJECT_XRAY_ARCH_PART}
    --output-arch ${CMAKE_CURRENT_BINARY_DIR}/arch.xml
    --tile-types "${TILE_TYPES_COMMA}"
    --pin_assignments ${PIN_ASSIGNMENTS}
    ${ROI_ARG}
    DEPENDS
    ${ARCH_IMPORT}
    ${DEPS}
    ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE arch.xml GENERATED)
  get_file_target(ARCH_TARGET arch.xml)
  set_target_properties(${ARCH_TARGET} PROPERTIES INCLUDE_FILES "${ARCH_INCLUDE_FILES}")

  if(NOT "${PROJECT_XRAY_ARCH_USE_ROI}" STREQUAL "")
    add_file_target(FILE synth_tiles.json GENERATED)
    set_target_properties(${ARCH_TARGET} PROPERTIES USE_ROI TRUE)
    set_target_properties(${ARCH_TARGET} PROPERTIES SYNTH_TILES ${CMAKE_CURRENT_SOURCE_DIR}/synth_tiles.json)
  endif()
endfunction()

function(PROJECT_XRAY_PREPARE_DATABASE)
  set(options)
  set(oneValueArgs PART)
  set(multiValueArgs )
  cmake_parse_arguments(
    PROJECT_XRAY_PREPARE_DATABASE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(PART ${PROJECT_XRAY_PREPARE_DATABASE_PART})
  set(FORM_CHANNELS ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray_form_channels.py)
  set(ASSIGN_PINS ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray_assign_tile_pin_direction.py)
  file(GLOB DEPS ${PRJXRAY_DB_DIR}/${PART}/*.json)
  file(GLOB DEPS2 ${PRJXRAY_DIR}/prjxray/*.py)

  set(CHANNELS channels.json)
  add_custom_command(
    OUTPUT ${CHANNELS}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${FORM_CHANNELS}
    --db_root ${PRJXRAY_DB_DIR}/${PART}/
    --channels ${CMAKE_CURRENT_BINARY_DIR}/${CHANNELS}
    DEPENDS
    ${FORM_CHANNELS}
    ${DEPS} ${DEPS2} simplejson progressbar2
    ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${CHANNELS} GENERATED)

  set(PIN_ASSIGNMENTS pin_assignments.json)
  add_custom_command(
    OUTPUT ${PIN_ASSIGNMENTS}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils
    ${PYTHON3} ${ASSIGN_PINS}
    --db_root ${PRJXRAY_DB_DIR}/${PART}/
    --channels ${CMAKE_CURRENT_BINARY_DIR}/${CHANNELS}
    --pin_assignments ${CMAKE_CURRENT_BINARY_DIR}/${PIN_ASSIGNMENTS}
    DEPENDS
    ${FORM_CHANNELS}
    ${DEPS} ${DEPS2} ${CHANNELS}
    ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${PIN_ASSIGNMENTS} GENERATED)
endfunction()
