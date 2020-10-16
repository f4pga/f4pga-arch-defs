FUNCTION(ADD_CELLS_SIM_TARGET OUTPUT_FILE)
  # ~~~
  # ADD_CELLS_SIM_TARGET(<output_file>)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(CONCATENATE_V_SOURCES_PY ${symbiflow-arch-defs_SOURCE_DIR}/utils/concatenate_v_sources.py)
  get_target_property(VERILOG_SOURCES QL_CELLS_SIM_DEPS VERILOG_SOURCES)

  add_custom_target(ql_cells_sim_tech_dir
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/techmap)

  add_custom_command(
    OUTPUT ${OUTPUT_FILE}
    DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${CONCATENATE_V_SOURCES_PY} QL_CELLS_SIM_DEPS
            ql_cells_sim_tech_dir
    COMMAND ${PYTHON3} ${CONCATENATE_V_SOURCES_PY} ${VERILOG_SOURCES} ${OUTPUT_FILE}
    COMMAND_EXPAND_LISTS
    COMMENT "Generating ${OUTPUT_FILE}"
    )
  add_file_target(FILE ${OUTPUT_FILE} GENERATED ABSOLUTE)
endfunction(ADD_CELLS_SIM_TARGET)

function(ADD_TO_CELLS_SIM file)
  # ~~~
  # ADD_TO_CELLS_SIM(<file>)

  set(FILE_LOC, "")
  set(FILE_TARGET, "")
  get_file_location(FILE_LOC ${file})
  get_file_target(FILE_TARGET ${file})

  set_property(TARGET QL_CELLS_SIM_DEPS APPEND PROPERTY VERILOG_SOURCES ${FILE_LOC})
  add_dependencies(QL_CELLS_SIM_DEPS ${FILE_TARGET})
endfunction(ADD_TO_CELLS_SIM)

