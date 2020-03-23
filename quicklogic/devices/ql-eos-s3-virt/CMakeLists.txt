quicklogic_define_device_type(
  DEVICE ql-eos-s3
  ARCH ql-s3
  PACKAGES wlcsp
  ROUTING_TIMING_FILE_NAME qlal4s3b_RoutingDelays_SSM40.csv
  TECHFILE_NAME QLAL4S3B.xml
  PB_TYPES
    GND VCC
    LOGIC
    BIDIR
    ASSP
)
