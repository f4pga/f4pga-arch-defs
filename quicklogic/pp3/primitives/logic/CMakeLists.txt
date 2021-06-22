add_file_target(FILE t_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE b_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE c_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE q_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE f_frag.sim.v SCANNER_TYPE verilog)

add_file_target(FILE t_frag.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE t_frag.model.xml SCANNER_TYPE xml)

add_file_target(FILE b_frag.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE b_frag.model.xml SCANNER_TYPE xml)

add_file_target(FILE c_frag.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE c_frag.model.xml SCANNER_TYPE xml)
add_file_target(FILE c_frag_modes.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE c_frag_modes.model.xml SCANNER_TYPE xml)

add_file_target(FILE q_frag.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE q_frag.model.xml SCANNER_TYPE xml)
add_file_target(FILE q_frag_modes.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE q_frag_modes.model.xml SCANNER_TYPE xml)

add_file_target(FILE f_frag.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE f_frag.model.xml SCANNER_TYPE xml)

add_file_target(FILE logic_macro.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE logic_macro.model.xml SCANNER_TYPE xml)
add_file_target(FILE logic.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE logic.model.xml SCANNER_TYPE xml)

add_to_cells_sim(t_frag.sim.v)
add_to_cells_sim(b_frag.sim.v)
add_to_cells_sim(q_frag.sim.v)
add_to_cells_sim(f_frag.sim.v)
add_to_cells_sim(c_frag.sim.v)
