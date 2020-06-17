add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  USE_ROI
  DEVICES xc7a50t-basys3 xc7a50t-arty-uart xc7a50t-arty-swbut
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  DEVICES xc7a50t-arty-swbut-top-left-pr
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  OVERLAY
  DEVICES xc7a50t-arty-swbut-overlay
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  DEVICES xc7a50t xc7a50t-bottom
)
