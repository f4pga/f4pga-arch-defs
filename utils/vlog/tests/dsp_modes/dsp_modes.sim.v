`include "../dsp_combinational/dsp_combinational.sim.v"
`include "../dsp_in_registered/dsp_in_registered.sim.v"
`include "../dsp_out_registered/dsp_out_registered.sim.v"
`include "../dsp_inout_registered/dsp_inout_registered.sim.v"
`include "../dsp_partial_registered/dsp_partial_registered.sim.v"

/* DSP Block with register on both the inputs and the output */
(* MODES="REGISTERED_NONE; REGISTERED_IN; REGISTERED_OUT; REGISTERED_INOUT; REGISTERED_PARTIAL" *)
module dsp_modes (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	parameter MODE = "REGISTERED_INOUT";

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Register modes */
	generate
		if (MODE == "REGISTERED_NONE") begin
			dsp_combinational dsp_int_comb (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_IN") begin
			dsp_in_registered dsp_int_regi (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_OUT") begin
			dsp_out_registered dsp_int_rego (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_INOUT") begin
			dsp_inout_registered dsp_int_regio (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_PARTIAL") begin
			dsp_partial_registered dsp_int_part (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end
	endgenerate
endmodule
