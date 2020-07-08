module top
(
input  wire         clk,

input  wire         rx,
output wire         tx,

input  wire [15:0]  sw,
output wire [15:0]  led
);

parameter PRESCALER = 4; //100000;

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
// SRL32 testers

wire sim_error = sw[2];

wire [3:0] srl_q;
wire [3:0] error;

genvar i;
generate for(i=0; i<4; i=i+1) begin
  wire [6:0] srl_a;
  wire       srl_d;
  wire       srl_sh;

  localparam SITE = (i==0) ?   "SLICE_X2Y100" :
                    (i==1) ?   "SLICE_X2Y101" :
                    (i==2) ?   "SLICE_X2Y102" : "SLICE_X2Y103";

  srl_shift_tester #(.FIXED_DELAY(32*(i+1)-1), .SRL_LENGTH(32 * (i+1))) tester
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

  srl32_chain_seg  #(.SITE(SITE), .N(i+1)) chain_seg
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
reg [3:0] error_lat = 0;
always @(posedge clk)
    if (rst)
        error_lat <= 0;
    else
        error_lat <= error_lat | error;

// ============================================================================

// LEDs
genvar j;
generate for(j=0; j<8; j=j+1) begin
  if (j < 4) begin
    assign led[j  ] = (sw[1]) ? error_lat[j] : error[j];
    assign led[j+8] = srl_q[j];
  end else begin
    assign led[j  ] = |sw;
    assign led[j+8] = |sw;
  end
end endgenerate

endmodule

