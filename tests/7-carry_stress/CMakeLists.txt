
get_target_property_required(PYTHON3 env PYTHON3)
foreach(CARRY_DEPTH 1 2 3 4 7 8 9 15 16 17 31 32)
    set(CARRY_TEST carry_test_${CARRY_DEPTH}_init0.v)
    add_custom_command(
        OUTPUT ${CARRY_TEST}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate_carry_test.py --init 0 --carry_depth
            ${CARRY_DEPTH} > ${CARRY_TEST}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/generate_carry_test.py ${PYTHON3}
        )
    add_file_target(
        FILE ${CARRY_TEST}
        GENERATED
        )

    add_simple_test(
        NAME 7-carry_stress_init0_depth_${CARRY_DEPTH}
        SOURCES ${CARRY_TEST}
        BOARDS ${FULL_BOARDS}
        EXPLICIT_ADD_FILE_TARGET
        ROUTE_ONLY
        )

    set(CARRY_TEST carry_test_${CARRY_DEPTH}_init1.v)
    add_custom_command(
        OUTPUT ${CARRY_TEST}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate_carry_test.py --init 1 --carry_depth
            ${CARRY_DEPTH} > ${CARRY_TEST}
        DEPENDS generate_carry_test.py ${PYTHON3}
        )
    add_file_target(
        FILE ${CARRY_TEST}
        GENERATED
        )

    add_simple_test(
        NAME 7-carry_stress_init1_depth_${CARRY_DEPTH}
        SOURCES ${CARRY_TEST}
        BOARDS ${FULL_BOARDS}
        EXPLICIT_ADD_FILE_TARGET
        ROUTE_ONLY
        )

    set(CARRY_TEST carry_test_${CARRY_DEPTH}_init_fabric.v)
    add_custom_command(
        OUTPUT ${CARRY_TEST}
        COMMAND ${PYTHON3} ${CMAKE_CURRENT_SOURCE_DIR}/generate_carry_test.py --init fabric --carry_depth
            ${CARRY_DEPTH} > ${CARRY_TEST}
        DEPENDS generate_carry_test.py ${PYTHON3}
        )
    add_file_target(
        FILE ${CARRY_TEST}
        GENERATED
        )

    add_simple_test(
        NAME 7-carry_stress_init_fabric_depth_${CARRY_DEPTH}
        SOURCES ${CARRY_TEST}
        BOARDS ${FULL_BOARDS}
        EXPLICIT_ADD_FILE_TARGET
        ROUTE_ONLY
        )
endforeach()
