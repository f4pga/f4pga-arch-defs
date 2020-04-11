"""
Generates a wrapper for initialized LUTn of the Quicklogic Tamar3 architecture.
The LUT initialization can be given explicitly or be randomized.

If the env. var. SEED is set (to a hex string) then the random generator
is initialized with its value.
"""
import argparse
import random
import os

# Seed the random generator
if "SEED" in os.environ:
    random.seed(int(os.getenv("SEED"), 16))

# =============================================================================


def generate_design(N, count=1, init=None):
    """
    Generates a design that uses LUTn
    """

    # INIT bit count
    bits = 2**N

    # Header
    verilog = """
module dut_lut(
  input  wire [{N1}:0] A,
  output wire [{M1}:0] O
);
""".format(
        N1=N - 1, M1=count - 1
    )

    # LUT(s)
    for i in range(count):

        # Randomize init
        if init is None:
            init_val = "".join([random.choice("01") for i in range(bits)])
            init_str = "{}'b{}".format(bits, init_val)
        # Explicit init
        else:
            init_str = "{}'b{}".format(bits, init)

        # Generate the LUT instance
        verilog += """
  LUT{N} # (.INIT({init})) lut_{i} (
""".format(N=N, i=i + 1, init=init_str)

        for j in range(N):
            verilog += "  .I{j}(A[{j}]),\n".format(j=j)

        verilog += """  .O(O[{}])
  );
""".format(i)

    # Footer
    verilog += """
endmodule"""

    return verilog


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "-n", type=int, required=True, help="LUT address width"
    )

    parser.add_argument(
        "--init",
        type=str,
        required=False,
        default=None,
        help="Explicit LUT initialization"
    )

    parser.add_argument(
        "--lut-count",
        type=int,
        required=False,
        default=1,
        help="LUT instance count"
    )

    args = parser.parse_args()

    # Generate the design
    print(generate_design(args.n, args.lut_count, args.init))


# =============================================================================

if __name__ == "__main__":
    main()
