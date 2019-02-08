#!/usr/bin/env python3
"""
This script allows to convert HEX file with firmware to a verilog ROM
implementation. The HEX file must be generated using the following command:

 "objcopy -O verilog <input ELF> <output HEX>".

The script generates a series of verilog case statements. Those statements are
then injected to a template file and as a result a new verilog file is written.

The verilog template file name is hard coded as "progmem.v.template". The
output file with the ROM is named "progmem.v".

Important! The script assumes that the firmware is placed at 0x00100000 address 
and will convert to verilog content beginning at that address only !

"""
import argparse

# =============================================================================


def load_hex_file(file_name):
    """
    Loads a "HEX" file generated using the command:
    'objcopy -O verilog firmware.elf firmware.hex'
    """

    print("Loading 'HEX' from: " + file_name)

    # Load and parse HEX data
    sections = {}
    section  = 0    # If no '@' is specified the code will end up at addr. 0
    hex_data = []

    with open(file_name, "r") as fp:
        for line in fp.readlines():

            # Address, create new section
            if line.startswith("@"):
                section  = int(line[1:], 16)
                hex_data = []
                sections[section] = hex_data
                continue

            # Data, append to current section
            else:
                hex_data += line.split()

    # Convert section data to bytes
    for section in sections.keys():
        sections[section] = bytes([int(s, 16) for s in sections[section]])

    # Dump sections
    print("Sections:")
    for section in sections.keys():
        length = len(sections[section])
        print(" @%08X - @%08X, %d bytes" % (section, section+length, length))

    return sections


def modify_code_templte(file_name, sections):
    """
    Modifies verilog ROM template by inserting case statements with the
    ROM content. Requires the sections dict to contain a section beginning
    at 0x00100000 address.
    """

    # Get section at 0x00100000
    data = sections[0x00100000]

    # Pad to make length a multiply of 4
    if len(data) % 4:
        dummy_cnt = ((len(data) // 4) + 1) * 4 - len(data)
        data += bytes(dummy_cnt)

    # Determine memory size bits (in words)
    mem_size_bits = len(data).bit_length() - 2
    print("ROM size (words): %d bits" % mem_size_bits)

    # Encode verilog case statements
    case_statements = []
    for i in range(len(data) // 4):

        # Little endian
        data_word  = data[4*i+0]
        data_word |= data[4*i+1] << 8
        data_word |= data[4*i+2] << 16
        data_word |= data[4*i+3] << 24

        statement = "    'h%04X: mem_data <= 32'h%08X;\n" % (i, data_word)
        case_statements.append(statement)

    # Load the template
    with open(file_name + ".template", "r") as fp:
        code = fp.readlines()

    # Change memory size
    for i in range(len(code)):
        fields = code[i].split()
        if len(fields) >= 4 and fields[0] == "localparam" and fields[1] == "MEM_SIZE_BITS":
            code[i] = "localparam  MEM_SIZE_BITS   = %d; // In 32-bit words\n" % mem_size_bits

    # Inject case statements
    for i in range(len(code)):
        if "case (mem_addr)" in code[i]:
            code = code[:i+1] + ["\n"] + case_statements + code[i+1:]
            break

    # Write modified code to a new file
    print("Writing verilog code to: " + file_name)
    with open(file_name, "w") as fp:
        fp.writelines(code)

# =============================================================================

def main():

    # Argument parser
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hex", type=str, help="Input HEX file")

    args = parser.parse_args()

    # Load HEX
    sections = load_hex_file(args.hex)

    # Modify the verilog code
    modify_code_templte("progmem.v", sections)

# =============================================================================

if __name__ == "__main__":
    main()

