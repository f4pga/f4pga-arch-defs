add_file_target(FILE slicel.model.xml SCANNER_TYPE xml)
add_file_target(FILE slicel.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE slicel.sim.v SCANNER_TYPE verilog)
add_verilog_image_gen(FILE slicel.sim.v)

get_file_target(SLICEL_TARGET slicel.pb_type.xml)
get_target_property_required(INCLUDE_FILES ${SLICEL_TARGET} INCLUDE_FILES)
message(STATUS "${SLICEL_INCLUDES}")
