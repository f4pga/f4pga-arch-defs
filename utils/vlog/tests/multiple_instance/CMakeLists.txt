add_file_target(FILE multiple_instance.sim.v SCANNER_TYPE verilog)
v2x_test_both(NAME multiple_instance TOP_MODULE multiple_instance)
vpr_test_pbtype(NAME multiple_instance)
