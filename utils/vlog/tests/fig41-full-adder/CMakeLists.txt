add_file_target(FILE adder.sim.v SCANNER_TYPE verilog)
v2x(NAME adder TOP_MODULE adder SRCS adder.sim.v)

add_file_target(FILE golden.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE golden.model.xml SCANNER_TYPE xml)

xml_sort(NAME pb_type_golden_sort FILE golden.pb_type.xml SORT_OUTPUT adder.pb_type.golden.xml)
xml_sort(NAME pb_type_actual_sort FILE adder.pb_type.xml  SORT_OUTPUT adder.pb_type.actual.xml)
