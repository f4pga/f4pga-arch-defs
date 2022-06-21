add_binary_toolchain_test(
    TEST_NAME counter_assp
    DEVICE    ql-eos-s3
    PINMAP    PD64
    PCF       chandalar.pcf
    EXTRA_ARGS "-dump post_verilog"

    ASSERT_BLOCK_TYPES_ARE_USED PB-ASSP=1,PB-GMUX=1
    CHECK_CONSTRAINTS

    ASSERT_EXISTS
        "top_post_synthesis.v"
        "top_merged_post_implementation.v"
        "top_post_synthesis.sdf"
        "top.bit.v"
        "top.bit.v.pcf"
)
