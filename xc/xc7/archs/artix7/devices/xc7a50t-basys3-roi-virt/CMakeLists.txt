add_xc_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-basys3
  ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/basys3/swbut
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

