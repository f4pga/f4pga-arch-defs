module BLOCK(c1, c2, a, b, c, o1, o2);
	input wire c1;
	input wire c2;
	input wire a;
	input wire b;
	input wire c;
	output wire o1;
	output wire o2;

	reg r1;
	reg r2;
        always @ ( posedge c1 ) begin
                r1 <= a | b;
        end
        always @ ( posedge c2 ) begin
                r2 <= b | c;
        end

	assign o1 = r1;
	assign o2 = r2;
endmodule
