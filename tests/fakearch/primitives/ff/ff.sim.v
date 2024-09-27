module FF(clk, D, Q);

	(* PORT_CLASS = "clock" *)
	input clk;

	(* PORT_CLASS = "D" *) (* SETUP = "clk 10e-12" *)
	input D;

	(* PORT_CLASS = "Q" *) (* CLK_TO_Q = "clk 10e-12" *)
	output reg Q;

	always @(posedge clk)
		Q <= D;

endmodule
