set(
  PRJXRAY_DIR
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/prjxray-db
  CACHE PATH "Path to prjxray database files"
)

function(get_project_xray_dependencies var part element)
  list(APPEND ${var} ${PRJXRAY_DIR}/Info.md)
  file(GLOB other_sources ${PRJXRAY_DIR}/${part}/*${element}*.db)
  list(APPEND ${var} ${other_sources})
  set(${var} ${${var}} PARENT_SCOPE)
endfunction()

function(PROJECT_XRAY_INT)
  set(options)
  set(oneValueArgs PART INT)
  set(multiValueArgs)
  cmake_parse_arguments(
    PROJECT_XRAY_INT
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  string(TOLOWER ${PROJECT_XRAY_INT_INT} INT)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(INT_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray-int-import.py)
  get_project_xray_dependencies(DEPS ${PROJECT_XRAY_INT_PART} ${INT})
  add_custom_command(
    OUTPUT ${INT}.pb_type.xml
    COMMAND ${PYTHON3} ${INT_IMPORT}
      --part ${PROJECT_XRAY_INT_PART}
      --tile ${PROJECT_XRAY_INT_INT}
      --output-pb-type ${CMAKE_CURRENT_BINARY_DIR}/${INT}.pb_type.xml
    DEPENDS
      ${INT_IMPORT}
      ${DEPS}
      ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${INT}.pb_type.xml GENERATED)
endfunction()

function(PROJECT_XRAY_CLB)
  set(options)
  set(oneValueArgs PART CLB)
  set(multiValueArgs)
  cmake_parse_arguments(
    PROJECT_XRAY_CLB
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  string(TOLOWER ${PROJECT_XRAY_CLB_CLB} CLB)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(CLB_IMPORT ${symbiflow-arch-defs_SOURCE_DIR}/artix7/utils/prjxray-clb-import.py)
  get_project_xray_dependencies(DEPS ${PROJECT_XRAY_CLB_PART} ${CLB})

  foreach(DEP
    ${symbiflow-arch-defs_SOURCE_DIR}/artix7/primitives/slicel/slicel.pb_type.xml
    ${symbiflow-arch-defs_SOURCE_DIR}/artix7/primitives/slicel/slicel.model.xml
    )
    append_file_dependency(DEPS ${DEP})
  endforeach()

  add_custom_command(
    OUTPUT ${CLB}.pb_type.xml ${CLB}.model.xml
    COMMAND ${PYTHON3} ${CLB_IMPORT}
      --part ${PROJECT_XRAY_CLB_PART}
      --tile ${PROJECT_XRAY_CLB_CLB}
      --output-pb-type ${CMAKE_CURRENT_BINARY_DIR}/${CLB}.pb_type.xml
      --output-model ${CMAKE_CURRENT_BINARY_DIR}/${CLB}.model.xml
    DEPENDS
    ${CLB_IMPORT}
    ${DEPS}
    ${PYTHON3} ${PYTHON3_TARGET}
    )

  add_file_target(FILE ${CLB}.pb_type.xml GENERATED)
  add_file_target(FILE ${CLB}.model.xml GENERATED)
endfunction()
