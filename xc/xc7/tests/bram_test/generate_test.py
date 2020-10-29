import argparse
from collections import namedtuple

TEMPLATE = """`include "bram_test.v"

module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);

bram_test #(
    .ADDR_WIDTH({ADDR_WIDTH}),
    .DATA_WIDTH({DATA_WIDTH}),
    .ADDRESS_STEP({ADDRESS_STEP}),
    .MAX_ADDRESS({MAX_ADDRESS})
    ) bram_test (
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
    );

endmodule
"""

BramConfig = namedtuple('BramConfig', 'data_width addr_width depth')

BRAM_TYPE_WIDTH = {
        # UG473 Table 1-11
        (18, 1): BramConfig(1, 14, 16384),
        (18, 2): BramConfig(2, 13, 8192),
        (18, 4): BramConfig(4, 12, 4096),
        (18, 9): BramConfig(9, 11, 2048),
        (18, 18): BramConfig(18, 10, 1024),
        # UG473 Table 1-13
        (36, 1): BramConfig(1, 15, 32768),
        (36, 2): BramConfig(2, 14, 16384),
        (36, 4): BramConfig(4, 13, 8192),
        (36, 9): BramConfig(9, 12, 4096),
        (36, 18): BramConfig(18, 11, 2048),
        (36, 36): BramConfig(18, 10, 1024),
        }

def main():
    parser = argparse.ArgumentParser(description="")

    parser.add_argument('--type', type=int, required=True)
    parser.add_argument('--width', type=int, required=True)

    args = parser.parse_args()

    bram_config = BRAM_TYPE_WIDTH[args.type, args.width]

    print(TEMPLATE.format(
        ADDR_WIDTH=bram_config.addr_width,
        DATA_WIDTH=bram_config.data_width,
        ADDRESS_STEP=1,
        MAX_ADDRESS=bram_config.depth-1,
        ))

if __name__ == "__main__":
    main()
