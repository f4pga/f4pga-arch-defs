#!/usr/bin/env python3
"""
This script generates a verilog module which implements ROM memory. Content
of the memory is also generated. Different styles of ROM implementation are
available.
"""
import sys
import argparse
import math
import random

# =============================================================================


class Templates:

    # =============================================================================

    memory_inferred_bram = """
module rom #
(
parameter  ROM_SIZE_BITS = {mem_size} // Size in 32-bit words
)
(
// Closk & reset
input  wire CLK,
input  wire RST,

// ROM interface
input  wire                     I_STB,
input  wire [ROM_SIZE_BITS-1:0] I_ADR,

output wire         O_STB,
output wire [31:0]  O_DAT
);

// ============================================================================
localparam ROM_SIZE = (1<<ROM_SIZE_BITS);

reg [31:0] rom [0:ROM_SIZE-1];

reg        rom_stb;
reg [31:0] rom_dat;

always @(posedge CLK)
    rom_dat <= rom[I_ADR];

always @(posedge CLK or posedge RST)
    if (RST) rom_stb <= 1'd0;
    else     rom_stb <= I_STB;

assign O_STB = rom_stb;
assign O_DAT = rom_dat;

// ============================================================================

initial begin
{mem_data}
end

// ============================================================================

endmodule
"""

    # =============================================================================

    memory_explicit_dram64 = """
module rom #
(
parameter  ROM_SIZE_BITS = {mem_size} // Size in 32-bit words
)
(
// Closk & reset
input  wire CLK,
input  wire RST,

// ROM interface
input  wire                     I_STB,
input  wire [ROM_SIZE_BITS-1:0] I_ADR,

output wire         O_STB,
output wire [31:0]  O_DAT
);

// ============================================================================
// DRAM aggregation logic
{dram_agg_code}
assign O_STB = rom_stb;
assign O_DAT = dram_data_0; // FIXME: Hard coded !

// ============================================================================
// DRAMs
{dram_code}
endmodule
"""

    # =============================================================================

    dram_row_reg = """
wire [{cols_minus_one}:0] {data_w};
reg  [{cols_minus_one}:0] {data_r};
wire [{mem_size_bits_minus_one}:0] {addr};

always @(posedge CLK)
    {data_r} <= {data_w};

assign {addr} = I_ADR; // FIXME: Hard coded !
"""

    ram64x1d = """
RAM64X1D #
(
.INIT   ({init})
)
dram_{row}_{col}
(
.WCLK   (1'b0),
.WE     (1'b0), .D(1'b0),
.DPRA0  (1'b0), .DPRA1(1'b0), .DPRA2(1'b0),
.DPRA3  (1'b0), .DPRA4(1'b0), .DPRA5(1'b0),

.A0     ({addr}[0]), .A1 ({addr}[1]), .A2 ({addr}[2]),
.A3     ({addr}[3]), .A4 ({addr}[4]), .A5 ({addr}[5]),

.SPO    ({data})
);
"""


# =============================================================================


def generate_inferred_bram(rom_data):

    # Log2 memory size
    mem_size_bits = int(math.ceil(math.log2(len(rom_data))))

    # Case statements
    case_statements = ""
    for i, data_word in enumerate(rom_data):
        case_statements += "    rom['h%04X] <= 32'h%08X;\n" % (i, data_word)

    return Templates.memory_inferred_bram.format(
        mem_size=mem_size_bits, mem_data=case_statements
    )


def generate_explicit_dram(rom_data, dram_size_bits=6):

    # Log2 memory size
    mem_size_bits = int(math.ceil(math.log2(len(rom_data))))
    # DRAM size
    dram_size = int(math.pow(2, dram_size_bits))

    # Memory width is fixed to 32-bits. It is the number of lets say "horizontal"
    # DRAMS that need to be used
    mem_width = 32

    # Memory height is the number of DRAMs required to store 1 bit of the
    # whole data set. It has to be an integer multiply of the DRAM size.
    mem_height = int(math.ceil(len(rom_data) / dram_size))

    # FIXME: Only one row works -> 64 words. Need more time to code hierarchical
    # muxes to join them.
    assert (mem_height == 1)

    sys.stderr.write("dram_size  = %d\n" % dram_size)
    sys.stderr.write("mem_height = %d\n" % mem_height)

    # Generate "rows" of DRAMs
    dram_code = ""
    wire_code = ""
    for row in range(mem_height):

        # Row aggregation
        wire_code += Templates.dram_row_reg.format(
            cols_minus_one=mem_width - 1,
            mem_size_bits_minus_one=dram_size_bits - 1,
            data_r="dram_data_%d" % (row),
            data_w="dram_data_%d_w" % (row),
            addr="dram_addr_%d" % (row)
        )

        # Cut data range
        i0 = row * dram_size
        i1 = min(len(rom_data), i0 + dram_size)
        sz = i1 - i0

        data_chunk = [0] * dram_size
        data_chunk[:sz] = rom_data[i0:i1]

        # Generate "row" of DRAMS
        for col in range(mem_width):
            bit = col

            init_data = [
                bool(data_chunk[i] & (1 << bit)) for i in range(dram_size)
            ]
            init_str = "".join(["%c" % "1" if b else "0" for b in init_data])
            init_str = "%d'b" % dram_size + init_str[::-1]

            code = Templates.ram64x1d.format(
                init=init_str,
                col=col,
                row=row,
                addr="dram_addr_%d" % (row),
                data="dram_data_%d_w[%d]" % (row, col)
            )

            dram_code += code

    # Add final wire bindings
    wire_code += """
assign rom_dat = dram_data_0; // FIXME: Hard coded !

reg rom_stb;

always @(posedge CLK or posedge RST)
    if (RST) rom_stb <= 1'd0;
    else     rom_stb <= I_STB;

"""

    return Templates.memory_explicit_dram64.format(
        mem_size=mem_size_bits,
        dram_agg_code=wire_code,
        dram_code=dram_code,
    )


# =============================================================================


def generate_rom_data(word_count):
    """
    Generates a list of 32-bit words that are to be put into ROM memory
    """

    rom_data = []
    random.seed(123456, version=2)  # A fixed seed

    for i in range(word_count):

        #        # Simple sequence of monotonically increasing numbers
        #        v0 = 2*i
        #        v1 = 2*i+1

        # Pseudo-random numbers
        v0 = int(random.random() * 65536.0)
        v1 = int(random.random() * 65536.0)

        # Pack as big endian
        data_word = v0 << 16
        data_word |= v1

        rom_data.append(data_word)

    return rom_data


# =============================================================================


def main():

    # Argument parser
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rom-style",
        type=str,
        default="bram",
        help="ROM style (\"bram\",\"dram64\")"
    )

    args = parser.parse_args()

    # Generate BRAM
    if args.rom_style == "bram":
        rom_data = generate_rom_data(512)
        print(generate_inferred_bram(rom_data))
    # Generate DRAM64
    elif args.rom_style == "dram64":
        rom_data = generate_rom_data(64)
        print(generate_explicit_dram(rom_data))
    # Error
    else:
        sys.stderr.write("Invalid ROM style '%s'" % args.rom_style)
        exit(-1)


# =============================================================================

if __name__ == "__main__":
    main()
