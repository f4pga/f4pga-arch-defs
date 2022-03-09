add_binary_toolchain_test(
    TEST_NAME  compile_args
    DEVICE     qlf_k4n8
    PINMAP     pinmap_qlf_k4n8_umc22.csv
    EXTRA_ARGS "+incdir+${CMAKE_CURRENT_SOURCE_DIR}/includes -y ${CMAKE_CURRENT_SOURCE_DIR}/libraries +libext+not_v"
)
