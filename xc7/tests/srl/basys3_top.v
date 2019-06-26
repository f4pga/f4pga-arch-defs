module top
(
input  wire        clk,

input  wire [7:0]  sw,
output wire [7:0]  led
);

// ============================================================================
// Reset synchronizer
reg [2:0] rst_sync = 3'h7;
wire rst = rst_sync[0];

always @(posedge clk) 
    if (sw[7])  rst_sync <= 3'h7;
    else        rst_sync <= rst_sync >> 1;

// ============================================================================
// Button synchronizers
reg [4:0] delay_x = 5'd0;
reg [4:0] delay_y = 5'd0;
reg [4:0] delay   = 5'd0;

always @(posedge clk) delay_x <= sw[4:0];
always @(posedge clk) delay_y <= delay_x;
always @(posedge clk) delay   <= delay_y;

// ============================================================================
// DUT
wire       srl_d;
wire       srl_q;
wire       srl_ce;
wire [4:0] srl_a;

(* DONT_TOUCH = "yes" *)
SRLC32E srl
(
.CLK    (clk),
.CE     (srl_ce),
.D      (srl_d ^ sw[6]),
.Q      (srl_q),
.A      (srl_a)
);

srl_tester dut
(
.clk    (clk),
.rst    (rst),

.delay  (delay),
.error  (error),

.srl_d  (srl_d),
.srl_q  (srl_q),
.srl_ce (srl_ce),
.srl_a  (srl_a)
);

// ============================================================================

reg [13:0] srl_vis;
reg [13:0] inp_vis;

always @(posedge clk)
    if (rst)
        srl_vis <= 0;
    else if (srl_ce)
        srl_vis <= (srl_vis << 1) | srl_q;

always @(posedge clk)
    if (rst)
        inp_vis <= 0;
    else if (srl_ce)
        inp_vis <= (inp_vis << 1) | (srl_d ^ sw[6]);

// ============================================================================

assign led[0] = inp_vis[4];
assign led[1] = inp_vis[3];
assign led[2] = inp_vis[2];
assign led[3] = inp_vis[1];

assign led[4] = srl_vis[0];
assign led[5] = srl_vis[1];
assign led[6] = srl_vis[2];
assign led[7] = srl_vis[3];

endmodule
