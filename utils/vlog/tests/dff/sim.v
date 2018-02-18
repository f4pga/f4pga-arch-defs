(* blackbox *) (* CLASS="flipflop" *)
module dff(clk, d, q);

(* PORT_CLASS = "clock" *)
input wire clk;

(* PORT_CLASS = "D" *) (* SETUP = "clk 200e-12" *) (* HOLD = "clk 50e-12" *)
input wire d;

(* PORT_CLASS = "Q" *) (* CLK_TO_Q = "clk 400e-12" *)
output wire q;

always @(posedge clk)
		q <= d;

endmodule
