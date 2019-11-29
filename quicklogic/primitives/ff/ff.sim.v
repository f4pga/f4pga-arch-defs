(* whitebox *) (* CLASS="flipflop" *)
module FF(clk, D, S, R, E, Q);
	(* PORT_CLASS = "clock" *)
	input clk;
	(* PORT_CLASS = "D" *)
	input D;
	input S;
	input R;
	input E;
	(* PORT_CLASS = "Q" *)
	output reg Q;
	always @(posedge clk or posedge S or posedge R) begin
		if (S)
			Q <= 1'b1;
		else if (R)
			Q <= 1'b0;
		else if (E)
			Q <= D;
	end
endmodule
