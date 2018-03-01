`include "../../../../vpr/muxes/logic/mux2/sim.v"

module MUX7
  (
   I0, I1, I2, I3, I4, I5, I6,
   S,
   O
   );
   input wire I0;
   input wire I1;
   input wire I2;
   input wire I3;
   input wire I4;
   input wire I5;
   input wire I6;

   input [2:0] S;

   output wire O;

   // wire        temp;
   // always
   // case (S)
   //   0: assign temp = I0;
   //   1: assign temp = I1;
   //   2: assign temp = I2;
   //   3: assign temp = I3;
   // endcase // case (S)

   // assign O = temp;


   wire        m0;
   wire        m1;
   wire        m2;

   wire        n0;
   wire        n1;

   MUX2 mux0    (.I0(I0), .I1(I1), .S0(S[0]), .O(m0));
   MUX2 mux1    (.I0(I2), .I1(I3), .S0(S[0]), .O(m1));
   MUX2 mux2    (.I0(I4), .I1(I5), .S0(S[0]), .O(m2));


   MUX2 mux3    (.I0(m0), .I1(m1), .S0(S[1]), .O(n0));
   MUX2 mux4    (.I0(m2), .I1(I6), .S0(S[1]), .O(n1));

   MUX2 mux5    (.I0(n0), .I1(n1), .S0(S[1]), .O(O));

endmodule // MUX7


module NMUX7
  (
   I0, I1, I2, I3, I4, I5, I6,
   S,
   O
   );

   parameter NBITS = 4;

   input wire [NBITS-1:0] I0;
   input wire [NBITS-1:0] I1;
   input wire [NBITS-1:0] I2;
   input wire [NBITS-1:0] I3;
   input wire [NBITS-1:0] I4;
   input wire [NBITS-1:0] I5;
   input wire [NBITS-1:0] I6;

   input wire [2:0] 	  S;

   output wire [NBITS-1:0] O;

   genvar 		 ii;

   for(ii=0; ii<NBITS; ii++) begin: bitmux
      MUX7 mux (I0[ii], I1[ii], I2[ii], I3[ii], I4[ii], I5[ii], I6[ii], S, O[ii]);
   end

endmodule // NMUX6
