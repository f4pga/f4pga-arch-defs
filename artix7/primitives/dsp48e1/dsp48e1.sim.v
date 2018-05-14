// DSP48E1 - 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

`ifndef PB_TYPE
`include "dual_ad_preadder/dual_ad_preadder.sim.v"
`include "dual_b_reg/dual_b_reg.sim.v"
`include "mult25x18/mult25x18.sim.v"
`include "xmux/dsp48_xmux.sim.v"
`include "ymux/dsp48_ymux.sim.v"
`include "zmux/dsp48_zmux.sim.v"
`include "alu/alu.sim.v"
`endif

// Figure 2-1: 7 Series FPGA DSP48E1 Slice
module DSP48E1(
       A, B, C, D,
       OPMODE,ALUMODE, CARRYIN, CARRYINSEL, INMODE,
       CEA1, CEA2, CEB1, CEB2, CEC, CED, CEM, CEP, CEAD,
       CEALUMODE, CECTRL, CECARRYIN, CEINMODE,
       RSTA, RSTB, RSTC, RSTD, RSTM, RSTP, RSTCTRL, RSTALLCARRYIN, RSTALUMODE, RSTINMODE,
       CLK,
       ACIN, BCIN, PCIN, CARRYCASCIN, MULTSIGNIN,
       ACOUT, BCOUT, PCOUT, P, CARRYOUT, CARRYCASCOUT, MULTSIGNOUT, PATTERNDETECT, PATTERNBDETECT, OVERFLOW, UNDERFLOW
       );

   // Main inputs
   input wire [29:0] A;
   input wire [17:0] B;
   input wire [47:0] C;
   input wire [24:0] D;
   input wire [6:0]  OPMODE;
   input wire [3:0]  ALUMODE;
   input wire 	     CARRYIN;
   input wire [2:0]  CARRYINSEL;
   input wire [4:0]  INMODE;

   // Clock enable for registers
   input wire 	     CEA1;
   input wire 	     CEA2;
   input wire 	     CEB1;
   input wire 	     CEB2;
   input wire 	     CEC;
   input wire 	     CED;
   input wire 	     CEM;
   input wire 	     CEP;
   input wire 	     CEAD;
   input wire 	     CEALUMODE;
   input wire 	     CECTRL;
   input wire 	     CECARRYIN;
   input wire 	     CEINMODE;

   // Reset for registers
   input wire 	     RSTA;
   input wire 	     RSTB;
   input wire 	     RSTC;
   input wire 	     RSTD;
   input wire 	     RSTM;
   input wire 	     RSTP;
   input wire 	     RSTCTRL;
   input wire 	     RSTALLCARRYIN;
   input wire 	     RSTALUMODE;
   input wire 	     RSTINMODE;

   // clock for all registers and flip-flops
   input wire 	     CLK;

   // Interslice connections
   input wire [29:0] ACIN;
   input wire [17:0] BCIN;
   input wire [47:0] PCIN;
   input wire 	     CARRYCASCIN;
   input wire 	     MULTSIGNIN;

   output wire [29:0] ACOUT;
   output wire [17:0] BCOUT;
   output wire [47:0] PCOUT;
   output wire [47:0] P;

   // main outputs
   output wire [3:0]  CARRYOUT;
   output wire 	      CARRYCASCOUT;
   output wire 	      MULTSIGNOUT;
   output wire 	      PATTERNDETECT;
   output wire 	      PATTERNBDETECT;
   output wire 	      OVERFLOW;
   output wire 	      UNDERFLOW;

   // wires for concatenating A and B registers to XMUX input
   wire [47:0] 	      XMUX_CAT;
   wire [29:0] 	      XMUX_A_CAT;
   wire [17:0] 	      XMUX_B_CAT;

   // wires for multiplier inputs
   wire [24:0] 	      AMULT;
   wire [17:0] 	      BMULT;

`ifndef PB_TYPE

   parameter ACASCREG = 1;
   parameter ADREG = 1;
   parameter ALUMODEREG = 1;
   parameter AREG = 1;
   parameter BCASCREG = 1;
   parameter BREG = 1;
   parameter CARRYINREG = 1;
   parameter CARRYINSELREG = 1;
   parameter CREG = 1;
   parameter DREG = 1;
   parameter INMODEREG = 1;
   parameter MREG = 1;
   parameter OPMODEREG = 1;
   parameter PREG = 1;
   parameter A_INPUT = "DIRECT";
   parameter B_INPUT = "DIRECT";
   parameter USE_DPORT = "FALSE";
   parameter USE_MULT = "MULTIPLY";
   parameter USE_SIMD = "ONE48";
   parameter AUTORESET_PATDET = "NO_RESET";
   parameter MASK = 001111111111111111111111111111111111111111111111;
   parameter PATTERN = 000000000000000000000000000000000000000000000000;
   parameter SEL_MASK = "MASK";
   parameter SEL_PATTERN = "PATTERN";
   parameter USE_PATTERN_DETECT = "NO_PATDET";

   // input register blocks for A, B, D
   DUAL_AD_PREADDER dual_ad_preadder (.A(A), .ACIN(ACIN), .D(D), .INMODE(INMODE),
				      .ACOUT(ACOUT), .XMUX(XMUX_A_CAT), .AMULT(AMULT),
				      .CEA1(CEA1), .CEA2(CEA2), .RSTA(RSTA), .CED(CED), .CEAD(CEAD), .RSTD(RSTD), .CLK(CLK));
   DUAL_B_REG dualb_reg (.B(B), .BCIN(BCIN), .INMODE(INMODE),
			 .BCOUT(BCOUT), .XMUX(XMUX_B_CAT), .BMULT(BMULT),
			 .CEB1(CEB1), .CEB2(CEB2), .RSTB(RSTB), .CLK(CLK));

   // concatenate for XMUX
   assign XMUX_CAT = {XMUX_A_CAT, XMUX_B_CAT};

   // Multiplier output
   wire [85:0] 	      MULT_OUT;

   // 25bit by 18bit multiplier
   MULT25X18 mult25x18 (.A(AMULT), .B(BMULT), .OUT(MULT_OUT));

   // signals from muxes to ALU unit
   wire [47:0] 	      X;
   wire [47:0] 	      Y;
   wire [47:0] 	      Z;

   // TODO(elmsfu): take in full OPMODE to check for undefined behaviors
   // See table 2-7 for X mux selection
   DSP48_XMUX dsp48_xmux (.ZEROS(48'h000000000000), .M({5'b00000, MULT_OUT[85:43]}), .P(P), .AB_CAT(XMUX_CAT), .S(OPMODE[1:0]), .O(X));

   // See table 2-8 for Y mux selection
   DSP48_YMUX dsp48_ymux (.ZEROS(48'h000000000000), .M({5'b00000, MULT_OUT[42:0]}), .ONES(48'hFFFFFFFFFFFF), .C(C), .S(OPMODE[3:2]), .O(Y));

   // See table 2-9 for Z mux selection
   // Note: Z mux actually has 7 inputs but 2 and 4 are both P
   DSP48_ZMUX dsp48_zmux (.ZEROS(48'h000000000000), .PCIN(PCIN), .P(P), .C(C), .P2(P), .PCIN_UPSHIFT({ {17{PCIN[47]}}, PCIN[47:17]}), .P_UPSHIFT({ {17{P[47]}}, P[47:17]}), .S(OPMODE[6:4]), .O(Z));

   // See table 2-10 for 3 input behavior
   // See table 2-13 for 2 input behavior
   ALU alu (.X(X), .Y(Y), .Z(Z), .ALUMODE(ALUMODE), .CARRYIN(CARRYIN), .MULTSIGNIN(MULTSIGNIN), .OUT(P), .CARRYOUT(CARRYOUT), .MULTSIGNOUT(MULTSIGNOUT));

   assign PCOUT = P;

`endif //  `ifndef PB_TYPE

endmodule // DSP48E1
