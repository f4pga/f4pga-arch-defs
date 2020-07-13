add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  USE_ROI
  DEVICES xc7a50t-basys3 xc7a50t-arty-uart xc7a50t-arty-swbut xc7a50t-arty-swbut-pr1
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  USE_OVERLAY
  CONTAINED_ROI_DEVICES xc7a50t-arty-swbut-pr1
  DEVICES xc7a50t-arty-swbut-overlay
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  DEVICES xc7a50t xc7a50t-bottom
)
