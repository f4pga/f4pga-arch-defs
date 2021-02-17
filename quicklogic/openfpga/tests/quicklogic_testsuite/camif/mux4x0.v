module mux4x0_top (A,B,C,D,S1,S0,Q);
input A,B,C,D,S0,S1;
output Q;

 assign Q = S1 ? (S0 ? D : C) : (S0 ? B : A);

endmodule


