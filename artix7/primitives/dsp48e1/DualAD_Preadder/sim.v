module DUALAD_PREADDER
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

endmodule // DUALAD_PREADDER

