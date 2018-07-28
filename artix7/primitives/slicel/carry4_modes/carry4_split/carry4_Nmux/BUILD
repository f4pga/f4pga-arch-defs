load('//make:build_defs.bzl', 'mux_gen')

mux_gen(
    name = 'ntemplate.carry4_Nmux',
    type = 'logic',
    mux_name = 'CARRY4_{N}MUX',
    width = 2,
    split_inputs = True,
    inputs = ['CI', 'DI'],
    subckt = 'MUXCY',
    ntemplate_prefixes = ['a', 'b', 'c', 'd'],
    visibility = ["//artix7/primitives/slicel/carry4_modes/carry4_split:__pkg__"],
    )
