# How wide to allow formatted cmake files
line_width = 80

# How many spaces to tab for indent
tab_size = 2

# If arglists are longer than this, break them always
max_subargs_per_line = 3

# If true, separate flow control names from their parentheses with a space
separate_ctrl_name_with_space = False

# If true, separate function names from parentheses with a space
separate_fn_name_with_space = False

# If a statement is wrapped to more than one line, than dangle the closing
# parenthesis on it's own line
dangle_parens = True

# What character to use for bulleted lists
bullet_char = u'*'

# What character to use as punctuation after numerals in an enumerated list
enum_char = u'.'

# What style line endings to use in the output.
line_ending = u'unix'

# Format command names consistently as 'lower' or 'upper' case
command_case = u'lower'

# Format keywords consistently as 'lower' or 'upper' case
keyword_case = u'upper'

# Specify structure for custom cmake functions
additional_commands = {
    "add_file_target":
        {
            "flags": ["GENERATED", ],
            "kwargs": {
                "FILE": 1,
                "SCANNER_TYPE": "*",
            },
        },
    "v2x": {
        "kwargs": {
            "NAME": 1,
            "SRCS": "+",
            "TOP_MODULE": "*",
        },
    },  # noqa: E122
    "mux_gen":
        {
            "flags": [
                "SPLIT_INPUTS",
                "SPLIT_SELECTS",
            ],
            "kwargs":
                {
                    "NAME": 1,
                    "TYPE": 1,
                    "MUX_NAME": 1,
                    "WIDTH": 1,
                    "INPUTS": 1,
                    "SELECTS": 1,
                    "SUBCKT": 1,
                    "COMMENT": 1,
                    "OUTPUT": 1,
                    "DATA_WIDTH": 1,
                    "NTEMPLATE_PREFIXES": "*",
                },
        },
    "n_template":
        {
            "flags": ["APPLY_V2X", ],
            "kwargs": {
                "NAME": 1,
                "SRCS": "+",
                "PREFIXES": "+",
            },
        },
    "define_arch":
        {
            "kwargs":
                {
                    "ARCH": 1,
                    "YOSYS_SCRIPT": 1,
                    "BITSTREAM_EXTENSION": 1,
                    "RR_PATCH_TOOL": 1,
                    "RR_PATCH_CMD": 1,
                    "PLACE_TOOL": 1,
                    "PLACE_TOOL_CMD": 1,
                    "CELLS_SIM": 1,
                    "EQUIV_CHECK_SCRIPT": 1,
                    "HLC_TO_BIT": 1,
                    "HLC_TO_BIT_CMD": 1,
                }
        },
    "define_device_type":
        {
            "kwargs": {
                "DEVICE_TYPE": 1,
                "ARCH": 1,
                "ARCH_XML": 1,
            }
        },
    "define_device":
        {
            "kwargs":
                {
                    "DEVICE": 1,
                    "ARCH": 1,
                    "DEVICE_TYPE": 1,
                    "PACKAGES": "+",
                }
        },
    "define_board":
        {
            "kwargs":
                {
                    "BOARD": 1,
                    "DEVICE": 1,
                    "PACKAGE": 1,
                    "PROG_TOOL": 1,
                    "PROG_CMD": "*",
                }
        },
    "add_fpga_target":
        {
            "flags": [
                "EXPLICIT_ADD_FILE_TARGET",
                "EMIT_CHECK_TESTS",
            ],
            "kwargs":
                {
                    "NAME": 1,
                    "TOP": 1,
                    "BOARD": 1,
                    "SOURCES": "+",
                    "TESTBENCH_SOURCES": "*",
                    "INPUT_IO_FILE": "*",
                }
        }
}

# A list of command names which should always be wrapped
always_wrap = []
