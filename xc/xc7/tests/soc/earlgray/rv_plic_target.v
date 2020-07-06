module rv_plic_target (
	clk_i,
	rst_ni,
	ip,
	ie,
	prio,
	threshold,
	irq,
	irq_id
);
	parameter signed [31:0] N_SOURCE = 32;
	parameter signed [31:0] MAX_PRIO = 7;
	localparam [31:0] SRCW = $clog2(N_SOURCE + 1);
	localparam [31:0] PRIOW = $clog2(MAX_PRIO + 1);
	input clk_i;
	input rst_ni;
	input [N_SOURCE - 1:0] ip;
	input [N_SOURCE - 1:0] ie;
	input [(0 >= (N_SOURCE - 1) ? ((PRIOW - 1) >= 0 ? ((2 - N_SOURCE) * PRIOW) + (((N_SOURCE - 1) * PRIOW) - 1) : ((2 - N_SOURCE) * (2 - PRIOW)) + (((PRIOW - 1) + ((N_SOURCE - 1) * (2 - PRIOW))) - 1)) : ((PRIOW - 1) >= 0 ? (N_SOURCE * PRIOW) + -1 : (N_SOURCE * (2 - PRIOW)) + ((PRIOW - 1) - 1))):(0 >= (N_SOURCE - 1) ? ((PRIOW - 1) >= 0 ? (N_SOURCE - 1) * PRIOW : (PRIOW - 1) + ((N_SOURCE - 1) * (2 - PRIOW))) : ((PRIOW - 1) >= 0 ? 0 : PRIOW - 1))] prio;
	input [PRIOW - 1:0] threshold;
	output wire irq;
	output wire [SRCW - 1:0] irq_id;
	localparam [31:0] N_LEVELS = $clog2(N_SOURCE);
	wire [(2 ** (N_LEVELS + 1)) - 2:0] is_tree;
	wire [(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((SRCW - 1) >= 0 ? ((((2 ** (N_LEVELS + 1)) - 2) + 1) * SRCW) + -1 : ((((2 ** (N_LEVELS + 1)) - 2) + 1) * (2 - SRCW)) + ((SRCW - 1) - 1)) : ((SRCW - 1) >= 0 ? ((3 - (2 ** (N_LEVELS + 1))) * SRCW) + ((((2 ** (N_LEVELS + 1)) - 2) * SRCW) - 1) : ((3 - (2 ** (N_LEVELS + 1))) * (2 - SRCW)) + (((SRCW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - SRCW))) - 1))):(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((SRCW - 1) >= 0 ? 0 : SRCW - 1) : ((SRCW - 1) >= 0 ? ((2 ** (N_LEVELS + 1)) - 2) * SRCW : (SRCW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - SRCW))))] id_tree;
	wire [(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((PRIOW - 1) >= 0 ? ((((2 ** (N_LEVELS + 1)) - 2) + 1) * PRIOW) + -1 : ((((2 ** (N_LEVELS + 1)) - 2) + 1) * (2 - PRIOW)) + ((PRIOW - 1) - 1)) : ((PRIOW - 1) >= 0 ? ((3 - (2 ** (N_LEVELS + 1))) * PRIOW) + ((((2 ** (N_LEVELS + 1)) - 2) * PRIOW) - 1) : ((3 - (2 ** (N_LEVELS + 1))) * (2 - PRIOW)) + (((PRIOW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - PRIOW))) - 1))):(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) : ((PRIOW - 1) >= 0 ? ((2 ** (N_LEVELS + 1)) - 2) * PRIOW : (PRIOW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - PRIOW))))] max_tree;
	generate
		genvar level;
		genvar offset;
		for (level = 0; level < (N_LEVELS + 1); level = level + 1) begin : gen_tree
			localparam [31:0] base0 = (2 ** level) - 1;
			localparam [31:0] base1 = (2 ** (level + 1)) - 1;
			for (offset = 0; offset < (2 ** level); offset = offset + 1) begin : gen_level
				localparam [31:0] pa = base0 + offset;
				localparam [31:0] c0 = base1 + (2 * offset);
				localparam [31:0] c1 = (base1 + (2 * offset)) + 1;
				if (level == N_LEVELS) begin : gen_leafs
					if (offset < N_SOURCE) begin : gen_assign
						assign is_tree[pa] = ip[offset] & ie[offset];
						assign id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)] = offset + 1'b1;
						assign max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)] = prio[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((0 >= (N_SOURCE - 1) ? offset : (N_SOURCE - 1) - offset) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)];
					end
					else begin : gen_tie_off
						assign is_tree[pa] = 1'sb0;
						assign id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)] = 1'sb0;
						assign max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)] = 1'sb0;
					end
				end
				else begin : gen_nodes
					wire sel;
					assign sel = (~is_tree[c0] & is_tree[c1]) | ((is_tree[c0] & is_tree[c1]) & sv2v_cast_1(max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c1 : 0 - (c1 - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)] > max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c0 : 0 - (c0 - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)]));
					assign is_tree[pa] = (sel & is_tree[c1]) | (~sel & is_tree[c0]);
					assign id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)] = ({SRCW {sel}} & id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c1 : 0 - (c1 - ((2 ** (N_LEVELS + 1)) - 2))) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)]) | ({SRCW {~sel}} & id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c0 : 0 - (c0 - ((2 ** (N_LEVELS + 1)) - 2))) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)]);
					assign max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)] = ({PRIOW {sel}} & max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c1 : 0 - (c1 - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)]) | ({PRIOW {~sel}} & max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c0 : 0 - (c0 - ((2 ** (N_LEVELS + 1)) - 2))) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)]);
				end
			end
		end
	endgenerate
	wire irq_d;
	reg irq_q;
	wire [SRCW - 1:0] irq_id_d;
	reg [SRCW - 1:0] irq_id_q;
	assign irq_d = (max_tree[((PRIOW - 1) >= 0 ? 0 : PRIOW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? 0 : (2 ** (N_LEVELS + 1)) - 2) * ((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW))+:((PRIOW - 1) >= 0 ? PRIOW : 2 - PRIOW)] > threshold ? is_tree[0] : 1'b0);
	assign irq_id_d = (is_tree[0] ? id_tree[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? 0 : (2 ** (N_LEVELS + 1)) - 2) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)] : 1'sb0);
	always @(posedge clk_i or negedge rst_ni) begin : gen_regs
		if (!rst_ni) begin
			irq_q <= 1'b0;
			irq_id_q <= 1'sb0;
		end
		else begin
			irq_q <= irq_d;
			irq_id_q <= irq_id_d;
		end
	end
	assign irq = irq_q;
	assign irq_id = irq_id_q;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
endmodule
