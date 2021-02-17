module adder_columns(cout,sum,a,b,cin);

input [507:0]a,b;
output [507:0]sum;
input [1:0]cin;
output [1:0]cout;

adder_max ad1(.a(a[253:0]),.b(b[253:0]),.cin(cin[0]),.sum(sum[253:0]),.cout(cout[0]));
adder_max ad2(.a(a[507:254]),.b(b[507:254]),.cin(cin[1]),.sum(sum[507:254]),.cout(cout[1]));

endmodule



module adder_max(cout, sum, a, b, cin);
parameter size = 254;  /* declare a parameter. default required */
output cout;
output [size-1:0] sum; 	 // sum uses the size parameter
input cin;
input [size-1:0] a, b;  // 'a' and 'b' use the size parameter

assign {cout, sum} = a + b + cin;

endmodule









