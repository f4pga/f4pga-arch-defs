add_file_target(FILE ntemplate.bufgctrlN.model.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.bufgctrlN.pb_type.xml SCANNER_TYPE xml)

n_template(
    NAME bufgctrlN.pb_type.xml
    PREFIXES 0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15
    SRCS ntemplate.bufgctrlN.pb_type.xml
    )
n_template(
    NAME bufgctrlN.model.xml
    PREFIXES 0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15
    SRCS ntemplate.bufgctrlN.model.xml
    )
