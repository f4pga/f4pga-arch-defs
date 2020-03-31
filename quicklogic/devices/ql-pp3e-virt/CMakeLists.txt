set(LIB_TIMING_FILES "*_BC_120V.lib" "*_WC_120V.lib" "BIDIR_COM_BC_180V.lib")
quicklogic_define_device_type(
  DEVICE ql-pp3e
  ARCH ql-s3
  PACKAGES wlcsp
  ROUTING_TIMING_FILE_NAME qlal3s2_RoutingDelays.csv
  TECHFILE_NAME QLAL3S2.xml
  LIB_TIMING_FILES ${LIB_TIMING_FILES}
  PB_TYPES
    GND VCC
    LOGIC
    IOB
)
