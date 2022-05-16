set(LIB_TIMING_FILES "*_ss_0p990v_m040c.lib" "*_ss_0p990v_m040c_Cmax_2P97V.lib")
set(DONT_NORMALIZE_FILES "RAM_ss_0p990v_m040c.lib" "RAM_ff_0p990v_m040c.lib")

set(FAMILY "pp3")
set(DEVICE "ql-eos-s3")
set(PACKAGES "wlcsp")
set(DEVICE_TYPE "ql-eos-s3-virt")

quicklogic_define_device_type(
  FAMILY ${FAMILY}
  DEVICE ${DEVICE}
  ARCH ql-s3
  PACKAGES wlcsp
  ROUTING_TIMING_FILE_NAME qlal4s3b_RoutingDelays_SSM40.csv
  TECHFILE_NAME QLAL4S3B.xml
  LIB_TIMING_FILES ${LIB_TIMING_FILES}
  DONT_NORMALIZE_FILES ${DONT_NORMALIZE_FILES}
  PB_TYPES
    GND VCC
    LOGIC
    CLOCK BIDIR SDIOMUX
    GMUX
    ASSP
    MULT
  RAM_TIMING_SDF RAM_ss_0p990v_m040c
  RAM_PBTYPE_COPY ram_a1.pb_type.xml
)
