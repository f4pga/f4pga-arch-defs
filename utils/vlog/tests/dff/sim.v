(* TYPE="bel" *) (* CLASS="flipflop" *)
module dff(clk, rst, d, q);

input wire clk;
input wire rst;

(* SETUP = "clk 200e-12" *) (* HOLD = "clk 50e-12" *)
input wire d;

(* CLK_TO_Q = "clk 400e-12" *)
output wire q;

always @(posedge clk)
	if (rst == 1'b1)
		q <= 1'b0;
	else
		q <= d;

endmodule
