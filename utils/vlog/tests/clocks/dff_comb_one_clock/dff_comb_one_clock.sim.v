/*
 * `input wire a` should be detected as a clock because it drives the flip
 * flop.
 */
module BLOCK(a, b, c, d);
	input wire a;
	input wire b;
	input wire c;
	output wire d;

	reg r;
        always @ ( posedge a ) begin
                r <= b | ~c;
        end
	assign d = r;
endmodule
