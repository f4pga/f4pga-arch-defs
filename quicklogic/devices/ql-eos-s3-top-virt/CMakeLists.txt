quicklogic_define_device_type(
  DEVICE ql-eos-s3-top
  ARCH ql-s3
  PACKAGES wlcsp
  TECHFILE_NAME QLAL4S3B.xml
  GRID_LIMIT 0,0,33,2
  ROUTING_TIMING_FILE_NAME qlal4s3b_RoutingDelays_SSM40.csv
  PB_TYPES
    GND VCC
    LOGIC
    BIDIR
)
