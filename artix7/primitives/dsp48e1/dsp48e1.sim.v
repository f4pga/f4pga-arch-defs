`include "DualAD_Preadder/sim.v"
`include "DualB/sim.v"
`include "Mult25x18/sim.v"
`include "nmux4/sim.v"
`include "nmux7/sim.v"
`include "ALU/sim.v"

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

   input wire [29:0] A;
   input wire [17:0] B;
   input wire [47:0] C;
   input wire [24:0] D;
   input wire [6:0]  OPMODE;
   input wire [3:0]  ALUMODE;
   input wire 	     CARRYIN;
   input wire [2:0]  CARRYINSEL;
   input wire [4:0]  INMODE;

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

   input wire 	     CLK;

   input wire [29:0] ACIN;
   input wire [17:0] BCIN;
   input wire [47:0] PCIN;
   input wire 	     CARRYCASCIN;
   input wire 	     MULTSIGNIN;

   output wire [29:0] ACOUT;
   output wire [17:0] BCOUT;
   output wire [47:0] PCOUT;
   output wire [47:0] P;

   output wire [3:0]  CARRYOUT;
   output wire 	      CARRYCASCOUT;
   output wire 	      MULTSIGNOUT;
   output wire 	      PATTERNDETECT;
   output wire 	      PATTERNBDETECT;
   output wire 	      OVERFLOW;
   output wire 	      UNDERFLOW;

   wire [47:0] 	      XMUX_CAT;
   wire [29:0] 	      XMUX_A_CAT;
   wire [17:0] 	      XMUX_B_CAT;

   wire [24:0] 	      AMULT;
   wire [17:0] 	      BMULT;

   DUALAD_PREADDER dualad_preadder (.A(A), .ACIN(ACIN), .D(D), .ACOUT(ACOUT), .XMUX(XMUX_A_CAT), .AMULT(AMULT));
   DUALB_REG dualb_reg (.B(B), .BCIN(BCIN), .BCOUT(BCOUT), .XMUX(XMUX_B_CAT), .BMULT(BMULT));

   assign XMUX_CAT = {XMUX_A_CAT, XMUX_B_CAT};

   wire [85:0] 	      MULT_OUT;

   MULT25X18 mult25x18 (.A(AMULT), .B(BMULT), .OUT(MULT_OUT));

   wire [47:0] 	      X;
   wire [47:0] 	      Y;
   wire [47:0] 	      Z;

   NMUX4 #(.NBITS(48)) xmux (.I0(48'h000000000000), .I1({5'b00000, MULT_OUT[85:43]}), .I2(P), .I3(XMUX_CAT), .S(OPMODE[1:0]), .O(X));
   NMUX4 #(.NBITS(48)) ymux (.I0(48'h000000000000), .I1({5'b00000, MULT_OUT[42:0]}), .I2(48'hFFFFFFFFFFFF), .I3(C), .S(OPMODE[3:2]), .O(Y));

   // TODO(elmsfu): z mux atually has 7 outputs from table 2-9, but 2 and 4 are both P
   NMUX7 #(.NBITS(48)) zmux (.I0(48'h000000000000), .I1(PCIN), .I2(P), .I3(C), .I4(P), .I5({ {17{PCIN[47]}}, PCIN[47:17]}), .I6({ {17{P[47]}}, P[47:17]}), .S(OPMODE[6:4]), .O(Z));

   ALU alu (.X(X), .Y(Y), .Z(Z), .ALUMODE(ALUMODE), .CARRYIN(CARRYIN), .MULTSIGNIN(MULTSIGNIN), .OUT(P), .CARRYOUT(CARRYOUT), .MULTSIGNOUT(MULTSIGNOUT));

   assign PCOUT = P;

endmodule // DSP48E1




