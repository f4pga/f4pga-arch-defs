// This techmap splits mux4x0 into 3x mux2x0

module mux4x0 (A, B, C, D, S0, S1, Q);
    input  A, B, C, D;
    input  S0, S1;
    output Q;

    wire q0;
    wire q1;

    mux2x0 mux0 (.A(A),  .B(B),  .S(S0), .Q(q0));
    mux2x0 mux1 (.A(C),  .B(D),  .S(S0), .Q(q1));

    mux2x0 mux2 (.A(q0), .B(q1), .S(S1), .Q(Q));

endmodule
