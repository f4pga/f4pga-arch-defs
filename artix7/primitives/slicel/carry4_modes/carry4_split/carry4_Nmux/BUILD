load('//make:build_defs.bzl', 'n_template', 'mux_gen')

mux_gen(
    name = 'ntemplate.carry4_Nmux',
    type = 'logic',
    mux_name = 'CARRY4_{N}MUX',
    width = 2,
    split_inputs = True,
    inputs = ['CI', 'DI'],
    subckt = 'MUXCY',
    )

n_template(
    name = 'carry4_Nmux.sim.v',
    prefixes = ['a', 'b', 'c', 'd'],
    srcs = [
        'ntemplate.carry4_Nmux.sim.v'
    ],
    )

n_template(
    name = 'carry4_Nmux.model',
    prefixes = ['a', 'b', 'c', 'd'],
    srcs = [
        'ntemplate.carry4_Nmux.model.xml'
    ],
    )

n_template(
    name = 'carry4_Nmux.pb_type',
    prefixes = ['a', 'b', 'c', 'd'],
    srcs = [
        'ntemplate.carry4_Nmux.pb_type.xml'
    ],
    )
