add_xc_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-arty-switch-processing-overlay
  OVERLAY_DIR ${f4pga-arch-defs_SOURCE_DIR}/xilinx/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt
  TILE_TYPES
    CLBLL_L
    CLBLL_R
    CLBLM_L
    CLBLM_R
    BRAM_L
    LIOPAD_M
    LIOPAD_S
    LIOPAD_SING
    RIOPAD_M
    RIOPAD_S
    RIOPAD_SING
    CLK_BUFG_BOT_R
    CLK_BUFG_TOP_R
    CMT_TOP_L_UPPER_T
    CMT_TOP_R_UPPER_T
    HCLK_IOI3
  PB_TYPES
    SLICEL
    SLICEM
    BRAM_L
    IOPAD
    IOPAD_M
    IOPAD_S
    BUFGCTRL
    PLLE2_ADV
    HCLK_IOI3
)
