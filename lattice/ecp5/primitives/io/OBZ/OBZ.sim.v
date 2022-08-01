`default_nettype none
module OBZ(input I, T, output O);
assign O = T ? 1'bz : I;
endmodule
