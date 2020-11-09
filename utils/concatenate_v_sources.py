#!/usr/bin/env python3
'''
Concatenate Verilog source files and process include directives inside them.

Usage: concatenate_v_sources.py [-h] inputfile [inputfile ...] outputfile
'''

import argparse
import sys
import re
from os import path

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile",
    nargs='+',
    type=argparse.FileType('r'),
    help="Input Verilog file"
)
parser.add_argument(
    "outputfile", type=argparse.FileType('w'), help="Output file"
)

include_re = re.compile(r'^`include *"([^"]+)"', flags=re.MULTILINE)
slash_star_re = re.compile(r'\s*/\*.*\*/\s*', flags=re.DOTALL)
slash_slash_re = re.compile(r'\s*//[^\n]*')
v2x_re = re.compile('.*\(\*.*((DELAY)|(CLOCK)|(MODEL)|(SETUP)|(HOLD)|(FASM)).*\*\)\n')


def process_includes(file, includes_list):
    file_name = path.realpath(file.name)
    if file_name in includes_list:
        return ''

    includes_list.append(file_name)

    code = file.read()
    code = slash_star_re.sub('', code)
    code = slash_slash_re.sub('', code)
    code = v2x_re.sub('', code)


    def process_match(match):
        include_path = path.join(path.dirname(file_name), match[1])
        include_file = open(include_path, 'r')
        return process_includes(include_file, includes_list)

    rel_file_name = path.relpath(file_name)

    result = \
            f'// {rel_file_name} {{{{{{\n' + \
            include_re.sub(process_match, code) + \
            f'// {rel_file_name} }}}}}}\n'
    return result


def main(argv):
    args = parser.parse_args(argv[1:])
    print(args)

    includes_list = []

    print(*(process_includes(f, includes_list) for f in args.inputfile), \
            sep='\n', end='', file=args.outputfile)

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
