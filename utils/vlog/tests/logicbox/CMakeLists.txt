add_file_target(FILE logicbox.sim.v SCANNER_TYPE verilog)
v2x(NAME logicbox SRCS logicbox.sim.v TOP_MODULE LOGICBOX)
v2x_test_generic(NAME logicbox TYPE pb_type)
v2x_test_generic(NAME logicbox TYPE model)
