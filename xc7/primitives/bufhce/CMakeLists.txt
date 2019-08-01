add_file_target(FILE ntemplate.bufhceN.model.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.bufhceN.pb_type.xml SCANNER_TYPE xml)

n_template(
    NAME bufhceN.pb_type.xml
    PREFIXES 0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23
    SRCS ntemplate.bufhceN.pb_type.xml
    )
n_template(
    NAME bufhceN.model.xml
    PREFIXES 0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23
    SRCS ntemplate.bufhceN.model.xml
    )
