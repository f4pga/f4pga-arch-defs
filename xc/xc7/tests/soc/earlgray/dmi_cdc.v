module dmi_cdc (
	tck_i,
	trst_ni,
	jtag_dmi_req_i,
	jtag_dmi_ready_o,
	jtag_dmi_valid_i,
	jtag_dmi_resp_o,
	jtag_dmi_valid_o,
	jtag_dmi_ready_i,
	clk_i,
	rst_ni,
	core_dmi_req_o,
	core_dmi_valid_o,
	core_dmi_ready_i,
	core_dmi_resp_i,
	core_dmi_ready_o,
	core_dmi_valid_i
);
	input wire tck_i;
	input wire trst_ni;
	input wire [40:0] jtag_dmi_req_i;
	output wire jtag_dmi_ready_o;
	input wire jtag_dmi_valid_i;
	output wire [33:0] jtag_dmi_resp_o;
	output wire jtag_dmi_valid_o;
	input wire jtag_dmi_ready_i;
	input wire clk_i;
	input wire rst_ni;
	output wire [40:0] core_dmi_req_o;
	output wire core_dmi_valid_o;
	input wire core_dmi_ready_i;
	input wire [33:0] core_dmi_resp_i;
	output wire core_dmi_ready_o;
	input wire core_dmi_valid_i;
	prim_fifo_async #(
		.Width(41),
		.Depth(4)
	) i_cdc_req(
		.clk_wr_i(tck_i),
		.rst_wr_ni(trst_ni),
		.wvalid(jtag_dmi_valid_i),
		.wready(jtag_dmi_ready_o),
		.wdata(jtag_dmi_req_i),
		.wdepth(),
		.clk_rd_i(clk_i),
		.rst_rd_ni(rst_ni),
		.rvalid(core_dmi_valid_o),
		.rready(core_dmi_ready_i),
		.rdata(core_dmi_req_o),
		.rdepth()
	);
	prim_fifo_async #(
		.Width(34),
		.Depth(4)
	) i_cdc_resp(
		.clk_wr_i(clk_i),
		.rst_wr_ni(rst_ni),
		.wvalid(core_dmi_valid_i),
		.wready(core_dmi_ready_o),
		.wdata(core_dmi_resp_i),
		.wdepth(),
		.clk_rd_i(tck_i),
		.rst_rd_ni(trst_ni),
		.rvalid(jtag_dmi_valid_o),
		.rready(jtag_dmi_ready_i),
		.rdata(jtag_dmi_resp_o),
		.rdepth()
	);
endmodule
