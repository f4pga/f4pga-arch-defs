/*
 * `input wire a` should be detected as a clock because it drives the flip
 * flop.
 */
module BLOCK(a, b, c);
	input wire a;
	input wire b;
	output wire c;

	reg r;
	always @ ( posedge a ) begin
		r <= b;
	end
	assign c = r;
endmodule
