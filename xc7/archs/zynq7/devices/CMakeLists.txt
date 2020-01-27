add_xc7_device_define(
  ARCH zynq7
  PART xc7z010clg400-1
  DEVICES xc7z010-zybo
  USE_ROI
)

add_xc7_device_define(
  ARCH zynq7
  PART xc7z010clg400-1
  DEVICES xc7z010
)

# Zynq 7020 contains tiles that are not present in 7010. Since we cannot have
# different tile sets per device, this one is disabled for now.
#add_xc7_device_define(
#  ARCH zynq7
#  DEVICES xc7z020
#)

