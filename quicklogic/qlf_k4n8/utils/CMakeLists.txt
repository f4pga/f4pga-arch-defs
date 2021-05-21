get_target_property_required(PYTHON3 env PYTHON3)

# Add a target that runs tests for Python utils
add_custom_target(all_python_tests
    COMMAND
        ${CMAKE_COMMAND} -E env
        PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils:$PYTHONPATH
        ${PYTHON3} -m pytest --doctest-modules -vv
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_dependencies(all_quicklogic_tests all_python_tests)
