function(generate_all_icebox_layouts)
  get_target_property_required(PYTHON3 env PYTHON3)

  set(ICESTORM_DB ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm/icebox/icebox.py)
  set(ICE_UTILS_DIR ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils)
  set(ICESTORM_LAYOUT_LIST ${ICE_UTILS_DIR}/ice40_list_layout_in_icebox.py)
  set(ICESTORM_LAYOUT_IMPORT ${ICE_UTILS_DIR}/ice40_import_layout_from_icebox.py)

  execute_process(
    COMMAND ${PYTHON3} ${ICESTORM_LAYOUT_LIST}
    OUTPUT_VARIABLE ICESTORM_LAYOUT_PARTS
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/
    )

  string(REPLACE "\n" ";" ICESTORM_LAYOUT_PARTS_LIST "${ICESTORM_LAYOUT_PARTS}")

  set(OUTPUTS "")
  foreach(PART ${ICESTORM_LAYOUT_PARTS_LIST})
    list(APPEND OUTPUTS ${PART}.fixed_layout.xml)
    list(APPEND OUTPUTS ${PART}.pinmap.csv)
  endforeach()

  add_custom_command(
    OUTPUT ${OUTPUTS}
    COMMAND ${PYTHON3} ${ICESTORM_LAYOUT_IMPORT}
    DEPENDS ${ICESTORM_LAYOUT_IMPORT} ${ICESTORM_LAYOUT_LIST} ${ICESTORM_DB}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )

  foreach(OUTPUT ${OUTPUTS})
    MAKE_FILE_TARGET(FILE ${OUTPUT} GENERATED)
  endforeach()
endfunction()

generate_all_icebox_layouts()
