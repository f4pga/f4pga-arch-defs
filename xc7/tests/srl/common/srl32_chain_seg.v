// This module explicitly instantiates a chain of 1 to 4 SRL32s along with
// required MUXF7s and MUX8.
module srl32_chain_seg #
(
parameter           N = 1,      // Numbers of SRL32s in chain (from 1 to 4!)
parameter           SITE = ""   // Site to LOC all bels to
)
(
input  wire CLK,
input  wire CE,
input  wire D,
input  wire [4+$clog2(N):0] A,
output wire Q,
output wire Q31
);

// ============================================================================
// SRLs

wire [N-1:0]    srl_d;
wire [N-1:0]    srl_q;
wire [N-1:0]    srl_q31;

assign srl_d[0] = D;

// SRLs
genvar i;
generate for(i=0; i<N; i=i+1) begin

    (* KEEP, DONT_TOUCH *)
    SRLC32E srl
    (
    .CLK    (CLK),
    .CE     (CE),
    .A      (A[4:0]),
    .D      (srl_d[i]),
    .Q      (srl_q[i]),
    .Q31    (srl_q31[i])
    );

    if (i > 0)
        assign srl_d[i] = srl_q31[i-1];

end endgenerate

// ============================================================================
// Muxes

wire f7bmux_o;
wire f7amux_o;
wire f8mux_o;

generate

  if (N == 2) begin

    // F7AMUX
    (* BEL="F7AMUX", KEEP, DONT_TOUCH *)
    MUXF7 muxf7a
    (
    .I0     (srl_q[0]),
    .I1     (srl_q[1]),
    .S      (A[5]),
    .O      (f7amux_o)
    );

  end else if (N >= 3) begin

    // F7BMUX
    (* BEL="F7BMUX", KEEP, DONT_TOUCH *)
    MUXF7 muxf7b
    (
    .I0     (srl_q[0]),
    .I1     (srl_q[1]),
    .S      (A[5]),
    .O      (f7bmux_o)
    );

    if (N == 3) begin

      // F7AMUX
      (* BEL="F7AMUX", KEEP, DONT_TOUCH *)
      MUXF7 muxf7a
      (
      .I0     (srl_q[2]),
      .I1     (),
      .S      (A[5]),
      .O      (f7amux_o)
      );

    end else if (N == 4) begin

      // F7AMUX
      (* BEL="F7AMUX", KEEP, DONT_TOUCH *)
      MUXF7 muxf7a
      (
      .I0     (srl_q[2]),
      .I1     (srl_q[3]),
      .S      (A[5]),
      .O      (f7amux_o)
      );

    end

    // F8MUX
    (* BEL="F8MUX", KEEP, DONT_TOUCH *)
    MUXF8 muxf8
    (
    .I0     (f7bmux_o),
    .I1     (f7amux_o),
    .S      (A[6]),
    .O      (f8mux_o)
    );

  end

endgenerate

// ============================================================================
// Output assignment

assign Q =  (N == 1) ? srl_q[0] :
            (N == 2) ? f7amux_o : f8mux_o;

assign Q31 = srl_q31[N-1];

endmodule
