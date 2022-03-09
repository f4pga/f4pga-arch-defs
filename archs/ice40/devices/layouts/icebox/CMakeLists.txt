set(
  ICESTORM_DB
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm/icebox/icebox.py
  CACHE FILEPATH "Path to icebox.py module"
  )
set(
  ICEBOX_PATH
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm/icebox
  CACHE PATH "Path to icebox directory"
  )

set(ICE_UTILS_DIR ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils)
set(ICESTORM_LAYOUT_LIST ${ICE_UTILS_DIR}/ice40_list_layout_in_icebox.py)
set(ICESTORM_LAYOUT_IMPORT ${ICE_UTILS_DIR}/ice40_import_layout_from_icebox.py)

function(generate_all_icebox_layouts)
  # Use system python during configure time. Conda is setup during build time.
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${ICEBOX_PATH}
    ${PYTHON_EXECUTABLE} ${ICESTORM_LAYOUT_LIST}
    OUTPUT_VARIABLE ICESTORM_LAYOUT_PARTS
    RESULT_VARIABLE ERROR_CODE
    ERROR_VARIABLE ERROR_MESSAGES
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/
  )

  if(NOT ${ERROR_CODE} EQUAL 0)
    message(FATAL_ERROR "Error getting layout list: ${ERROR_CODE} ${ERROR_MESSAGES}")
  endif()

  string(
    REPLACE
      "\n"
      ";"
      ICESTORM_LAYOUT_PARTS_LIST
      "${ICESTORM_LAYOUT_PARTS}"
  )

  set(OUTPUTS "")
  foreach(PART ${ICESTORM_LAYOUT_PARTS_LIST})
    list(APPEND OUTPUTS ${PART}.fixed_layout.xml)
    list(APPEND OUTPUTS ${PART}.pinmap.csv)
  endforeach()

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(QUIET_CMD env QUIET_CMD)
  add_custom_command(
    OUTPUT ${OUTPUTS}
    COMMAND ${QUIET_CMD} ${CMAKE_COMMAND} -E env PYTHONPATH=${ICEBOX_PATH}:${PYUTILS_PATH}
    ${PYTHON3} ${ICESTORM_LAYOUT_IMPORT}
    DEPENDS
      ${QUIET_CMD}
      ${PYTHON3}
      ${ICESTORM_LAYOUT_IMPORT} ${ICESTORM_LAYOUT_LIST} ${ICESTORM_DB}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

  foreach(OUTPUT ${OUTPUTS})
    add_file_target(FILE ${OUTPUT} GENERATED)
  endforeach()
endfunction()

function(ADD_ICEBOX_LAYOUTS)
  set(options)
  set(oneValueArgs DEVICE PACKAGES)
  set(multiValueArgs)
  cmake_parse_arguments(
    SET_ICEBOX_LAYOUT
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(DEVICE ${SET_ICEBOX_LAYOUT_DEVICE})
  get_target_property_required(ARCH ${DEVICE} ARCH)
  foreach(PACKAGE ${SET_ICEBOX_LAYOUT_PACKAGES})
    set(PINMAP ${symbiflow-arch-defs_SOURCE_DIR}/ice40/devices/layouts/icebox/${DEVICE}.${PACKAGE}.pinmap.csv)
    set_target_properties(
      ${DEVICE}
      PROPERTIES
        ${PACKAGE}_PINMAP
        ${PINMAP}
    )

    # Set pinmap for dummy board
    set_target_properties(
      dummy_${ARCH}_${DEVICE}_${PACKAGE}
      PROPERTIES
      PINMAP ${PINMAP})
  endforeach()
endfunction()

generate_all_icebox_layouts()
