set(VEXRISCV ${symbiflow-arch-defs_SOURCE_DIR}/third_party/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv.v)
add_file_target(FILE ${VEXRISCV} ABSOLUTE)

set(GENERATE_LITEX ${CMAKE_CURRENT_SOURCE_DIR}/generate.py)
set(FIXUP_XDC ${CMAKE_CURRENT_SOURCE_DIR}/fixup_xdc.py)

add_file_target(FILE ${GENERATE_LITEX})
add_file_target(FILE ${FIXUP_XDC})

add_subdirectory(mini)
add_subdirectory(mini_ddr)
add_subdirectory(base)
