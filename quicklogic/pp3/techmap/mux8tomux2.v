// This techmap splits mux8x0 into 7x mux2x0

module mux8x0 (A, B, C, D, E, F, G, H, S0, S1, S2, Q);
    input  A, B, C, D;
    input  E, F, G, H;
    input  S0, S1, S2;
    output Q;

    wire q0;
    wire q1;
    wire q2;
    wire q3;

    wire w0;
    wire w1;

    mux2x0 mux00 (.A(A),  .B(B),  .S(S0), .Q(q0));
    mux2x0 mux01 (.A(C),  .B(D),  .S(S0), .Q(q1));

    mux2x0 mux02 (.A(E),  .B(F),  .S(S0), .Q(q2));
    mux2x0 mux03 (.A(G),  .B(H),  .S(S0), .Q(q3));

    mux2x0 mux10 (.A(q0), .B(q1), .S(S1), .Q(w0));
    mux2x0 mux11 (.A(q2), .B(q3), .S(S1), .Q(w1));

    mux2x0 mux2  (.A(w0), .B(w1), .S(S2), .Q(Q));

endmodule
