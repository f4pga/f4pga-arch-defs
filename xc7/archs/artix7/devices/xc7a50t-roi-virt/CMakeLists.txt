project_xray_arch(
  PART artix7
  DEVICE ${DEVICE}
  TILE_TYPES INT_R INT_L CLBLL_R CLBLL_L CLBLM_R CLBLM_L BRAM_L
  USE_ROI ${ROI_DIR}/design.json
)

define_device_type(
  DEVICE_TYPE ${DEVICE}-roi-virt
  ARCH artix7
  ARCH_XML arch.xml
)
