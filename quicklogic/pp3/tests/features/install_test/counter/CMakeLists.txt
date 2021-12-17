add_binary_toolchain_test(
    TEST_NAME counter
    DEVICE    ql-eos-s3
    PINMAP    PD64
    PCF       chandalar.pcf
    EXTRA_ARGS "-dump post_verilog"

    ASSERT_USAGE  PB-CLOCK=0,PB-GMUX=0,PB-BIDIR=5
    ASSERT_TIMING fmax>=30.0
    CHECK_CONSTRAINTS

    ASSERT_EXISTS
        "top_post_synthesis.v"
        "top_post_synthesis.no_split.v"
        "top_post_synthesis.sdf"
        "top.bit.v"
        "top.bit.v.pcf"
)
