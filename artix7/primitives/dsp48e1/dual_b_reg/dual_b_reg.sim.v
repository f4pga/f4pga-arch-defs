// DSP48E1
// [1] 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

// Figure 2-8 and Table 2-6 shows details
`include "../nmux2/nmux2.sim.v"
`include "../nreg/nreg.sim.v"

module DUAL_B_REG
  (
   B, BCIN, INMODE,
   BCOUT, XMUX, BMULT
   );

   // input mux
   // DIRECT:  use B port
   // CASCADE: use BCIN port
   parameter B_INPUT = "DIRECT";

   // Number of registers in pipeline
   parameter BREG = 1;

   // Number of registers in BC pipeline
   // BREG = 0: BCASCREG must be 0
   // BREG = 1: BCASCREG must be 1
   // BREG = 2: BCASCREG can be 1 or 2
   parameter BCASCREG = 1;

   input wire [17:0] B;
   input wire [17:0] BCIN;
   input wire [4:0]  INMODE;

   output wire [17:0] BCOUT;
   output wire [17:0] XMUX;
   output wire [17:0] BMULT;

   wire 	      B_SEL = (B_INPUT == "DIRECT") ? 0 : 1;
   wire 	      CASC_SEL = (BCASCREG == 1);

   wire [17:0] 	      B1IN;
   wire [17:0] 	      B1OUT;
   wire [17:0] 	      B2IN;
   wire [17:0] 	      B2OUT;

   NMUX2 #(.NBITS(18)) binmux (.I0(B), .I1(BCIN), .S(B_SEL), .O(B1IN));
   NMUX2 #(.NBITS(18)) b1mux (.I0(B1IN), .I1(B1OUT), .S(BREG>1), .O(B2IN));
   NMUX2 #(.NBITS(18)) b2mux (.I0(B2IN), .I1(B2OUT), .S(BREG>0), .O(XMUX));
   NMUX2 #(.NBITS(18)) bcmux (.I0(XMUX), .I1(B1OUT), .S(CASC_SEL), .O(BCOUT));

   NREG #(.NBITS(18)) b1 (.D(B1IN), .Q(B1OUT), .CLK(CLK), .CE(CEB1), .RESET(RSTB));
   NREG #(.NBITS(18)) b2 (.D(B2IN), .Q(B2OUT), .CLK(CLK), .CE(CEB2), .RESET(RSTB));

   NMUX2 #(.NBITS(18)) bmultmux (.I0(B1OUT), .I1(XMUX), .S(INMODE[4]), .O(BMULT));

endmodule // DUALB_REG
