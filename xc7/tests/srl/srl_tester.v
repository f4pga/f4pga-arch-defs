module srl_tester
(
input  wire       clk,
input  wire       rst,

input  wire [4:0] delay,
output reg        error,

output wire       srl_d,
input  wire       srl_q,
output wire       srl_ce,
output wire [4:0] srl_a
);

// ============================================================================
// Prescaler
`ifdef SIMULATION
localparam PRESCALER_TOP = 2;
`else
localparam PRESCALER_TOP = 50000000 - 2;
`endif

reg [32:0] prescaler;
wire       tick;

always @(posedge clk)
    if (rst)    prescaler <= 33'd0;
    else        prescaler <= (tick) ? PRESCALER_TOP : (prescaler - 1);

assign tick = prescaler[32];

// ============================================================================
// Pseudo-random data source
wire din;

/*
LFSR8_11D lfsr
(
.clk    (clk),
.ce     (tick),
.q      (din)
);
*/

ROM rom
(
.clk    (clk),
.ce     (tick),
.q      (din)
);


// ============================================================================
// Non-SRL variable delay

(* DONT_TOUCH = "yes" *)
reg [32:0] sreg;

always @(posedge clk)
    if (rst)        sreg <= 32'd0;
    else if(tick)   sreg <= (sreg << 1) | din;
    else            sreg <= sreg;

wire sreg_q = (sreg >> delay) & 1'd1;

// ============================================================================
// SRL interface

assign srl_d  = din;
assign srl_ce = tick;
assign srl_a  = delay;

// ============================================================================
// Data comparator

initial error <= 1'd0;

always @(posedge clk)
    if (rst) error <= 1'd0;
    else     error <= srl_q ^ sreg_q;

endmodule

