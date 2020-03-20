module MULT25X18
  (
   A, B,
   OUT
   );

   input wire [24:0] A;
   input wire [17:0] B;

   output wire [85:0] OUT;

   // TODO(elms): See if there is a way validate the actual partial product split
   assign OUT[42:0] = A * B[8:0];
   assign OUT[85:43] = (A * B[17:9]) << 9;

endmodule // MULT25X18

