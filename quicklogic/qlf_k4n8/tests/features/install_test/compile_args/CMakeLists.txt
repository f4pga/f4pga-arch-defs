add_binary_test(
    binary_toolchain_test_compile_args
    compile_args
    qlf_k4n8
    "+incdir+${CMAKE_CURRENT_SOURCE_DIR}/includes -y ${CMAKE_CURRENT_SOURCE_DIR}/libraries +libext+not_v"
)
