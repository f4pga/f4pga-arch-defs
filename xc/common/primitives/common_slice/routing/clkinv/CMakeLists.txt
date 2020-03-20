add_file_target(FILE clkinv.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE clkinv.sim.v SCANNER_TYPE verilog)
add_verilog_image_gen(FILE clkinv.sim.v)
