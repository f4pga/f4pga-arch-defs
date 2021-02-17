module mux2x0_top (A,B,S,Q); 
input A,B,S;
output Q;

assign Q= (S)? A: B;

endmodule


