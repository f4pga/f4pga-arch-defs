module prim_arbiter_tree (
	clk_i,
	rst_ni,
	req_i,
	data_i,
	gnt_o,
	idx_o,
	valid_o,
	data_o,
	ready_i
);
	parameter [31:0] N = 4;
	parameter [31:0] DW = 32;
	parameter Lock = 1'b1;
	input clk_i;
	input rst_ni;
	input [N - 1:0] req_i;
	input [(0 >= (N - 1) ? ((DW - 1) >= 0 ? ((2 - N) * DW) + (((N - 1) * DW) - 1) : ((2 - N) * (2 - DW)) + (((DW - 1) + ((N - 1) * (2 - DW))) - 1)) : ((DW - 1) >= 0 ? (N * DW) + -1 : (N * (2 - DW)) + ((DW - 1) - 1))):(0 >= (N - 1) ? ((DW - 1) >= 0 ? (N - 1) * DW : (DW - 1) + ((N - 1) * (2 - DW))) : ((DW - 1) >= 0 ? 0 : DW - 1))] data_i;
	output wire [N - 1:0] gnt_o;
	output wire [$clog2(N) - 1:0] idx_o;
	output wire valid_o;
	output wire [DW - 1:0] data_o;
	input ready_i;
	generate
		genvar level;
		genvar offset;
		if (N == 1) begin : gen_degenerate_case
			assign valid_o = req_i[0];
			assign data_o = data_i[((DW - 1) >= 0 ? 0 : DW - 1) + ((0 >= (N - 1) ? 0 : N - 1) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)];
			assign gnt_o[0] = valid_o & ready_i;
			assign idx_o = 1'sb0;
		end
		else begin : gen_normal_case
			localparam [31:0] N_LEVELS = $clog2(N);
			wire [N - 1:0] req;
			wire [(2 ** (N_LEVELS + 1)) - 2:0] req_tree;
			wire [(2 ** (N_LEVELS + 1)) - 2:0] gnt_tree;
			wire [(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((N_LEVELS - 1) >= 0 ? ((((2 ** (N_LEVELS + 1)) - 2) + 1) * N_LEVELS) + -1 : ((((2 ** (N_LEVELS + 1)) - 2) + 1) * (2 - N_LEVELS)) + ((N_LEVELS - 1) - 1)) : ((N_LEVELS - 1) >= 0 ? ((3 - (2 ** (N_LEVELS + 1))) * N_LEVELS) + ((((2 ** (N_LEVELS + 1)) - 2) * N_LEVELS) - 1) : ((3 - (2 ** (N_LEVELS + 1))) * (2 - N_LEVELS)) + (((N_LEVELS - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - N_LEVELS))) - 1))):(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) : ((N_LEVELS - 1) >= 0 ? ((2 ** (N_LEVELS + 1)) - 2) * N_LEVELS : (N_LEVELS - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - N_LEVELS))))] idx_tree;
			wire [(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((DW - 1) >= 0 ? ((((2 ** (N_LEVELS + 1)) - 2) + 1) * DW) + -1 : ((((2 ** (N_LEVELS + 1)) - 2) + 1) * (2 - DW)) + ((DW - 1) - 1)) : ((DW - 1) >= 0 ? ((3 - (2 ** (N_LEVELS + 1))) * DW) + ((((2 ** (N_LEVELS + 1)) - 2) * DW) - 1) : ((3 - (2 ** (N_LEVELS + 1))) * (2 - DW)) + (((DW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - DW))) - 1))):(((2 ** (N_LEVELS + 1)) - 2) >= 0 ? ((DW - 1) >= 0 ? 0 : DW - 1) : ((DW - 1) >= 0 ? ((2 ** (N_LEVELS + 1)) - 2) * DW : (DW - 1) + (((2 ** (N_LEVELS + 1)) - 2) * (2 - DW))))] data_tree;
			reg [N_LEVELS - 1:0] rr_q;
			if (Lock) begin : gen_lock
				wire [N - 1:0] mask_d;
				reg [N - 1:0] mask_q;
				assign mask_d = (valid_o && !ready_i ? req : {N {1'b1}});
				assign req = mask_q & req_i;
				always @(posedge clk_i) begin : p_lock_regs
					if (!rst_ni)
						mask_q <= {N {1'b1}};
					else
						mask_q <= mask_d;
				end
			end
			else begin : gen_no_lock
				assign req = req_i;
			end
			for (level = 0; level < (N_LEVELS + 1); level = level + 1) begin : gen_tree
				localparam [31:0] base0 = (2 ** level) - 1;
				localparam [31:0] base1 = (2 ** (level + 1)) - 1;
				for (offset = 0; offset < (2 ** level); offset = offset + 1) begin : gen_level
					localparam [31:0] pa = base0 + offset;
					localparam [31:0] c0 = base1 + (2 * offset);
					localparam [31:0] c1 = (base1 + (2 * offset)) + 1;
					if (level == N_LEVELS) begin : gen_leafs
						if (offset < N) begin : gen_assign
							assign req_tree[pa] = req[offset];
							assign idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)] = offset;
							assign data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)] = data_i[((DW - 1) >= 0 ? 0 : DW - 1) + ((0 >= (N - 1) ? offset : (N - 1) - offset) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)];
							assign gnt_o[offset] = gnt_tree[pa];
						end
						else begin : gen_tie_off
							assign req_tree[pa] = 1'sb0;
							assign idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)] = 1'sb0;
							assign data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)] = 1'sb0;
						end
					end
					else begin : gen_nodes
						wire sel;
						assign sel = ~req_tree[c0] | (req_tree[c1] & rr_q[(N_LEVELS - 1) - level]);
						assign req_tree[pa] = req_tree[c0] | req_tree[c1];
						assign idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)] = ({N_LEVELS {sel}} & idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c1 : 0 - (c1 - ((2 ** (N_LEVELS + 1)) - 2))) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)]) | ({N_LEVELS {~sel}} & idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c0 : 0 - (c0 - ((2 ** (N_LEVELS + 1)) - 2))) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)]);
						assign data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? pa : 0 - (pa - ((2 ** (N_LEVELS + 1)) - 2))) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)] = ({DW {sel}} & data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c1 : 0 - (c1 - ((2 ** (N_LEVELS + 1)) - 2))) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)]) | ({DW {~sel}} & data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? c0 : 0 - (c0 - ((2 ** (N_LEVELS + 1)) - 2))) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)]);
						assign gnt_tree[c0] = gnt_tree[pa] & ~sel;
						assign gnt_tree[c1] = gnt_tree[pa] & sel;
					end
				end
			end
			assign idx_o = idx_tree[((N_LEVELS - 1) >= 0 ? 0 : N_LEVELS - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? 0 : (2 ** (N_LEVELS + 1)) - 2) * ((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS))+:((N_LEVELS - 1) >= 0 ? N_LEVELS : 2 - N_LEVELS)];
			assign data_o = data_tree[((DW - 1) >= 0 ? 0 : DW - 1) + ((((2 ** (N_LEVELS + 1)) - 2) >= 0 ? 0 : (2 ** (N_LEVELS + 1)) - 2) * ((DW - 1) >= 0 ? DW : 2 - DW))+:((DW - 1) >= 0 ? DW : 2 - DW)];
			assign valid_o = req_tree[0];
			assign gnt_tree[0] = valid_o & ready_i;
			always @(posedge clk_i or negedge rst_ni) begin : p_regs
				if (!rst_ni)
					rr_q <= 1'sb0;
				else if (gnt_tree[0] && (rr_q == (N - 1)))
					rr_q <= 1'sb0;
				else if (gnt_tree[0])
					rr_q <= rr_q + 1'b1;
			end
		end
	endgenerate
endmodule
