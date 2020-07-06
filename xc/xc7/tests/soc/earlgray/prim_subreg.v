module prim_subreg (
	clk_i,
	rst_ni,
	we,
	wd,
	de,
	d,
	qe,
	q,
	qs
);
	parameter signed [31:0] DW = 32;
	parameter SWACCESS = "RW";
	parameter [DW - 1:0] RESVAL = 1'sb0;
	input clk_i;
	input rst_ni;
	input we;
	input [DW - 1:0] wd;
	input de;
	input [DW - 1:0] d;
	output reg qe;
	output reg [DW - 1:0] q;
	output wire [DW - 1:0] qs;
	wire wr_en;
	wire [DW - 1:0] wr_data;
	generate
		if ((SWACCESS == "RW") || (SWACCESS == "WO")) begin : gen_w
			assign wr_en = we | de;
			assign wr_data = (we == 1'b1 ? wd : d);
		end
		else if (SWACCESS == "RO") begin : gen_ro
			assign wr_en = de;
			assign wr_data = d;
		end
		else if (SWACCESS == "W1S") begin : gen_w1s
			assign wr_en = we | de;
			assign wr_data = (de ? d : q) | (we ? wd : 1'sb0);
		end
		else if (SWACCESS == "W1C") begin : gen_w1c
			assign wr_en = we | de;
			assign wr_data = (de ? d : q) & (we ? ~wd : 1'sb1);
		end
		else if (SWACCESS == "W0C") begin : gen_w0c
			assign wr_en = we | de;
			assign wr_data = (de ? d : q) & (we ? wd : 1'sb1);
		end
		else if (SWACCESS == "RC") begin : gen_rc
			assign wr_en = we | de;
			assign wr_data = (de ? d : q) & (we ? 1'sb0 : 1'sb1);
		end
		else begin : gen_hw
			assign wr_en = de;
			assign wr_data = d;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			qe <= 1'b0;
		else
			qe <= we;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			q <= RESVAL;
		else if (wr_en)
			q <= wr_data;
	assign qs = q;
endmodule
