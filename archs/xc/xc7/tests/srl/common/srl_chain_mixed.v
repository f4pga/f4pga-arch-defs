// Fixed delay shift registed made of various configurations of chained SRL16s
// and SRL32s.
`ifndef __ICARUS__
`include "srlc16e.v"
`endif

module srl_chain_mixed #
(
parameter [0:0] BEGIN_WITH_SRL16 = 0,   // Start with SRL16.
parameter [1:0] NUM_SRL32        = 0,   // SRL32 count in the middle.
parameter [0:0] END_WITH_SRL16   = 0,   // End on SRL16.
parameter       SITE             = ""   // Site to LOC all bels to
)
(
input  wire CLK,
input  wire CE,
input  wire D,
output wire Q
);

// ============================================================================
// SRL16 at the beginning
wire d;

generate if (BEGIN_WITH_SRL16) begin

  // Use SRL16
  (* KEEP, DONT_TOUCH *)
  SRLC16E beg_srl16
  (
  .CLK  (CLK),
  .CE   (CE),
  .D    (D),
  .A0   (0),
  .A1   (0),
  .A2   (0),
  .A3   (0),
  .Q15  (d)
  );

end else begin

  // No SRL16
  assign d = D;

end endgenerate

// ============================================================================
// Chain of 0 or more SRL32s
wire q;

genvar i;
generate if (NUM_SRL32 > 0) begin

    wire [NUM_SRL32-1:0] srl_d;
    wire [NUM_SRL32-1:0] srl_q31;

    assign srl_d[0] = d;

    for(i=0; i<NUM_SRL32; i=i+1) begin

        (* KEEP, DONT_TOUCH *)
        SRLC32E srl
        (
        .CLK    (CLK),
        .CE     (CE),
        .A      (5'd0),
        .D      (srl_d[i]),
        .Q31    (srl_q31[i])
        );

        if (i > 0) begin
            assign srl_d[i] = srl_q31[i-1];
        end

    end

    assign q = srl_q31[NUM_SRL32-1];

end else begin

    // No SRL32s
    assign q = d;

end endgenerate

// ============================================================================
// SRL16 at the end

generate if (END_WITH_SRL16) begin

  // Use SRL16
  (* KEEP, DONT_TOUCH *)
  SRLC16E end_srl16
  (
  .CLK  (CLK),
  .CE   (CE),
  .D    (q),
  .A0   (0),
  .A1   (0),
  .A2   (0),
  .A3   (0),
  .Q15  (Q)
  );

end else begin

  // No SRL16
  assign Q = q;

end endgenerate

endmodule
