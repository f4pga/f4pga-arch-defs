// DSP48E1
// [1] 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

// Figure 2-8 and Table 2-6 shows details
module DUAL_B_REG
  (
   B, BCIN,
   BCOUT, XMUX, BMULT
   );


   input wire [17:0] B;
   input wire [17:0] BCIN;

   output wire [17:0] BCOUT;
   output wire [17:0] XMUX;
   output wire [17:0] BMULT;

endmodule // DUALB_REG
