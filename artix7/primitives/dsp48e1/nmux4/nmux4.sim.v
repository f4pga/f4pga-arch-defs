`include "../../../../vpr/muxes/logic/mux2/mux2.sim.v"

module MUX4
  (
   I0, I1, I2, I3,
   S,
   O
   );
   input wire I0;
   input wire I1;
   input wire I2;
   input wire I3;

   input [1:0] S;

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

   MUX2 mux0    (.I0(I0), .I1(I1), .S0(S[0]), .O(m0));
   MUX2 mux1    (.I0(I2), .I1(I3), .S0(S[0]), .O(m1));

   MUX2 mux3    (.I0(m0), .I1(m1), .S0(S[1]), .O(O));


endmodule // MUX4


module NMUX4
  (
   I0, I1, I2, I3,
   S,
   O
   );

   parameter NBITS = 4;

   input wire [NBITS-1:0] I0;
   input wire [NBITS-1:0] I1;
   input wire [NBITS-1:0] I2;
   input wire [NBITS-1:0] I3;

   input wire [1:0] 	S;

   output wire [NBITS-1:0] O;

   genvar 		 ii;

   for(ii=0; ii<NBITS; ii++) begin: bitmux
      MUX4 mux (I0[ii], I1[ii], I2[ii], I3[ii], S, O[ii]);
   end

endmodule // NMUX4
