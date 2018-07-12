`include "../dsp_in_registered/dsp_regi.sim.v"
`include "../dsp_out_registered/dsp_rego.sim.v"
`include "../dsp_inout_registered/dsp_regio.sim.v"

/* DSP Block with register on both the inputs and the output */
(* MODES="REGISTERED_IN; REGISTERED_OUT; REGISTERED_INOUT" *)
module dsp_modes (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	parameter MODE = "REGISTERED_INOUT";

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Input registers */
	generate
		if (MODE == "REGISTERED_IN") begin
			dsp_regi dsp_int_regi (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_OUT") begin
			dsp_rego dsp_int_rego (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end if (MODE == "REGISTERED_INOUT") begin
			dsp_regio dsp_int_regio (.clk(clk), .a(a), .b(b), .m(m), .out(out));
		end
	endgenerate
endmodule
