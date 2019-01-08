add_file_target(FILE ntemplate.slicelN.model.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.slicelN.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE slicel.sim.v SCANNER_TYPE verilog)
add_verilog_image_gen(FILE slicel.sim.v)

n_template(
    NAME sliceN.pb_type.xml
    PREFIXES 0;1;2
    SRCS ntemplate.slicelN.pb_type.xml
    )
n_template(
    NAME sliceN.model.xml
    PREFIXES 0;1;2
    SRCS ntemplate.slicelN.model.xml
    )
