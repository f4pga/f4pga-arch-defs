set(FULL_BOARDS dummy_ice40_hx1k_tq144 qlf_k4n8-qlf_k4n8_umc22_slow_board)
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
list(APPEND FULL_BOARDS dummy_artix7_xc7a50t-basys3_test)
endif()
set(SMALL_BOARDS dummy_testarch_4x4_dummy dummy_testarch_10x10_dummy)
set(BOARDS ${FULL_BOARDS} ${SMALL_BOARDS})

foreach(BOARD ${BOARDS})
    add_custom_target(all_${BOARD})
endforeach()

function(add_simple_test)
  # ~~~
  #   ADD_SIMPLE_TEST(
  #     NAME <name of test>
  #     SOURCES <list of sources for test>
  #     BOARDS <list of boards to test against>
  #     [ROUTE_ONLY]
  #     [EQUIV_CHECK_SCRIPT <filename of yosys script to prove gold and gate>]
  #     [EXPLICIT_ADD_FILE_TARGET]
  #     [DEFINES <list of defines>]
  #   )
  # ~~~
  #
  # ADD_SIMPLE_TEST creates test targets that check routing and equivilence
  # between original source, post-synthesis and post-place and route modules.
  set(options ROUTE_ONLY EXPLICIT_ADD_FILE_TARGET NO_SYNTHESIS)
  set(oneValueArgs NAME EQUIV_CHECK_SCRIPT)
  set(multiValueArgs SOURCES BOARDS DEFINES)
  cmake_parse_arguments(
    ADD_SIMPLE_TEST
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  if(NOT ${ADD_SIMPLE_TEST_EXPLICIT_ADD_FILE_TARGET})
    foreach(SRC ${ADD_SIMPLE_TEST_SOURCES})
      add_file_target(
        FILE ${SRC}
        SCANNER_TYPE verilog
        )
    endforeach()
  endif()

  set(EQUIV_CHECK_SCRIPT ${ADD_SIMPLE_TEST_EQUIV_CHECK_SCRIPT})

  if("${EQUIV_CHECK_SCRIPT}" STREQUAL "")
    set(EQUIV_CHECK_SCRIPT
      ${symbiflow-arch-defs_SOURCE_DIR}/common/yosys/miter_and_tempinduct.ys)
  endif()

  foreach(BOARD ${ADD_SIMPLE_TEST_BOARDS})
    get_target_property_required(DEVICE ${BOARD} DEVICE)
    get_target_property_required(ARCH ${DEVICE} ARCH)
    get_target_property_required(NO_PINS ${ARCH} NO_PINS)
    get_target_property_required(NO_TEST_PINS ${ARCH} NO_TEST_PINS)
    get_target_property_required(NO_BITSTREAM ${ARCH} NO_BITSTREAM)

    set_target_properties(${BOARD} PROPERTIES PART "dummy")

    set(INPUT_IO_FILE_ARG "")
    if(NOT ${NO_PINS} AND NOT ${NO_TEST_PINS})
      generate_pinmap(
          NAME ${ADD_SIMPLE_TEST_NAME}_${BOARD}.pcf
        TOP top
        BOARD ${BOARD}
        SOURCES ${ADD_SIMPLE_TEST_SOURCES}
        )
      set(INPUT_IO_FILE_ARG INPUT_IO_FILE ${ADD_SIMPLE_TEST_NAME}_${BOARD}.pcf)
    endif()

    set(NO_SYNTHESIS_ARG "")
    if(${ADD_SIMPLE_TEST_NO_SYNTHESIS})
      set(NO_SYNTHESIS_ARG NO_SYNTHESIS)
    endif()

    set(CHECK_TEST_ARGS "")
    if(NOT ${ADD_SIMPLE_TEST_ROUTE_ONLY} AND NOT ${NO_BITSTREAM})
      set(CHECK_TEST_ARGS EMIT_CHECK_TESTS EQUIV_CHECK_SCRIPT ${EQUIV_CHECK_SCRIPT})
    else()
      set(CHECK_TEST_ARGS "ROUTE_ONLY")
    endif()

    add_fpga_target(
      NAME ${ADD_SIMPLE_TEST_NAME}_${BOARD}
      BOARD ${BOARD}
      ${INPUT_IO_FILE_ARG}
      SOURCES ${ADD_SIMPLE_TEST_SOURCES}
      EXPLICIT_ADD_FILE_TARGET
      ${CHECK_TEST_ARGS}
      ${NO_SYNTHESIS_ARG}
      DEFINES ${ADD_SIMPLE_TEST_DEFINES}
      )

    add_dependencies(all_route_tests ${ADD_SIMPLE_TEST_NAME}_${BOARD}_route)
    add_dependencies(all_${BOARD} ${ADD_SIMPLE_TEST_NAME}_${BOARD}_route)
  endforeach()
endfunction()

add_subdirectory(0-const)
add_subdirectory(1-wire)
add_subdirectory(2-mwire)
add_subdirectory(3-ff)
add_subdirectory(3-lut4)
add_subdirectory(3-lut5x2)
add_subdirectory(3-lut6)
add_subdirectory(3-lut7)
add_subdirectory(3-lut8)
add_subdirectory(4-lutff)
add_subdirectory(4-mlut)
add_subdirectory(5-lut_cascade_1)
add_subdirectory(6-big_xor)
add_subdirectory(6-counter)
add_subdirectory(6-led)
add_subdirectory(6-rot)
add_subdirectory(7-carry_stress)
add_subdirectory(9-soc)
add_subdirectory(9-scalable_proc)

