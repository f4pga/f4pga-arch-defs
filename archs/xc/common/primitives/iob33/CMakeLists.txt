add_file_target(FILE inpad.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE outpad.pb_type.xml SCANNER_TYPE xml)

add_subdirectory("modes")

add_file_target(FILE iob33.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE iob33.model.xml SCANNER_TYPE xml)
