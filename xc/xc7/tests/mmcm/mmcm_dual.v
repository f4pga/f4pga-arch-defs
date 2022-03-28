// A test with two MMCMs that have feedback through BUFGs

module top (
    input  wire         clk,
    input  wire         rx,
    output wire         tx,
    input  wire [15:0]  sw,
    output wire [15:0]  led
);

// ==========================================================================--
// Reset generator

reg [7:0] rst_sr;
wire      rst;

always @(posedge clk)
    rst_sr <= {1'b1, rst_sr[7:1]};

assign rst = ~rst_sr[0];

// ==========================================================================--
// MMCM 1

wire clk_1, clk_1_buf;
wire clkfb_1, clkfb_1_buf;

MMCME2_ADV # (
    .CLKIN1_PERIOD      (10.0),
    .CLKFBOUT_MULT_F    (8.00),
    .CLKOUT0_DIVIDE_F   (24.0),
    .COMPENSATION       ("ZHOLD")
) mmcm_1 (
    .RST        (rst),
    .CLKIN1     (clk),
    .CLKOUT0    (clk_1),
    .CLKFBIN    (clkfb_1_buf),
    .CLKFBOUT   (clkfb_1),
    .PWRDWN     (1'b0),
);

BUFG bufg_1_1 (.I(clk_1),   .O(clk_1_buf));
BUFG bufg_1_2 (.I(clkfb_1), .O(clkfb_1_buf));

reg [21:0] cnt_1;
always @(posedge clk_1_buf)
    cnt_1 <= cnt_1 + 1;

assign led[0] = cnt_1[21];

// ==========================================================================--
// MMCM 2

wire clk_2, clk_2_buf;
wire clkfb_2, clkfb_2_buf;

MMCME2_ADV # (
    .CLKIN1_PERIOD      (10.0),
    .CLKFBOUT_MULT_F    (8.00),
    .CLKOUT0_DIVIDE_F   (16.0),
    .COMPENSATION       ("ZHOLD")
) mmcm_2 (
    .RST        (rst),
    .CLKIN1     (clk),
    .CLKOUT0    (clk_2),
    .CLKFBIN    (clkfb_2_buf),
    .CLKFBOUT   (clkfb_2),
    .PWRDWN     (1'b0),
);

BUFG bufg_2_1 (.I(clk_2),   .O(clk_2_buf));
BUFG bufg_2_2 (.I(clkfb_2), .O(clkfb_2_buf));

reg [21:0] cnt_2;
always @(posedge clk_2_buf)
    cnt_2 <= cnt_2 + 1;

assign led[1] = cnt_2[21];

endmodule
