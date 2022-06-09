#!/usr/bin/env python3

from sys import argv
from pathlib import Path
from re import compile as re_compile

PACKAGE_RE = re_compile("symbiflow-arch-defs-([a-zA-Z0-9_-]+)-([a-z0-9])")

with (Path(__file__).parent.parent.parent / 'packages.list').open('r') as rptr:
    for artifact in rptr.read().splitlines():
        m = PACKAGE_RE.match(artifact)
        assert m, f"Package name not recognized! {artifact}"

        package_name = m.group(1)
        if package_name == "install":
            package_name == "toolchain"

        with (Path("install") /
              f"symbiflow-{package_name}-latest").open("w") as wptr:
            wptr.write(
                'https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/'
                f'foss-fpga-tools/symbiflow-arch-defs/continuous/install/{argv[1]}/{artifact}'
            )
