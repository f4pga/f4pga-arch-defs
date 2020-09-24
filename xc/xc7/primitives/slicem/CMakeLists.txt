add_subdirectory(Ndram)
add_subdirectory(srl)

add_file_target(FILE wemux.pb_type.xml SCANNER_TYPE xml)

add_file_target(FILE dram_2_output_stub.sim.v SCANNER_TYPE verilog)
add_file_target(FILE dram_4_output_stub.sim.v SCANNER_TYPE verilog)
add_file_target(FILE dram_8_output_stub.sim.v SCANNER_TYPE verilog)
add_file_target(FILE di64_stub.sim.v SCANNER_TYPE verilog)

v2x(
    NAME dram_2_output_stub
    SRCS dram_2_output_stub.sim.v
    )
v2x(
    NAME dram_4_output_stub
    SRCS dram_4_output_stub.sim.v
    )
v2x(
    NAME dram_8_output_stub
    SRCS dram_8_output_stub.sim.v
    )
v2x(
    NAME di64_stub
    SRCS di64_stub.sim.v
    )

add_file_target(FILE slicem.model.xml SCANNER_TYPE xml)
add_file_target(FILE slicem.pb_type.xml SCANNER_TYPE xml)

