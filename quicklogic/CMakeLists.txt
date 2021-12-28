add_subdirectory(common)

add_quicklogic_plugins()

set(QLF_FPGA_DATABASE_DIR quicklogic/third_party/qlfpga-symbiflow-plugins)
set(QLF_FPGA_PLUGINS_DIR quicklogic/third_party/qlfpga-symbiflow-plugins)

add_subdirectory(qlf_k4n8)
add_subdirectory(pp3)
