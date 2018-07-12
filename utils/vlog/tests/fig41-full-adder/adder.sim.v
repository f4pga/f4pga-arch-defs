module adder (
	a, b, cin,
	sum, cout
);
	input wire a;
	input wire b;
	input wire cin;

	output wire sum;
	output wire cout;

	// Full adder combinational logic
	assign sum = a ^ b ^ cin;
	assign cout = ((a ^ b) & cin) | (a & b);

	// Timing parameters, not supported by Yosys at the moment.
`ifndef YOSYS
	`timescale 1ps/1ps
	specify
		specparam T1 300;
		specparam T2 10;
		// (input->output) min:typ:max

		(a => sum) 	= T1;
		(b => sum)	= T1;
		(cin => sum)	= T1;

		(a => cout)	= T1;
		(b => cout)	= T1;
		(cin => cout)	= T2;

	endspecify
`endif
endmodule

