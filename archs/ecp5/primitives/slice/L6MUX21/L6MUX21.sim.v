`default_nettype none
module L6MUX21 (input D0, D1, SD, output Z);
	assign Z = SD ? D1 : D0;
endmodule
