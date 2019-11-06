`include "plle2_test.v"

`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire [11:0] in,
output wire [11:0] out,

input  wire jc1,
output wire jc2
);

// ============================================================================
// Clock & reset
wire CLK;
BUFG bufgctrl(.I(clk), .O(CLK));

reg [3:0] rst_sr;
initial rst_sr <= 4'hF;

always @(posedge CLK)
    if (in[0])
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

// ============================================================================
// The tester

plle2_test #
(
.FEEDBACK   ("EXTERNAL")
)
plle2_test
(
.CLK        (CLK),
.RST        (RST),

.CLKFBOUT   (jc2),
.CLKFBIN    (jc1),

.I_PWRDWN   (in[1]),
.I_CLKINSEL (in[2]),

.O_LOCKED   (out[6]),
.O_CNT      (out[5:0])
);

assign out [10:7] = 1'd0;

endmodule

