(* blackbox *) (* CLASS="flipflop" *)
module FF(clk, D, Q);

	(* PORT_CLASS = "clock" *)
	input wire clk;

	(* PORT_CLASS = "D" *) (* SETUP = "clk 10e-12" *)
	input wire D;

	(* PORT_CLASS = "Q" *) (* CLK_TO_Q = "clk 10e-12" *)
	output wire Q;

	always @(posedge clk)
		Q <= D;

endmodule
