add_xc_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-arty-swbut-overlay
  OVERLAY ${CMAKE_CURRENT_SOURCE_DIR}
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
