`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire sw,
output wire [1:0] led,

input  wire [0:0] i_dat,
output wire [0:0] o_dat
);

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

always @(posedge clk)
    if (sw)
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

wire CLK, CLKDIV;
BUFG bufg(.I(clk), .O(CLK));

wire clk_div_tmp, clk_div_tmp_1;
clk_div clk_div_1(.clk_in(clk), .clk_out(clk_div_tmp));
clk_div clk_div_2(.clk_in(clk_div_tmp), .clk_out(clk_div_tmp_1));

BUFG bufg_div(.I(clk_div_tmp_1), .O(CLKDIV));

// ============================================================================
// Clocks for OSERDES


// ============================================================================
// Test uints
wire [0:0] error;


oserdes_test #
(
.DATA_WIDTH   (8),
.DATA_RATE    ("SDR")
)
oserdes_test
(
.CLK      (CLK),
.CLKDIV   (CLKDIV),
.RST      (RST),

.O_DAT    (o_dat),
.I_DAT   (i_dat),
.O_ERROR  (error[0])
);

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[0] = i_dat;
assign led[1] = heartbeat_cnt[23];

endmodule

module clk_div (
    input clk_in,
    output clk_out
);

    initial begin
        clk_out <= 0;
    end

    always @(posedge clk_in) begin
        clk_out <= ~clk_out;
    end

endmodule

// ============================================================================

module lfsr #
(
parameter WIDTH = 16, // LFSR width
parameter [WIDTH-1:0] POLY  = 16'hD008, // Polynomial
parameter [WIDTH-1:0] SEED  = 1 // Initial value
)
(
input  wire CLK,
input  wire CE,
input  wire RST,

output reg [WIDTH-1:0] O
);

wire feedback = ^(O & POLY);

always @(posedge CLK) begin
  if(RST) begin
    O <= SEED;
  end else if(CE) begin
    O <= {O[WIDTH-2:0], feedback};
  end
end

endmodule

// This module compares two bitstreams and automatically determines their
// offset. This is done by iteratively changing bit delay for I_DAT_REF
// every time the number of errors exceeds ERROR_COUNT. The output O_ERROR
// signal is high for at least ERROR_HOLD cycles.

// ============================================================================

module comparator #
(
parameter ERROR_COUNT = 8,
parameter ERROR_HOLD  = 2500000
)
(
input  wire CLK,
input  wire RST,

input  wire I_DAT_REF,
input  wire I_DAT_IOB,

output wire O_ERROR
);

// ============================================================================
// Data latch
reg [2:0] i_dat_ref_sr;
reg [2:0] i_dat_iob_sr;

always @(posedge CLK)
    i_dat_ref_sr <= (i_dat_ref_sr << 1) | I_DAT_REF;
always @(posedge CLK)
    i_dat_iob_sr <= (i_dat_iob_sr << 1) | I_DAT_IOB;

wire i_dat_ref = i_dat_ref_sr[2];
wire i_dat_iob = i_dat_iob_sr[2];

// ============================================================================
// Shift register for reference data, shift strobe generator.
reg  [31:0] sreg;
reg  [ 4:0] sreg_sel;
wire        sreg_dat;
reg         sreg_sh;

always @(posedge CLK)
    sreg <= (sreg << 1) | i_dat_ref;

always @(posedge CLK)
    if (RST)
        sreg_sel <= 0;
    else if(sreg_sh)
        sreg_sel <= sreg_sel + 1;

assign sreg_dat = sreg[sreg_sel];

// ============================================================================
// Comparator and error counter
wire        cmp_err;
reg  [31:0] err_cnt;

assign cmp_err = sreg_dat ^ i_dat_iob;

always @(posedge CLK)
    if (RST)
        err_cnt <= 0;
    else if(sreg_sh)
        err_cnt <= 0;
    else if(cmp_err)
        err_cnt <= err_cnt + 1;

always @(posedge CLK)
    if (RST)
        sreg_sh <= 0;
    else if(~sreg_sh && (err_cnt == ERROR_COUNT))
        sreg_sh <= 1;
    else
        sreg_sh <= 0;

// ============================================================================
// Output generator
reg [24:0] o_cnt;

always @(posedge CLK)
    if (RST)
        o_cnt <= -1;
    else if (cmp_err)
        o_cnt <= ERROR_HOLD - 2;
    else if (~o_cnt[24])
        o_cnt <= o_cnt - 1;

assign O_ERROR = !o_cnt[24];

endmodule

module oserdes_test #
(
parameter DATA_WIDTH    = 8,
parameter DATA_RATE     = "SDR",
parameter ERROR_HOLD    = 2500000
)
(
// "Hi speed" clock and reset
input  wire CLK,
input  wire CLKDIV,
input  wire RST,

// Data out pin
output wire O_DAT,

// Data in pin
input wire I_DAT,

// Error indicator
output wire O_ERROR
);

// ============================================================================
// Generate CLK2 and CLKDIV for OSERDES using BUFRs

localparam CLKDIV_DIVIDE = 
    (DATA_RATE == "SDR" && DATA_WIDTH == 2) ? "2" :
    (DATA_RATE == "SDR" && DATA_WIDTH == 3) ? "3" : 
    (DATA_RATE == "SDR" && DATA_WIDTH == 4) ? "4" : 
    (DATA_RATE == "SDR" && DATA_WIDTH == 5) ? "5" : 
    (DATA_RATE == "SDR" && DATA_WIDTH == 6) ? "6" : 
    (DATA_RATE == "SDR" && DATA_WIDTH == 7) ? "7" : 
    (DATA_RATE == "SDR" && DATA_WIDTH == 8) ? "8" : 

    (DATA_RATE == "DDR" && DATA_WIDTH == 4) ? "4" : 
    (DATA_RATE == "DDR" && DATA_WIDTH == 6) ? "6" : 
    (DATA_RATE == "DDR" && DATA_WIDTH == 8) ? "8" : "BYPASS";

// ============================================================================
// Data source
reg         lfsr_stb;
wire [7:0]  lfsr_dat;

wire clkdiv_r;
wire ce;

always @(posedge CLK)
    clkdiv_r <= CLKDIV;

assign ce = clkdiv_r && !CLKDIV;

lfsr lfsr
(
.CLK    (CLK),
.RST    (RST),
.CE     (ce),

.O      (lfsr_dat)
);

always @(posedge CLK)
    if (RST)
        lfsr_stb <= 1'b0;
    else
        lfsr_stb <= ce;

// Synchronize generated data wordst to the CLKDIV
reg  [7:0] ser_dat;

always @(posedge CLKDIV)
    ser_dat <= lfsr_dat;

// ============================================================================
// OSERDES 

// OSERDES reset generator (required for it to work properly!)
reg [3:0]  ser_rst_sr;
initial    ser_rst_sr <= 4'hF;

always @(posedge CLKDIV)
    if (RST) ser_rst_sr <= 4'hF;
    else     ser_rst_sr <= ser_rst_sr >> 1;

wire ser_rst = ser_rst_sr[0];

// OSERDES
wire ser_oq;
wire ser_tq;

OSERDESE2 #
(
.DATA_RATE_OQ   (DATA_RATE),
.DATA_WIDTH     (DATA_WIDTH),
.DATA_RATE_TQ   ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? "DDR" : "SDR"),
.TRISTATE_WIDTH ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? 4 : 1)
)
oserdes
(
.CLK    (CLK),
.CLKDIV (CLKDIV),
.RST    (ser_rst),

.OCE    (1'b1),
.D1     (ser_dat[0]),
.D2     (ser_dat[1]),
.D3     (ser_dat[2]),
.D4     (ser_dat[3]),
.D5     (ser_dat[4]),
.D6     (ser_dat[5]),
.D7     (ser_dat[6]),
.D8     (ser_dat[7]),
.OQ     (O_DAT),

.TCE    (1'b0),
.T1     (1'b0), // All 0 to keep OBUFT always on.
.T2     (1'b0),
.T3     (1'b0),
.T4     (1'b0)
);

// ============================================================================
// Reference data serializer
reg  [7:0]  ref_sr;
wire        ref_o;

always @(posedge CLK)
    if (RST)
        ref_sr <= 0;
    else if (ce)
        ref_sr <= lfsr_dat;
    else
        ref_sr <= ref_sr >> 1;

assign ref_o = ref_sr[0];

// ============================================================================
// Data comparator

comparator #
(
.ERROR_COUNT    (16),
.ERROR_HOLD     (ERROR_HOLD)
)
comparator
(
.CLK    (CLK),
.RST    (RST),

.I_DAT_REF  (ref_o),
.I_DAT_IOB  (I_DAT),

.O_ERROR    (O_ERROR)
);

endmodule
