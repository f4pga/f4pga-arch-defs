add_xc7_device_define_type(
  ARCH artix7
  DEVICE xc7a50t-arty-uart
  ROI_PART xc7a35tcsg324-1
  ROI_DIR ${PRJXRAY_DB_DIR}/artix7/harness/arty-a7/uart
  TILE_TYPES SLICEL SLICEM BRAM_L
  NAME arty
)
