module DUALB_REG
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
