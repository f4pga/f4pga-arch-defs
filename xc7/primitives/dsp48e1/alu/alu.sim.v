module ALU
  (X, Y, Z,
   ALUMODE,
   CARRYIN,
   MULTSIGNIN,
   OUT,
   CARRYOUT,
   MULTSIGNOUT
   );

   input wire [47:0] X;
   input wire [47:0] Y;
   input wire [47:0] Z;
   input wire [3:0]  ALUMODE;
   input wire 	     CARRYIN;
   input wire 	     MULTSIGNIN;

   output wire [47:0] OUT;
   output wire [3:0]  CARRYOUT;
   output wire 	      MULTSIGNOUT;

endmodule // ALU



