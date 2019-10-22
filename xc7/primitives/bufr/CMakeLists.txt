add_file_target(FILE ntemplate.bufrN.model.xml SCANNER_TYPE xml)
add_file_target(FILE ntemplate.bufrN.pb_type.xml SCANNER_TYPE xml)

n_template(
    NAME bufrN.pb_type.xml
    PREFIXES 0;1;2;3
    SRCS ntemplate.bufrN.pb_type.xml
    )
n_template(
    NAME bufrN.model.xml
    PREFIXES 0;1;2;3
    SRCS ntemplate.bufrN.model.xml
    )
