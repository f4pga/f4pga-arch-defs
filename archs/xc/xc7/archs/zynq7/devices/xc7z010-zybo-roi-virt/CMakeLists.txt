add_xc_device_define_type(
  ARCH zynq7
  DEVICE xc7z010-zybo
  ROI_DIR ${PRJXRAY_DB_DIR}/zynq7/harness/zybo/swbut
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
