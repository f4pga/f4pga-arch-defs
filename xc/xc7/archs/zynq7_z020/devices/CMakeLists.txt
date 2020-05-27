# Zynq 7020 contains tiles that are not present in 7010. Since we cannot have
# different tile sets per device, this one is disabled for now.
add_xc_device_define(
  ARCH zynq7_z020
  PART xc7z020clg484-1
  DEVICES xc7z020
)

