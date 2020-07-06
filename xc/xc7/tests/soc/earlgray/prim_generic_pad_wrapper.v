module prim_generic_pad_wrapper (
	inout_io,
	in_o,
	out_i,
	oe_i,
	attr_i
);
	localparam [0:0] STRONG_DRIVE = 1'b0;
	localparam [0:0] WEAK_DRIVE = 1'b1;
	parameter [31:0] AttrDw = 6;
	inout wire inout_io;
	output wire in_o;
	input out_i;
	input oe_i;
	input [AttrDw - 1:0] attr_i;
	wire kp;
	wire pu;
	wire pd;
	wire od;
	wire inv;
	wire [0:0] drv;
	assign {drv, kp, pu, pd, od, inv} = attr_i[5:0];
	assign in_o = inv ^ inout_io;
	wire oe;
	wire out;
	assign out = out_i ^ inv;
	assign oe = oe_i & ((od & ~out) | ~od);
	assign  inout_io = (oe && (drv == STRONG_DRIVE) ? out : 1'bz);
	assign  inout_io = (oe && (drv == WEAK_DRIVE) ? out : 1'bz);
	assign  inout_io = pu;
	assign  inout_io = ~pd;
	assign  inout_io = (kp ? inout_io : 1'bz);
endmodule
