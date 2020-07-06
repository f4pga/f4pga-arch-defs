module prim_xilinx_pad_wrapper (
	inout_io,
	in_o,
	out_i,
	oe_i,
	attr_i
);
	parameter [31:0] AttrDw = 2;
	inout wire inout_io;
	output wire in_o;
	input out_i;
	input oe_i;
	input [AttrDw - 1:0] attr_i;
	wire od;
	wire inv;
	assign {od, inv} = attr_i[1:0];
	assign in_o = inv ^ inout_io;
	wire oe;
	wire out;
	assign out = out_i ^ inv;
	assign oe = oe_i & ((od & ~out) | ~od);
	assign inout_io = (oe ? out : 1'bz);
endmodule
