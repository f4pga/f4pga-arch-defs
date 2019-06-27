module top
(
input  wire        clk,

input  wire [7:0]  sw,
output wire [7:0]  led
);

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
localparam PRESCALER = 1000000;

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

assign led[7] = blink_cnt[3];

// ============================================================================
// SRL32 testers

wire sim_error = sw[2];

wire [5:0] srl_q;
wire [5:0] error;

genvar i;
generate for(i=0; i<6; i=i+1) begin
  wire [4:0] srl_a;
  wire       srl_d;
  wire       srl_sh;

  srl_shift_tester tester
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

  SRLC32E srl
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
reg [5:0] error_lat = 0;
always @(posedge clk)
    if (rst)
        error_lat <= 0;
    else
        error_lat <= error_lat | error;

// LEDs
assign led[5:0] = (sw[1]) ? error_lat[5:0] : error[5:0];
assign led[6]   = srl_q[0];

endmodule

