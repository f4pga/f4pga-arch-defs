`include "../../../../vpr/muxes/logic/mux4/mux4.sim.v"

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
      MUX4 mux (I0[ii], I1[ii], I2[ii], I3[ii], S[1], S[0], O[ii]);
   end

endmodule // NMUX4
