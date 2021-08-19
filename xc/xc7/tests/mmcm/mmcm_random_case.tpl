`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire [7:0] sw,
output wire [7:0] led
);

// ============================================================================

// Input clock BUFG
wire CLK100;
BUFG bufgctrl(.I(clk), .O(CLK100));

// Clock times 2 divider
reg clk50_ce;
always @(posedge CLK100)
    clk50_ce <= !clk50_ce;

wire CLK50;
BUFGCE bufg50 (.I(clk), .CE(clk50_ce), .O(CLK50));

// Reset pulse generator
reg [3:0] rst_sr;
initial rst_sr <= 4'hF;

always @(posedge CLK100)
    if (sw[0])
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

// ============================================================================
// MMCM

wire [6:0] oclk;
wire [6:0] gclk;

wire clk_fb;

wire pwrdwn   = sw[1];
wire clkinsel = sw[2];

wire locked;

(* LOC="MMCME2_ADV_X1Y0" *)
MMCME2_ADV #
(
.BANDWIDTH          ("{{ bandwidth }}"),
.COMPENSATION       ("INTERNAL"),

.CLKIN1_PERIOD      (10.0),  // 100MHz, actually 50MHz
.CLKIN2_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT_F    ({{ clkfbout_mult |round(3) }}),
.CLKFBOUT_PHASE     ({{ clkfbout_phase|round(3) }}),

.DIVCLK_DIVIDE      ({{ divclk_divide }}),

{%- if clkout[0].enabled %}
.CLKOUT0_DIVIDE_F   ({{ clkout[0].divide|round(3) }}),
.CLKOUT0_DUTY_CYCLE ({{ clkout[0].duty  |round(3) }}),
.CLKOUT0_PHASE      ({{ clkout[0].phase |round(3) }}),
{%- endif %}

{%- for clk in clkout %}
{%- if clk.enabled and clk.index != 0 %}
.CLKOUT{{ clk.index }}_DIVIDE     ({{ clk.divide|round(3) }}),
.CLKOUT{{ clk.index }}_DUTY_CYCLE ({{ clk.duty  |round(3) }}),
.CLKOUT{{ clk.index }}_PHASE      ({{ clk.phase |round(3) }}),
{%- endif %}
{%- endfor %}

.STARTUP_WAIT       ("FALSE")
)
mmcm
(
.CLKIN1     (CLK50),
.CLKIN2     (CLK100),
.CLKINSEL   (clkinsel),

.RST        (RST),
.PWRDWN     (pwrdwn),
.LOCKED     (locked),

{% for clk in clkout %}
{%- if clk.enabled %}
.CLKOUT{{ clk.index }}    (oclk[{{ clk.index }}]),
{%- endif %}
{%- endfor %}

.CLKFBIN    (clk_fb),
.CLKFBOUT   (clk_fb)
);

// ============================================================================
// Counters

wire rst = RST || !locked;

{%- for clk in clkout %}
{% if clk.enabled %}
BUFG bufg{{ clk.index }} (.I(oclk[{{ clk.index }}]), .O(gclk[{{ clk.index }}]));

reg [23:0] counter{{ clk.index }};
always @(posedge gclk[{{ clk.index }}] or posedge rst)
  if (rst) counter{{ clk.index }} <= 0;
  else     counter{{ clk.index }} <= counter{{ clk.index }} + 1;

assign led[{{ clk.index }}] = counter{{ clk.index }}[21];
{%- else %}
assign led[{{ clk.index }}] = 1'b0;
{%- endif %}
{%- endfor %}

// ============================================================================

endmodule
