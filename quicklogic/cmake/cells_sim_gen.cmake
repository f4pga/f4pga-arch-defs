function(ADD_CELLS_SIM_TARGET output_file)
  # ~~~
  # ADD_CELLS_SIM_TARGET(<output_file>)

  add_file_target(FILE ${output_file} GENERATED)
  set(FILE_TARGET, "")
  get_file_target(FILE_TARGET ${output_file})
  set(FILE_DIR, "")
  get_filename_component(FILE_DIR ${output_file} DIRECTORY)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(CONCATENATE_V_SOURCES_PY ${symbiflow-arch-defs_SOURCE_DIR}/utils/concatenate_v_sources.py)

  add_custom_command(
    OUTPUT ${output_file}
    DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${CONCATENATE_V_SOURCES_PY}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${FILE_DIR}/"
    COMMAND ${PYTHON3} ${CONCATENATE_V_SOURCES_PY} $<TARGET_PROPERTY:${FILE_TARGET},VERILOG_SOURCES> ${output_file}
    COMMAND_EXPAND_LISTS
    COMMENT "Generating ${output_file}"
    )
  set_property(TARGET ${FILE_TARGET} PROPERTY VERILOG_SOURCES "")

  set(CELLS_SIM_TARGET_NAME "${FILE_TARGET}" PARENT_SCOPE)
endfunction(ADD_CELLS_SIM_TARGET)


function(ADD_TO_CELLS_SIM file)
  # ~~~
  # ADD_TO_CELLS_SIM(<file>)

  set(FILE_LOC, "")
  set(FILE_TARGET, "")
  get_file_location(FILE_LOC ${file})
  get_file_target(FILE_TARGET ${file})

  set_property(TARGET ${CELLS_SIM_TARGET_NAME} APPEND PROPERTY VERILOG_SOURCES ${FILE_LOC})
  add_dependencies(${CELLS_SIM_TARGET_NAME} ${FILE_TARGET})
endfunction(ADD_TO_CELLS_SIM)


