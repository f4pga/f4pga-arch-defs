`include "../../../../../vpr/muxes/logic/mux2/mux2.sim.v"

module NMUX2
  (
   I0, I1,
   S,
   O
   );

   parameter NBITS = 4;

   input wire [NBITS-1:0] I0;
   input wire [NBITS-1:0] I1;

   input wire 		  S;

   output wire [NBITS-1:0] O;

   genvar 		 ii;

   for(ii=0; ii<NBITS; ii++) begin: bitmux
      MUX2 mux (I0[ii], I1[ii], S, O[ii]);
   end

endmodule // NMUX2
