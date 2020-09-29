add_file_target(FILE fdse.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdre.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdpe.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdce.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdse_or_fdre.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdpe_or_fdce.sim.v SCANNER_TYPE verilog)
add_file_target(FILE slice_ff_half.sim.v SCANNER_TYPE verilog)
add_file_target(FILE slice_ff.sim.v SCANNER_TYPE verilog)

v2x(
    NAME fdse
    SRCS fdse.sim.v
)

v2x(
    NAME fdre
    SRCS fdre.sim.v
)

v2x(
    NAME fdpe
    SRCS fdpe.sim.v
)

v2x(
    NAME fdce
    SRCS fdce.sim.v
)

v2x(
    NAME fdse_or_fdre
    SRCS fdse_or_fdre.sim.v
)

v2x(
    NAME fdpe_or_fdce
    SRCS fdpe_or_fdce.sim.v
)

v2x(
    NAME slice_ff_half
    SRCS slice_ff_half.sim.v
)

v2x(
    NAME slice_ff
    SRCS slice_ff.sim.v
    ENABLE_CANONICALIZE
)
