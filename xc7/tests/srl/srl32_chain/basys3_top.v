module top
(
input  wire         clk,

input  wire         rx,
output wire         tx,

input  wire [15:0]  sw,
output wire [15:0]  led
);

parameter SRLS_IN_CHAIN = 2;
parameter CHAIN_COUNT   = 1;

parameter PRESCALER = 1000000;

// UART loopback
assign tx = rx;

// ============================================================================
// Reset
reg  [3:0] rst_sr;
wire       rst;

initial rst_sr <= 4'hF;
always @(posedge clk)
    if (sw[0])  rst_sr <= 4'hF;
    else        rst_sr <= rst_sr >> 1;

assign rst = rst_sr[0];

// ============================================================================
// Clock prescaler
reg [32:0]  ps_cnt  = 0;
wire        ps_tick = ps_cnt[32];

always @(posedge clk)
    if (rst || ps_tick)
        ps_cnt <= PRESCALER - 2;
    else
        ps_cnt <= ps_cnt - 1;

// ============================================================================
// Led blinker
reg [3:0] blink_cnt = 0;

always @(posedge clk)
    if (rst)
        blink_cnt <= 0;
    else if (ps_tick)
        blink_cnt <= blink_cnt + 1;


// ============================================================================
// SRL32 testers

wire sim_error = sw[2];

wire [CHAIN_COUNT-1:0] srl_q;
wire [CHAIN_COUNT-1:0] error;

genvar i;
generate for(i=0; i<CHAIN_COUNT; i=i+1) begin
  wire [6:0] srl_a;
  wire       srl_d;
  wire       srl_sh;

  srl_shift_tester #(.SRL_LENGTH(32 * SRLS_IN_CHAIN)) tester
  (
  .clk      (clk),
  .rst      (rst),
  .ce       (ps_tick),
  .srl_sh   (srl_sh),
  .srl_d    (srl_d),
  .srl_q    (srl_q[i] ^ sim_error),
  .srl_a    (srl_a),
  .error    (error[i])
  );

  srl32_chain_seg #(.N(SRLS_IN_CHAIN)) chain_seg
  (
  .CLK      (clk),
  .CE       (srl_sh),
  .A        (srl_a),
  .D        (srl_d),
  .Q        (srl_q[i])
  );

end endgenerate

// ============================================================================

// Error latch
reg [CHAIN_COUNT-1:0] error_lat = 0;
always @(posedge clk)
    if (rst)
        error_lat <= 0;
    else
        error_lat <= error_lat | error;

// LEDs
assign led[CHAIN_COUNT-1:0] = (sw[1]) ? error_lat : error;

genvar j;
generate if (CHAIN_COUNT < 13)
 for (j = CHAIN_COUNT; j <= 13; j = j + 1)
     assign led[j] = led[CHAIN_COUNT-1];
endgenerate

assign led[14] = srl_q[0];
assign led[15] = blink_cnt[3] ^ |sw[15:3];

endmodule

