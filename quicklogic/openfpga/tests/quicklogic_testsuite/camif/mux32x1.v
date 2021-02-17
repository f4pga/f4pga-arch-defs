module mux32x1 (A,SEL,Q);

input [31:0] A;
input [4:0] SEL;
output Q;

wire [5:0] W;

mux8x0_top M1 (.A(A[0]),.B(A[1]),.C(A[2]),.D(A[3]),.E(A[4]),.F(A[5]),.G(A[6]),.H(A[7]),
               .S0(SEL[2]),.S1(SEL[3]),.S2(SEL[4]),.Q(W[0]));

mux8x0_top M2 (.A(A[8]),.B(A[9]),.C(A[10]),.D(A[11]),.E(A[12]),.F(A[13]),.G(A[14]),.H(A[15]),
               .S0(SEL[2]),.S1(SEL[3]),.S2(SEL[4]),.Q(W[1]));

mux8x0_top M3 (.A(A[16]),.B(A[17]),.C(A[18]),.D(A[19]),.E(A[20]),.F(A[21]),.G(A[22]),.H(A[23]),
               .S0(SEL[2]),.S1(SEL[3]),.S2(SEL[4]),.Q(W[2]));

mux8x0_top M4 (.A(A[24]),.B(A[25]),.C(A[26]),.D(A[27]),.E(A[28]),.F(A[29]),.G(A[30]),.H(A[31]),
               .S0(SEL[2]),.S1(SEL[3]),.S2(SEL[4]),.Q(W[3]));

mux2x0_top M5 (.A(W[0]),.B(W[1]),.S(SEL[1]),.Q(W[4]));

mux2x0_top M6 (.A(W[2]),.B(W[3]),.S(SEL[1]),.Q(W[5]));

mux2x0_top M7 (.A(W[4]),.B(W[5]),.S(SEL[0]),.Q(Q));

endmodule 