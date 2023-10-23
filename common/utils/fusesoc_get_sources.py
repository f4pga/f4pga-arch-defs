#!/usr/bin/env python3

import os
import argparse

from yaml import load, Loader

SOURCE_FILE_TYPES = [
    "verilogSource",
    "systemVerilogSource",
]


def get_sources(eda_yml):
    eda_yml_path = os.path.realpath(eda_yml)
    current_dir = os.path.dirname(eda_yml_path)

    with open(eda_yml_path) as f:
        data = load(f, Loader=Loader)
        files = data["files"]

    for src in files:
        if "file_type" not in src.keys():
            continue

        if src["file_type"] in SOURCE_FILE_TYPES:
            file_path = os.path.realpath(
                os.path.join(current_dir, src["name"])
            )
            basename = os.path.basename(file_path)
            print(basename)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Get sources from an EDA YAML file produced by fusesoc"
    )
    parser.add_argument("eda_yml", help="An EDA YAML produced by fusesoc")

    args = parser.parse_args()
    get_sources(args.eda_yml)
