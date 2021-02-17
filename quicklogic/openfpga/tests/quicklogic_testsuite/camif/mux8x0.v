module mux8x0_top(A,B,C,D,E,F,G,H,S0,S1,S2,Q);

input A,B,C,D,E,F,G,H,S0,S1,S2;
output Q;

mux4x0_top M1 (.A(A),.B(B),.C(C),.D(D),.S1(S1),.S0(S0),.Q(m1_out));
mux4x0_top M2 (.A(E),.B(F),.C(G),.D(H),.S1(S1),.S0(S0),.Q(m2_out));
mux2x0_top M3 (.A(m1_out),.B(m2_out),.S(S2),.Q(Q));

endmodule

