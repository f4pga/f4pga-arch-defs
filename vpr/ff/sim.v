(* blackbox *) (* CLASS="flipflop" *)
module VPR_FF (D, Q, clk);

(* PORT_CLASS = "D" *)
(* SETUP = "clk 0.301e-9" *)
input wire D;

(* PORT_CLASS = "Q" *)
(* CLK_TO_Q = "clk 0.301e-9" *)
output reg Q;

(* PORT_CLASS = "clock" *)
input wire clk;

always @ ( posedge clk ) begin
	Q <= D;
end

endmodule
