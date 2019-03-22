#!/usr/bin/env python3
"""
An utility script that allows to convert text file to BRAM content.
For testing purposes
"""

import argparse

# =============================================================================

def main():

    statements = []
    for i in range(512):
        v0 = 2*i
        v1 = 2*i+1
        
        # Big endian
        data_word  = v0 << 16
        data_word |= v1

        statements.append("    rom['h%04X] <= 32'h%08X;" % (i, data_word))

    # Dump
    for statement in statements:
        print(statement)

#    # Argument parser
#    parser = argparse.ArgumentParser(description=__doc__)
#    parser.add_argument("text", type=str, help="Input text file")
#    parser.add_argument("--rom-size", type=int, default=512, help="ROM cell count")
#    parser.add_argument("--rom-bits", type=int, default=32,  help="ROM word size (32, 16 or 8)")

#    args = parser.parse_args()

#    rom_bytes = args.rom_size * args.rom_bits // 8;

#    # Load text
#    with open(args.text, "r") as fp:
#        text = fp.read()

#    # Limit text size, append newline
#    text = text[:rom_bytes-2] + "\r\n"
#    data = text.encode("ascii")

#    # Generate statements
#    statements = []

#    if args.rom_bits == 32:

#        for i in range(len(text) // 4):

#            # Little endian
#            data_word  = data[4*i+0]
#            data_word |= data[4*i+1] << 8
#            data_word |= data[4*i+2] << 16
#            data_word |= data[4*i+3] << 24

#            statements.append("    rom['h%04X] <= 32'h%08X;" % (i, data_word))

#    if args.rom_bits == 16:

#        for i in range(len(text) // 2):

#            # Little endian
#            data_word  = data[2*i+0]
#            data_word |= data[2*i+1] << 8

#            statements.append("    rom['h%04X] <= 16'h%04X;" % (i, data_word))

#    if args.rom_bits == 8:

#        for i in range(len(text)):
#            statements.append("    rom['h%04X] <= 8'h%02X;"  % (i, text[i]))

#    # Dump
#    for statement in statements:
#        print(statement)

# =============================================================================


if __name__ == "__main__":
    main()

