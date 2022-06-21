add_file_target(FILE chandalar.pcf)

set(CONFIGURATIONS
    1024x16,1
    1024x8,1
    2048x8,1
    512x16,1
    512x32,1
)

foreach(FIELDS ${CONFIGURATIONS})
    string(REPLACE "," ";" FIELDS ${FIELDS})
    list(GET FIELDS 0 NAME)
    list(GET FIELDS 1 RAM_COUNT)

    set(SOURCES r${NAME}_${NAME}.v r${NAME}_wrapper.v)
    foreach(SOURCE ${SOURCES})
        add_file_target(FILE ${SOURCE} SCANNER_TYPE verilog)
    endforeach()

    add_fpga_target(
      NAME regression-ram_${NAME}-ql-chandalar
      BOARD quickfeather
      SOURCES ${SOURCES}
      INPUT_IO_FILE chandalar.pcf
      EXPLICIT_ADD_FILE_TARGET
      ASSERT_BLOCK_TYPES_ARE_USED PB-CLOCK=2,PB-GMUX=2,PB-RAM=${RAM_COUNT}
    )

    add_dependencies(all_eos_s3_tests_regression regression-ram_${NAME}-ql-chandalar_assert_usage)

endforeach()
