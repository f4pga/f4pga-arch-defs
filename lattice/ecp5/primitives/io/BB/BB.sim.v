`default_nettype none
module BB(input I, T, output O, inout B);
assign B = T ? 1'bz : I;
assign O = B;
endmodule
