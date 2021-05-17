set(SLOW_CORNER_DEVICE "qlf_k4n8-qlf_k4n8_umc22_slow")
set(FAST_CORNER_DEVICE "qlf_k4n8-qlf_k4n8_umc22_fast")

add_quicklogic_board(
  BOARD      ${FAST_CORNER_DEVICE}_board
  FAMILY     qlf_k4n8
  DEVICE     ${FAST_CORNER_DEVICE}
  PINMAP_XML interface-mapping_24x24.xml
  PACKAGE    ${FAST_CORNER_DEVICE}
  PINMAP     qlf_k4n8-qlf_k4n8_umc22.csv
  FABRIC_PACKAGE qlf_k4n8_umc22
)

add_quicklogic_board(
  BOARD      ${SLOW_CORNER_DEVICE}_board
  FAMILY     qlf_k4n8
  DEVICE     ${SLOW_CORNER_DEVICE}
  PINMAP_XML interface-mapping_24x24.xml
  PACKAGE    ${SLOW_CORNER_DEVICE}
  PINMAP     qlf_k4n8-qlf_k4n8_umc22.csv
  FABRIC_PACKAGE qlf_k4n8_umc22
)
