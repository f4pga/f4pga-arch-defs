add_xc_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-arty-swbut-pr2
  ROI_DIR ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/archs/artix7/devices/xc7a50t-arty-swbut-pr2-roi-virt
  TILE_TYPES
    CLBLL_L
    CLBLL_R
    CLBLM_L
    CLBLM_R
    BRAM_L
  PB_TYPES
    SLICEL
    SLICEM
    BRAM_L
)
