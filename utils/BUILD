package(
    default_visibility = ["//visibility:public"],
    )

py_binary(
    name = 'n',
    srcs = ['n.py'],
    default_python_version = "PY3",
    deps = ['//utils/lib:asserts'],
    )

py_binary(
    name = 'mux_gen',
    srcs = ['mux_gen.py'],
    default_python_version = "PY3",
    deps = [
        '//utils/lib:asserts',
        '//utils/lib:argparse_extra',
        '//utils/lib:mux',
        ],
    )
