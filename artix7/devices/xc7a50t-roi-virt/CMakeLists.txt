project_xray_arch(
  PART artix7
  TILE_TYPES INT_R INT_L CLBLL_R CLBLL_L CLBLM_R CLBLM_L BRAM_R BRAM_L
  USE_ROI ${ROI_DIR}/design.json
  )

define_device_type(
  DEVICE_TYPE xc7a50t-roi-virt
  ARCH artix7
  ARCH_XML arch.xml
  )
