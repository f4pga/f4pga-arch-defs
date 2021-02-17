
module ff_lut4_1000(qck, qrt,c, d_out);
   // Port Declaration
   input   qck;
   input [0:999]c;
   input  qrt;
   output  [0:999]d_out;
wire [0:999]d_out_w;
genvar i;
generate for (i = 0; i < 1000; i = i + 1) begin
   D_ff dut1(.D(c[i]),.QCK(qck),.QRT(qrt),.CQZ(d_out_w[i]));
   lut_4 L1(.a(d_out_w[i]),.b(c[i]),.c(qrt),.d(c[i]),.Q(d_out[i]));
  
end endgenerate
endmodule


module D_ff(input QCK,QRT,D, output CQZ);

always @ (posedge QCK or posedge QRT)

begin
if(QRT)
	CQZ <= 1'b1;
else
CQZ <= D;
end
endmodule

module lut_4(input a, b, c, d, output Q);

assign Q =a ^b ^ c ^d;

endmodule
