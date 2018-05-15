// DSP48E1
// [1] 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

// Figure 2-8 and Table 2-6 shows details
`include "bin_mux/bin_mux.sim.v"
`include "b1reg_mux/b1reg_mux.sim.v"
`include "b2reg_mux/b2reg_mux.sim.v"
`include "bc_mux/bc_mux.sim.v"
`include "bmult_mux/bmult_mux.sim.v"

`include "../nreg/nreg.sim.v"

module DUAL_B_REG
  (
   B, BCIN, INMODE,
   BCOUT, XMUX, BMULT,
   CEB1, CEB2, RSTB, CLK
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

   input wire 	      CEB1;
   input wire 	      CEB2;
   input wire 	      RSTB;
   input wire 	      CLK;

   wire [17:0] 	      B1IN;
   wire [17:0] 	      B1OUT;
   wire [17:0] 	      B2IN;
   wire [17:0] 	      B2OUT;

   BIN_MUX #(.S(B_INPUT == "CASCADE")) bin_mux (.B(B), .BCIN(BCIN), .O(B1IN));
   B1REG_MUX #(.S(BREG>1)) b1_mux (.BYPASS(B1IN), .REG(B1OUT), .O(B2IN));
   B2REG_MUX #(.S(BREG>0)) b2_mux (.BYPASS(B2IN), .REG(B2OUT),  .O(XMUX));

   // If 0, then both reg muxes are in bypass, so use B2_MUX output
   // If 1, then use B1 register output (this works for BREG=1 or 2
   // If 2, then both reg muxes are not in bypass so use B2_MUX output
   BC_MUX #(.S(BCASCREG == 1)) bc_mux (.B1REG(B1OUT), .B2(XMUX), .O(BCOUT));

   NREG #(.NBITS(18)) b1 (.D(B1IN), .Q(B1OUT), .CLK(CLK), .CE(CEB1), .RESET(RSTB));
   NREG #(.NBITS(18)) b2 (.D(B2IN), .Q(B2OUT), .CLK(CLK), .CE(CEB2), .RESET(RSTB));

   BMULT_MUX bmultmux (.B2(XMUX), .B1REG(B1OUT), .S(INMODE[4]), .O(BMULT));

endmodule // DUALB_REG
