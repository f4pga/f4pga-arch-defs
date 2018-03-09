// DSP48E1
// [1] 7 Series DSP48E1 User Guide UG479 (v1.9) September 27, 2016

// Figure 2-7 shows details
module DUAL_AD_PREADDER
  (
   A, ACIN, D,
   ACOUT, XMUX, AMULT
   );

   input wire [29:0] A;
   input wire [29:0] ACIN;
   input wire [24:0] D;

   output wire [29:0] ACOUT;
   output wire [29:0] XMUX;
   output wire [24:0] AMULT;

endmodule // DUAL_AD_PREADDER

// Table 2-5 defines behavior
