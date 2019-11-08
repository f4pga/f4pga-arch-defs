`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire sw,
output wire [1:0] led,

input  wire in,
output wire out
);

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

wire CLK;

BUFG bufg(.I(clk), .O(CLK));

always @(posedge CLK)
    if (sw)
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

// ============================================================================
// Test uints
wire error;

localparam DATA_WIDTH = `DATA_WIDTH_DEFINE;
localparam DATA_RATE = `DATA_RATE_DEFINE;

oserdes_test #
(
.DATA_WIDTH   (DATA_WIDTH),
.DATA_RATE    (DATA_RATE)
)
oserdes_test
(
.CLK      (CLK),
.RST      (RST),

.I_DAT   (in),
.O_DAT   (out),
.O_ERROR  (error)
);

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[0] = !error;
assign led[1] = heartbeat_cnt[24];

endmodule

