set(VEXRISCV ${symbiflow-arch-defs_SOURCE_DIR}/third_party/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv.v)
add_file_target(FILE ${VEXRISCV} ABSOLUTE)
set(VEXRISCV_LINUX ${symbiflow-arch-defs_SOURCE_DIR}/third_party/pythondata-cpu-vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv_Linux.v)
add_file_target(FILE ${VEXRISCV_LINUX} ABSOLUTE)

set(GENERATE_LITEX ${CMAKE_CURRENT_SOURCE_DIR}/generate.py)
set(GENERATE_LINUX_LITEX ${CMAKE_CURRENT_SOURCE_DIR}/generate_linux.py)
set(FIXUP_XDC ${CMAKE_CURRENT_SOURCE_DIR}/fixup_xdc.py)

add_file_target(FILE generate.py)
add_file_target(FILE generate_linux.py)
add_file_target(FILE fixup_xdc.py)

add_subdirectory(mini)
add_subdirectory(mini_ddr)
add_subdirectory(mini_ddr_eth)
add_subdirectory(linux)
add_subdirectory(partial_reconfiguration)
