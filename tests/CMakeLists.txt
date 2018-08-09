set(FULL_BOARDS dummy_ice40_hx1k_tq144 )
set(SMALL_BOARDS dummy_testarch_4x4_dummy)
set(ARTIX7_BOARDS dummy_artix7_xc7a50t_test)
set(BOARDS ${FULL_BOARDS} ${SMALL_BOARDS} ${ARTIX7_BOARDS})

function(add_simple_test)
  # ~~~
  #   ADD_SIMPLE_TEST(
  #     NAME <name of test>
  #     SOURCES <list of sources for test>
  #     BOARDS <list of boards to test against>
  #     [ROUTE_ONLY]
  #     [EQUIV_CHECK_SCRIPT <filename of yosys script to prove gold and gate>]
  #   )
  # ~~~
  #
  # ADD_SIMPLE_TEST creates test targets that check routing and equivilence
  # between original source, post-synthesis and post-place and route modules.
  set(options ROUTE_ONLY)
  set(oneValueArgs NAME EQUIV_CHECK_SCRIPT)
  set(multiValueArgs SOURCES BOARDS)
  cmake_parse_arguments(
    ADD_SIMPLE_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  foreach(SRC ${ADD_SIMPLE_TEST_SOURCES})
    add_file_target(
      FILE ${SRC}
      SCANNER_TYPE verilog
      )
  endforeach()

  set(EQUIV_CHECK_SCRIPT ${ADD_SIMPLE_TEST_EQUIV_CHECK_SCRIPT})

  if("${EQUIV_CHECK_SCRIPT}" STREQUAL "")
    set(EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/yosys/miter_and_tempinduct.ys)
  endif()

  set(CHECK_TEST_ARGS "")
  if(NOT ${ADD_SIMPLE_TEST_ROUTE_ONLY})
    set(CHECK_TEST_ARGS EMIT_CHECK_TESTS EQUIV_CHECK_SCRIPT ${EQUIV_CHECK_SCRIPT})
  endif()


  foreach(BOARD ${ADD_SIMPLE_TEST_BOARDS})
    get_target_property_required(DEVICE ${BOARD} DEVICE)
    get_target_property_required(ARCH ${DEVICE} ARCH)
    get_target_property_required(NO_PINS ${ARCH} NO_PINS)

    set(INPUT_IO_FILE_ARG "")
    if(NOT ${NO_PINS})
      generate_pinmap(
        NAME ${BOARD}.pcf
        TOP top
        BOARD ${BOARD}
        SOURCES ${ADD_SIMPLE_TEST_SOURCES}
        )
      set(INPUT_IO_FILE_ARG INPUT_IO_FILE ${BOARD}.pcf)
    endif()

    add_fpga_target(
      NAME ${ADD_SIMPLE_TEST_NAME}_${BOARD}
      BOARD ${BOARD}
      ${INPUT_IO_FILE_ARG}
      SOURCES ${ADD_SIMPLE_TEST_SOURCES}
      EXPLICIT_ADD_FILE_TARGET
      ${CHECK_TEST_ARGS}
      )

    add_dependencies(all_route_tests ${ADD_SIMPLE_TEST_NAME}_${BOARD}_route)
  endforeach()
endfunction()

add_subdirectory(0-const)
add_subdirectory(1-wire)
add_subdirectory(2-mwire)
add_subdirectory(3-ff)
add_subdirectory(3-lut)
add_subdirectory(4-lutff)
add_subdirectory(4-mlut)
add_subdirectory(5-lut_cascade_1)
add_subdirectory(6-big_xor)
add_subdirectory(6-counter)
add_subdirectory(6-led)
add_subdirectory(6-rot)
