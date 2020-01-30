add_subdirectory(s3-test-virt)
add_subdirectory(s3-top-routing-virt)

define_device(
  DEVICE ql-eos-s3-test
  ARCH ql-s3
  DEVICE_TYPE ql-s3-test-virt
  PACKAGES wlcsp
  WIRE_EBLIF ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/dummy.eblif
  CACHE_PLACE_DELAY
  CACHE_ARGS
    --route_chan_width 100
    --clock_modeling route
    --allow_unrelated_clustering off
    --target_ext_pin_util 0.7
    --router_init_wirelength_abort_threshold 2
    --congested_routing_iteration_threshold 0.8
)

