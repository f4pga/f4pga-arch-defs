# List all verilog files
file(GLOB VERILOG_FILES LIST_DIRECTORIES false "*.v")

# Add targets
foreach(VERILOG_FILE ${VERILOG_FILES})
    get_filename_component(VERILOG_FILE_NOPATH ${VERILOG_FILE} NAME)
    add_file_target(FILE ${VERILOG_FILE_NOPATH} SCANNER_TYPE verilog)
endforeach()

set(TARGET_NAME v2x_sanity_checks)
set(DEPENDS_LIST "")

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)
list(APPEND DEPENDS_LIST ${PYTHON3} ${PYTHON3_TARGET})

get_target_property_required(YOSYS env YOSYS)
get_target_property(YOSYS_TARGET env YOSYS_TARGET)
list(APPEND DEPENDS_LIST ${YOSYS} ${YOSYS_TARGET})

add_dependencies(all_v2x_tests ${TARGET_NAME})

add_custom_target(${TARGET_NAME})
add_custom_command(
    TARGET ${TARGET_NAME}
    COMMAND
      ${CMAKE_COMMAND} -E env YOSYS=${YOSYS} ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/tests/sanity_checks/sanity_checks.py
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/tests/sanity_checks/
    DEPENDS
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/vlog_to_pbtype.py
      ${symbiflow-arch-defs_SOURCE_DIR}/utils/vlog/tests/sanity_checks/sanity_checks.py
)

