`ifndef DSP48_NREG_NREG
`define DSP48_NREG_NREG

`include "reg.sim.v"

module NREG(D, Q, CLK, CE, RESET);
   parameter NBITS = 4;

   input wire [NBITS-1:0] D;
   output reg [NBITS-1:0] Q;
   input wire CLK;
   input wire CE;
   input wire RESET;

   genvar     ii;

   for (ii=0; ii<NBITS; ii++) begin: bitreg
      REG breg (.D(D[ii]), .Q(Q[ii]), .CLK(CLK), .CE(CE), .RESET(RESET));
   end

endmodule // NREG

`endif //  `ifndef DSP48_NREG_NREG
