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
import sys

# =============================================================================


class Templates:

    memory_case = """
module progmem
(
// Closk & reset
input  wire         clk,
input  wire         rstn,

// PicoRV32 bus interface
input  wire         valid,
output wire         ready,
input  wire [31:0]  addr,
output wire [31:0]  rdata
);

// ============================================================================

localparam  MEM_SIZE_BITS   = {mem_size}; // In 32-bit words
localparam  MEM_SIZE        = 1 << MEM_SIZE_BITS;
localparam  MEM_ADDR_MASK   = 32'h0010_0000;

// ============================================================================

wire [MEM_SIZE_BITS-1:0]    mem_addr;
reg  [31:0]                 mem_data;

always @(posedge clk)
    case (mem_addr)

{mem_data}

    default:    mem_data <= 32'hDEADBEEF;

    endcase

// ============================================================================

reg o_ready;

always @(posedge clk or negedge rstn)
    if (!rstn)  o_ready <= 1'd0;
    else        o_ready <= valid && ((addr & MEM_ADDR_MASK) != 0);

// Output connectins
assign ready    = o_ready;
assign rdata    = mem_data;
assign mem_addr = addr[MEM_SIZE_BITS+1:2];

endmodule
"""

    memory_initial = """
module progmem
(
// Closk & reset
input  wire         clk,
input  wire         rstn,

// PicoRV32 bus interface
input  wire         valid,
output wire         ready,
input  wire [31:0]  addr,
output wire [31:0]  rdata
);

// ============================================================================

localparam  MEM_SIZE_BITS   = {mem_size}; // In 32-bit words
localparam  MEM_SIZE        = 1 << MEM_SIZE_BITS;
localparam  MEM_ADDR_MASK   = 32'h0010_0000;

// ============================================================================

wire [MEM_SIZE_BITS-1:0]    mem_addr;
reg  [31:0]                 mem_data;
reg  [31:0]                 mem[0:MEM_SIZE];

initial begin
{mem_data}
end

always @(posedge clk)
    mem_data <= mem[mem_addr];

// ============================================================================

reg o_ready;

always @(posedge clk or negedge rstn)
    if (!rstn)  o_ready <= 1'd0;
    else        o_ready <= valid && ((addr & MEM_ADDR_MASK) != 0);

// Output connectins
assign ready    = o_ready;
assign rdata    = mem_data;
assign mem_addr = addr[MEM_SIZE_BITS+1:2];

endmodule
"""


# =============================================================================


def load_hex_file(file_name):
    """
    Loads a "HEX" file generated using the command:
    'objcopy -O verilog firmware.elf firmware.hex'
    """

    sys.stderr.write("Loading 'HEX' from: " + file_name + "\n")

    # Load and parse HEX data
    sections = {}
    section = 0  # If no '@' is specified the code will end up at addr. 0
    hex_data = []

    with open(file_name, "r") as fp:
        for line in fp.readlines():

            # Address, create new section
            if line.startswith("@"):
                section = int(line[1:], 16)
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
    sys.stderr.write("Sections:\n")
    for section in sections.keys():
        length = len(sections[section])
        sys.stderr.write(
            " @%08X - @%08X, %d bytes\n" % (section, section + length, length)
        )

    return sections


def modify_code_templte(sections, rom_style):
    """
    Modifies verilog ROM template by inserting case statements with the
    ROM content. Requires the sections dict to contain a section beginning
    at 0x00100000 address.

    Returns a string with the verilog code
    """

    # Get section at 0x00100000
    data = sections[0x00100000]

    # Pad to make length a multiply of 4
    if len(data) % 4:
        dummy_cnt = ((len(data) // 4) + 1) * 4 - len(data)
        data += bytes(dummy_cnt)

    # Determine memory size bits (in words)
    mem_size_bits = len(data).bit_length() - 2
    sys.stderr.write("ROM size (words): %d bits\n" % mem_size_bits)

    # Encode verilog case statements
    if rom_style == "case":

        # Generate statements
        case_statements = ""
        for i in range(len(data) // 4):

            # Little endian
            data_word = data[4 * i + 0]
            data_word |= data[4 * i + 1] << 8
            data_word |= data[4 * i + 2] << 16
            data_word |= data[4 * i + 3] << 24

            statement = "    'h%04X: mem_data <= 32'h%08X;\n" % (i, data_word)
            case_statements += statement

        # Return the code
        return Templates.memory_case.format(
            mem_size=mem_size_bits, mem_data=case_statements
        )

    # Encode data as initial statements for a verilog array
    if rom_style == "initial":

        # Generate statements
        initial_statements = ""
        for i in range(len(data) // 4):

            # Little endian
            data_word = data[4 * i + 0]
            data_word |= data[4 * i + 1] << 8
            data_word |= data[4 * i + 2] << 16
            data_word |= data[4 * i + 3] << 24

            statement = "    mem['h%04X] <= 32'h%08X;\n" % (i, data_word)
            initial_statements += statement

        # Return the code
        return Templates.memory_initial.format(
            mem_size=mem_size_bits, mem_data=initial_statements
        )

    # Error
    sys.stdout.write("Invalid ROM style '%s'\n" % rom_style)
    return ""


# =============================================================================


def main():

    # Argument parser
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hex", type=str, help="Input HEX file")
    parser.add_argument(
        "--rom-style", type=str, default="case", help="ROM style"
    )

    args = parser.parse_args()

    # Load HEX
    sections = load_hex_file(args.hex)

    # Generate verilog code
    code = modify_code_templte(sections, args.rom_style)

    # Output verilog code
    sys.stdout.write(code)
    sys.stdout.flush()


# =============================================================================

if __name__ == "__main__":
    main()
