#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2020  The Symbiflow Authors.
#
# Use of this source code is governed by a ISC-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/ISC
#
# SPDX-License-Identifier: ISC
"""Generates sources for the Ibex example and copies them to the example build directory"""
import argparse
import tempfile
import os.path
import subprocess
import shutil
import sys


def patch_ibex(current_dir, ibex_tmp_dir, f_log):
    """ Patch ibex sources. """

    # TODO: Remove the need for ibex.patch
    with open(os.path.join(current_dir, 'ibex.patch')) as f_patch:
        subprocess.check_call(
            "patch -p1",
            stdin=f_patch,
            stdout=f_log,
            stderr=f_log,
            shell=True,
            cwd=ibex_tmp_dir
        )


def run_fusesoc(ibex_tmp_dir, soc, part, f_log):
    """ Invoke fusesoc to generate sources. """

    subprocess.check_call(
        (
            'python3 -mfusesoc.main --cores-root={ibex_tmp_dir} run ' +
            '--target=synth --setup {soc} --part {part}'
        ).format(ibex_tmp_dir=ibex_tmp_dir, soc=soc, part=part),
        stdout=f_log,
        stderr=f_log,
        shell=True,
        cwd=ibex_tmp_dir
    )


def get_fusesoc_sources(root_dir, eda_yaml_path, f_log):
    """ Get list of sources in fusesoc output. """

    if not os.path.exists(eda_yaml_path):
        print('ERROR: Wrong path to EDA YAML file!', file=f_log)
        print(
            'Check if the main lowrisc_ibex_top_artya7_x version is still valid!',
            file=f_log
        )
        sys.exit(1)

    get_sources_invocation = 'python3 "{get_source_path}" "{eda_yaml_path}"'.format(
        get_source_path=os.path.join(
            root_dir, 'utils', 'fusesoc_get_sources.py'
        ),
        eda_yaml_path=eda_yaml_path
    )

    return set(
        s.decode() for s in
        subprocess.check_output(get_sources_invocation, shell=True).split()
    )


def copy_fusesoc_sources_to_build_dir(
        ibex_tmp_dir, fusesoc_sources, ibex_test_build_dir, f_log
):
    """ Copy fusesoc sources from ibex_tmp_dir to the build dir. """

    for root, _, files in os.walk(os.path.join(ibex_tmp_dir, 'build')):
        for f in files:
            if f in fusesoc_sources:
                shutil.copy(os.path.join(root, f), ibex_test_build_dir)
                print("Copying {} ... ".format(f), file=f_log)


def print_log_file(log_file, file=sys.stdout):
    with open(log_file) as f_log:
        for line in f_log:
            print(line.strip(), file=file)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only-deps', action='store_true')
    parser.add_argument('--root_source_dir', required=True)
    parser.add_argument('--current_binary_dir', required=True)

    args = parser.parse_args()

    current_dir = os.path.dirname(__file__)
    root_dir = args.root_source_dir
    ibex_dir = os.path.join(args.root_source_dir, 'third_party', 'ibex')
    ibex_test_build_dir = args.current_binary_dir
    log_file = os.path.join(ibex_test_build_dir, 'generate.log')

    try:
        with tempfile.TemporaryDirectory() as tmp_dir, open(log_file,
                                                            'w') as f_log:
            ibex_tmp_dir = os.path.join(tmp_dir, 'ibex')

            shutil.copytree(ibex_dir, ibex_tmp_dir)
            patch_ibex(current_dir, ibex_tmp_dir, f_log)

            soc = 'lowrisc:ibex:top_artya7'
            part = 'xc7a35ticsg324-1L'
            run_fusesoc(ibex_tmp_dir, soc, part, f_log)

            eda_yaml_path = os.path.join(
                ibex_tmp_dir, 'build', 'lowrisc_ibex_top_artya7_0.1',
                'synth-vivado', 'lowrisc_ibex_top_artya7_0.1.eda.yml'
            )
            fusesoc_sources = get_fusesoc_sources(
                root_dir, eda_yaml_path, f_log
            )

            if args.only_deps:
                for source in fusesoc_sources:
                    print(source)
            else:
                copy_fusesoc_sources_to_build_dir(
                    ibex_tmp_dir, fusesoc_sources, ibex_test_build_dir, f_log
                )

        if not args.only_deps:
            print_log_file(log_file)
    except Exception:
        print_log_file(log_file, file=sys.stderr)
        raise


if __name__ == "__main__":
    main()
