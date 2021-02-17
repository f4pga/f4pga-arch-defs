module multiplier_8bit (prod,a_in,b_in);

output [15:0] prod;
input [7:0] a_in, b_in;

assign prod = a_in * b_in;

endmodule 