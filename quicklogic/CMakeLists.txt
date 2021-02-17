# VPR architecture args for AP3 with OpenFPGA
set(VPR_AP3_OPENFPGA_ARCH_ARGS "\
    ${VPR_AP3_COMMON_ARCH_ARGS} \
    --clock_modeling ideal "
)

# Architectures using OpenFPGA VPR architecture directly
add_subdirectory(openfpga)
