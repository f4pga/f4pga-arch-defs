#!/usr/bin/env python3

db_full = """\
# Format: //devtools/kokoro/config/proto/build.proto

build_file: "symbiflow-arch-defs-%(kokoro_type)s-%(arch)s/.github/kokoro/%(arch)s.sh"

timeout_mins: 4320

action {
  define_artifacts {
    # File types
    regex: "**/*result*.xml"
    regex: "**/*sponge_log.xml"
    strip_prefix: "github/symbiflow-arch-defs-%(kokoro_type)s-%(arch)s/"
  }
}

env_vars {
  key: "KOKORO_TYPE"
  value: "%(kokoro_type)s"
}

env_vars {
  key: "KOKORO_DIR"
  value: "symbiflow-arch-defs-%(kokoro_type)s-%(arch)s"
}

env_vars {
  key: "SYMBIFLOW_ARCH"
  value: "%(arch)s"
}
"""

for type in ['tests', 'docs', 'ice40', 'testarch', 'xc7']:
    with open("continuous-%s.cfg" % type, "w") as f:
        f.write(db_full % {
            'arch': type,
            'kokoro_type': 'continuous',
        })

    with open("presubmit-%s.cfg" % type, "w") as f:
        f.write(db_full % {
            'arch': type,
            'kokoro_type': 'presubmit',
        })
