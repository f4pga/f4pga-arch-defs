module top
(
input  wire         clk,

input  wire         rx,
output wire         tx,

input  wire [15:0]  sw,
output wire [15:0]  led
);

parameter PRESCALER = 4; //100000;

// UART loopback + switches to avoid unused inputs
assign tx = rx || (|sw);

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
// SRL chain testers

wire sim_error = sw[2];

wire [7:0] srl_q;
wire [7:0] error;

genvar i;
generate for(i=0; i<8; i=i+1) begin

  localparam j = (i % 4);

  wire srl_d;
  wire srl_sh;

  localparam SITE = (i==0) ?   "SLICE_X2Y100" :
                    (i==1) ?   "SLICE_X2Y101" :
                    (i==2) ?   "SLICE_X2Y102" :
                    (i==3) ?   "SLICE_X2Y103" :
                    (i==4) ?   "SLICE_X2Y104" :
                    (i==5) ?   "SLICE_X2Y105" :
                    (i==6) ?   "SLICE_X2Y106" :
                  /*(i==7) ?*/ "SLICE_X2Y107";

  srl_shift_tester #
  (
  .SRL_LENGTH  ((j==0) ? 32 : (16 + j*32)),
  .FIXED_DELAY ((j==0) ? 32 : (16 + j*32))
  )
  tester
  (
  .clk      (clk),
  .rst      (rst),
  .ce       (ps_tick),
  .srl_sh   (srl_sh),
  .srl_d    (srl_d),
  .srl_q    (srl_q[i] ^ sim_error),
  .error    (error[i])
  );

  srl_chain_mixed  #
  (
  .BEGIN_WITH_SRL16 ((j==0) || (i>=8)),
  .END_WITH_SRL16   ((j==0) || (i< 8)),
  .NUM_SRL32        (j),
  .SITE             (SITE)
  )
  chain_seg
  (
  .CLK      (clk),
  .CE       (srl_sh),
  .D        (srl_d),
  .Q        (srl_q[i])
  );

end endgenerate

// ============================================================================

// Error latch
reg [7:0] error_lat = 0;
always @(posedge clk)
    if (rst)
        error_lat <= 0;
    else
        error_lat <= error_lat | error;

// ============================================================================

// LEDs
genvar j;
generate for(j=0; j<8; j=j+1) begin
  assign led[j  ] = (sw[1]) ? error_lat[j] : error[j];
  assign led[j+8] = srl_q[j];
end endgenerate

endmodule

