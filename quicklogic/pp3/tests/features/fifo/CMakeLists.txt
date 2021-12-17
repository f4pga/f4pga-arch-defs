add_file_target(FILE chandalar.pcf)
add_file_target(FILE chandalar_1clk.pcf)

set(CONFIGURATIONS
    af,512x16,1
    af,512x32,1
    f,1024x16,1
)

foreach(FIELDS ${CONFIGURATIONS})
    string(REPLACE "," ";" FIELDS ${FIELDS})
    list(GET FIELDS 0 TYPE)
    list(GET FIELDS 1 NAME)
    list(GET FIELDS 2 RAM_COUNT)

    set(SOURCES ${TYPE}${NAME}_${NAME}.v ${TYPE}${NAME}_wrapper.v)
    foreach(SOURCE ${SOURCES})
        add_file_target(FILE ${SOURCE} SCANNER_TYPE verilog)
    endforeach()

    if("${TYPE}" STREQUAL "f")
        set(PCF_SUFFIX "_1clk")
        set(NUM_CLK 1)
    else()
        set(PCF_SUFFUX "")
        set(NUM_CLK 2)
    endif()

    add_fpga_target(
      NAME regression-fifo_${TYPE}${NAME}-ql-chandalar
      BOARD quickfeather
      SOURCES ${SOURCES}
      INPUT_IO_FILE chandalar${PCF_SUFFIX}.pcf
      EXPLICIT_ADD_FILE_TARGET
      ASSERT_USAGE PB-CLOCK=${NUM_CLK},PB-GMUX=${NUM_CLK},PB-RAM=${RAM_COUNT}
    )

    add_dependencies(all_eos_s3_tests_regression regression-fifo_${TYPE}${NAME}-ql-chandalar_assert_usage)

endforeach()
