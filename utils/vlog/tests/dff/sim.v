(* TYPE="bel" *) (* CLASS="flipflop" *)
module dff(clk, rst, d, q);

(* PORT_CLASS = "clock" *)
input wire clk;

(* SETUP = "clk 200e-12" *) (* HOLD = "clk 50e-12" *)
input wire rst;

(* PORT_CLASS = "D" *) (* SETUP = "clk 200e-12" *) (* HOLD = "clk 50e-12" *)
input wire d;

(* PORT_CLASS = "Q" *) (* CLK_TO_Q = "clk 400e-12" *)
output wire q;

always @(posedge clk)
	if (rst == 1'b1)
		q <= 1'b0;
	else
		q <= d;

endmodule
