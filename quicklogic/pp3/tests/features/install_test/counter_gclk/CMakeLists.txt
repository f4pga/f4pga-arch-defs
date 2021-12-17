add_binary_toolchain_test(
    TEST_NAME counter_gclk
    DEVICE    ql-eos-s3
    PINMAP    PD64
    PCF       chandalar.pcf
    EXTRA_ARGS "-dump post_verilog"

    CHECK_CONSTRAINTS
    ASSERT_USAGE  PB-CLOCK=1,PB-GMUX=1,PB-BIDIR=4
    ASSERT_TIMING fmax>56.0

    ASSERT_EXISTS
        "top_post_synthesis.v"
        "top_post_synthesis.no_split.v"
        "top_post_synthesis.sdf"
        "top.bit.v"
        "top.bit.v.pcf"
)
