// DSP48E1
// [1] 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

`include "amux/areg_mux.sim.v"
`include "dmux/dreg_mux.sim.v"
`include "ain_mux/ain_mux.sim.v"
`include "acout_mux/acout_mux.sim.v"
`include "amult_mux/amult_mux.sim.v"
`include "a_adder_mux/a_adder_mux.sim.v"
`include "../nreg/nreg.sim.v"

// Figure 2-7 shows details
module DUAL_AD_PREADDER
  (
   A, ACIN, D, INMODE,
   ACOUT, XMUX, AMULT,
   CEA1, CEA2, RSTA, CED, CEAD, RSTD, CLK
   );

   parameter A_INPUT = "DIRECT";

   parameter ACASCREG = 1;
   parameter ADREG = 1;
   parameter ALUMODEREG = 1;
   parameter AREG = 1;

   parameter DREG = 1;
   parameter USE_DPORT = "FALSE";

   input wire [29:0] A;
   input wire [29:0] ACIN;
   input wire [24:0] D;
   input wire [4:0]  INMODE;

   output wire [29:0] ACOUT;
   output wire [29:0] XMUX;
   output wire [24:0] AMULT;

   input wire 	      CEA1;
   input wire 	      CEA2;
   input wire 	      RSTA;
   input wire 	      CED;
   input wire 	      CEAD;
   input wire 	      RSTD;

   input wire 	      CLK;

   wire [29:0] 	      A1IN;
   wire [29:0] 	      A1REG_OUT;
   wire [29:0]	      A2IN;
   wire [29:0]	      A2REG_OUT;
   wire [29:0]	      XMUX;
   wire [24:0]	      DREG_OUT;
   wire [24:0]	      DOUT;
   wire [24:0]	      ADDER_OUT;
   wire [24:0]	      ADDER_AIN;
   wire [24:0]	      ADDER_DIN;
   wire [24:0]	      ADREG_OUT;
   wire [24:0]	      AD_OUT;

   wire [24:0]	      A_ADDER_CANDIDATE;

`ifndef PB_TYPE
   AIN_MUX #(.S(A_INPUT == "DIRECT")) ain_mux (.A(A), .ACIN(ACIN), .O(A1IN));
   AREG_MUX #(.S(AREG==2)) a1mux (.BYPASS(A1IN), .REG(A1REG_OUT), .O(A2IN));
   AREG_MUX #(.S(AREG>0)) a2mux (.BYPASS(A2IN), .REG(A2REG_OUT), .O(XMUX));
   ACOUT_MUX #(.S(ACASCREG == 1)) acout_mux (.I0(A1REG_OUT), .I1(XMUX), .O(ACOUT));

   NREG #(.NBITS(30)) a1 (.D(A1IN), .Q(A1REG_OUT), .CLK(CLK), .CE(CEA1), .RESET(RSTA));
   NREG #(.NBITS(30)) a2 (.D(A2IN), .Q(A2REG_OUT), .CLK(CLK), .CE(CEA2), .RESET(RSTA));

   DREG_MUX #(.S(DREG == 0)) d_mux (.BYPASS(D), .REG(DREG_OUT), .O(DOUT));
   DREG_MUX #(.S(ADREG == 0)) ad_mux (.BYPASS(ADDER_OUT), .REG(ADREG_OUT), .O(AD_OUT));

   NREG #(.NBITS(25)) d (.D(D), .Q(DREG_OUT), .CLK(CLK), .CE(CED), .RESET(RSTD));
   NREG #(.NBITS(25)) ad (.D(ADDER_OUT), .Q(ADREG_OUT), .CLK(CLK), .CE(CEAD), .RESET(RSTD));

   A_ADDER_MUX a_adder_muxx (.A2(XMUX[24:0]), .A1(A1REG_OUT[24:0]), .S(INMODE[0]), .O(A_ADDER_CANDIDATE));

   A_ADDER_MUX a_or_zero (.A2(A_ADDER_CANDIDATE), .A1(25'b0), .S(INMODE[1]), .O(ADDER_AIN));
   A_ADDER_MUX d_or_zero (.A2(25'b0), .A1(DOUT), .S(INMODE[2]), .O(ADDER_DIN));

   assign ADDER_OUT = INMODE[3] ? (ADDER_DIN - ADDER_AIN) : (ADDER_DIN + ADDER_AIN);

   AMULT_MUX #(.S(USE_DPORT == "FALSE")) amult_mux (.A(ADDER_AIN), .ADDER_OUT(ADDER_OUT), .O(AMULT));
`endif //  `ifndef PB_TYPE

endmodule // DUAL_AD_PREADDER

// Table 2-5 defines behavior
