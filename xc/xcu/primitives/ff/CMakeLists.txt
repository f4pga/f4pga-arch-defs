# Primitives
add_file_target(FILE fdse.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdre.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdpe.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdce.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ce_vcc.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ce_used.sim.v SCANNER_TYPE verilog)
add_file_target(FILE sr_gnd.sim.v SCANNER_TYPE verilog)
add_file_target(FILE sr_used.sim.v SCANNER_TYPE verilog)

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
    NAME ce_vcc
    SRCS ce_vcc.sim.v
)

v2x(
    NAME ce_used
    SRCS ce_used.sim.v
)

v2x(
    NAME sr_gnd
    SRCS sr_gnd.sim.v
)

v2x(
    NAME sr_used
    SRCS sr_used.sim.v
)

# Intermediate
add_file_target(FILE fdse_or_fdre.sim.v SCANNER_TYPE verilog)
add_file_target(FILE fdpe_or_fdce.sim.v SCANNER_TYPE verilog)
add_file_target(FILE ceusedmux.sim.v SCANNER_TYPE verilog)
add_file_target(FILE srusedmux.sim.v SCANNER_TYPE verilog)
add_file_target(FILE slice_ff_bot.sim.v SCANNER_TYPE verilog)
add_file_target(FILE slice_ff_top.sim.v SCANNER_TYPE verilog)

v2x(
    NAME ceusedmux
    SRCS ceusedmux.sim.v
)

v2x(
    NAME srusedmux
    SRCS srusedmux.sim.v
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
    NAME slice_ff_bot
    SRCS slice_ff_bot.sim.v
)

v2x(
    NAME slice_ff_top
    SRCS slice_ff_top.sim.v
)

# Top level ff
add_file_target(FILE slice_ff.sim.v SCANNER_TYPE verilog)

v2x(
    NAME slice_ff
    SRCS slice_ff.sim.v
    ENABLE_CANONICALIZE
)
