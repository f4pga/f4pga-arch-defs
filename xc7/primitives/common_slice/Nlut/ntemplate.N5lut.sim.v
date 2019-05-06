(* blackbox *)  (* CLASS="lut" *)
module {N}5LUT(in, out);

	(* PORT_CLASS = "lut_in" *)
	input wire [4:0] in;

	(* PORT_CLASS = "lut_out" *)
	(* DELAY_MATRIX_in = "1e-11; 1e-11; 1e-11; 1e-11; 1e-11;"/*"{{iopath_A1_O5}}; {{iopath_A2_O5}}; {{iopath_A3_O5}}; {{iopath_A4_O5}}; {{iopath_A5_O5}};"*/ *)
	output wire out;

	parameter [63:0] INIT = 0;

	wire [15: 0] lower_s4 = in[4] ?       INIT[31:16] :     INIT[15: 0];
	wire [ 7: 0] lower_s3 = in[3] ?   lower_s4[15: 8] : lower_s4[ 7: 0];
	wire [ 3: 0] lower_s2 = in[2] ?   lower_s3[ 7: 4] : lower_s3[ 3: 0];
	wire [ 1: 0] lower_s1 = in[1] ?   lower_s2[ 3: 2] : lower_s2[ 1: 0];
	wire         lower_O  = in[0] ?   lower_s1[    1] : lower_s1[    0];
	assign out = lower_O;

endmodule
