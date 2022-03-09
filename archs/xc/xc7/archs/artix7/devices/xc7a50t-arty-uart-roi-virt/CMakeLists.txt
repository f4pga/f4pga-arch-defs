add_xc_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-arty-uart
  ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/arty-a7/uart
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
