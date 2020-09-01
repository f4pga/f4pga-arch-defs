add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  USE_ROI
  DEVICES xc7a50t-basys3 xc7a50t-arty-uart xc7a50t-arty-swbut xc7a50t-arty-swbut-pr1 xc7a50t-arty-switch-processing-pr1 xc7a50t-arty-switch-processing-pr2

)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  USE_OVERLAY
  DEVICES xc7a50t-arty-swbut-overlay xc7a50t-arty-switch-processing-overlay
)
add_xc_device_define(
  ARCH artix7
  PART xc7a50tfgg484-1
  DEVICES xc7a50t xc7a50t-bottom
)
