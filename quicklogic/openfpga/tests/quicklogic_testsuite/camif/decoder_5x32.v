module decoder_5x32 (A,Q);

input [4:0] A;
output [31:0] Q;
wire [3:0] w;

 
     decoder_2x4 d1 (.A(A[4:3]),.Y(w[3:0]));
     decoder_3x8 d2 (.b(A[2:0]),.en(w[0]),.y(Q[7:0]));
     decoder_3x8 d3 (.b(A[2:0]),.en(w[1]),.y(Q[15:8]));
     decoder_3x8 d4 (.b(A[2:0]),.en(w[2]),.y(Q[23:16]));
     decoder_3x8 d5 (.b(A[2:0]),.en(w[3]),.y(Q[31:24]));
    

endmodule 
