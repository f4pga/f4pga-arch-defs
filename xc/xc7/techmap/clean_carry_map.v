// Output CO directly
module CARRY_CO_DIRECT(input CO, input O, input S, output OUT);

assign OUT = CO;

endmodule

// Compute CO from O and S
module CARRY_CO_LUT(input CO, input O, input S, output OUT);

LUT2 #(.INIT(4'b0110)) xor_lut (.I0(O), .I1(S), .O(OUT));

endmodule
