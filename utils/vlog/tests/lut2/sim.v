(* blackbox *)
module lut2 (
		input [1:0] in,

		(* DELAY_MATRIX_in = "10e-12; 10e-12" *)
		output y);
parameter [3:0] content = 4'b1000;
assign y = content[in];
endmodule
