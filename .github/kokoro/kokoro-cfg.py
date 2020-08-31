#!/usr/bin/env python3
"""
Generates kokoro config files based on template.
"""

db_full = """\
# Format: //devtools/kokoro/config/proto/build.proto

# Generated from .github/kokoro/kokoro-cfg.py
# To regenerate run:
# cd .github/kokoro/ && python3 kokoro-cfg.py

build_file: "symbiflow-arch-defs-%(kokoro_type)s-%(arch)s/.github/kokoro/%(arch)s.sh"

timeout_mins: 4320

action {
  define_artifacts {
    # File types
    regex: "**/*result*.xml"
    regex: "**/*sponge_log.xml"
    regex: "**/.ninja_log"
    regex: "**/pack.log"
    regex: "**/place.log"
    regex: "**/route.log"
    regex: "**/*_sv2v.v.log"
    regex: "**/*_qor.csv"
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

for type in ['tests', 'docs', 'ice40', 'testarch', 'xc7', 'xc7-vendor',
             'xc7a200t', 'xc7a200t-vendor', 'install']:
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
