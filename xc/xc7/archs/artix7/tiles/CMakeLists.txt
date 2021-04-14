add_subdirectory(bram_l)
add_subdirectory(bram_r)
add_subdirectory(clbll_l)
add_subdirectory(clbll_r)
add_subdirectory(clblm_l)
add_subdirectory(clblm_r)
add_subdirectory(slicel)
add_subdirectory(slicem)
add_subdirectory(clk_bufg_top_r)
add_subdirectory(clk_bufg_bot_r)
add_subdirectory(bufgctrl)
add_subdirectory(hclk_ioi3)
add_subdirectory(gtpe2_common)
add_subdirectory(gtpe2_channel)
add_subdirectory(ibufds_gte2)
add_subdirectory(ipad)
add_subdirectory(opad)
add_subdirectory(gtp_common)
add_subdirectory(gtp_channel_0)
add_subdirectory(gtp_channel_1)
add_subdirectory(gtp_channel_2)
add_subdirectory(gtp_channel_3)

set(IOPAD_SITES IOB33 IDELAYE2 ILOGICE3 OLOGICE3)
set(IOPAD_S_SITES IOB33S IDELAYE2 ILOGICE3 OLOGICE3)
set(IOPAD_M_SITES IOB33M IDELAYE2 ILOGICE3 OLOGICE3)

project_ray_equiv_tile(
  ARCH artix7
  TILES RIOPAD_M RIOPAD_S RIOPAD_SING LIOPAD_M LIOPAD_S LIOPAD_SING
  PB_TYPES IOPAD IOPAD_S IOPAD_M
  PB_TYPE_SITES IOPAD_SITES IOPAD_S_SITES IOPAD_M_SITES
  SITE_EQUIV IOB33M=IOB33 IOB33S=IOB33
  )

set(PLLE2_ADV_SITES PLLE2_ADV)

project_ray_equiv_tile(
  ARCH artix7
  TILES CMT_TOP_L_UPPER_T CMT_TOP_R_UPPER_T
  PB_TYPES PLLE2_ADV
  PB_TYPE_SITES PLLE2_ADV_SITES
  )
