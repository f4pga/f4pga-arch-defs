module rv_dm (
	clk_i,
	rst_ni,
	testmode_i,
	ndmreset_o,
	dmactive_o,
	debug_req_o,
	unavailable_i,
	tl_d_i,
	tl_d_o,
	tl_h_o,
	tl_h_i,
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o,
	tdo_oe_o
);
	localparam [11:0] dm_DataAddr = 12'h380;
	localparam [3:0] dm_DataCount = 4'h2;
	localparam [4:0] dm_ProgBufSize = 5'h8;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter signed [31:0] NrHarts = 1;
	parameter [31:0] IdcodeValue = 32'h 0000_0001;
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	output wire ndmreset_o;
	output wire dmactive_o;
	output wire [NrHarts - 1:0] debug_req_o;
	input wire [NrHarts - 1:0] unavailable_i;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_d_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_d_o;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_h_o;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_h_i;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output wire td_o;
	output wire tdo_oe_o;
	localparam signed [31:0] BusWidth = 32;
	localparam [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	wire [((NrHarts - 1) >= 0 ? (NrHarts * 32) + -1 : ((2 - NrHarts) * 32) + (((NrHarts - 1) * 32) - 1)):((NrHarts - 1) >= 0 ? 0 : (NrHarts - 1) * 32)] hartinfo;
	wire [NrHarts - 1:0] halted;
	wire [NrHarts - 1:0] resumeack;
	wire [NrHarts - 1:0] haltreq;
	wire [NrHarts - 1:0] resumereq;
	wire clear_resumeack;
	wire cmd_valid;
	wire [31:0] cmd;
	wire cmderror_valid;
	wire [2:0] cmderror;
	wire cmdbusy;
	wire [((dm_ProgBufSize - 1) >= 0 ? (dm_ProgBufSize * 32) + -1 : ((2 - dm_ProgBufSize) * 32) + (((dm_ProgBufSize - 1) * 32) - 1)):((dm_ProgBufSize - 1) >= 0 ? 0 : (dm_ProgBufSize - 1) * 32)] progbuf;
	wire [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_csrs_mem;
	wire [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_mem_csrs;
	wire data_valid;
	wire [19:0] hartsel;
	wire [BusWidth - 1:0] sbaddress_csrs_sba;
	wire [BusWidth - 1:0] sbaddress_sba_csrs;
	wire sbaddress_write_valid;
	wire sbreadonaddr;
	wire sbautoincrement;
	wire [2:0] sbaccess;
	wire sbreadondata;
	wire [BusWidth - 1:0] sbdata_write;
	wire sbdata_read_valid;
	wire sbdata_write_valid;
	wire [BusWidth - 1:0] sbdata_read;
	wire sbdata_valid;
	wire sbbusy;
	wire sberror_valid;
	wire [2:0] sberror;
	wire [40:0] dmi_req;
	wire [33:0] dmi_rsp;
	wire dmi_req_valid;
	wire dmi_req_ready;
	wire dmi_rsp_valid;
	wire dmi_rsp_ready;
	wire dmi_rst_n;
	localparam [31:0] DebugHartInfo = sv2v_struct_D8B87(1'sb0, 2, 0, 1'b1, dm_DataCount, dm_DataAddr);
	generate
		genvar i;
		for (i = 0; i < NrHarts; i = i + 1) begin : gen_dm_hart_ctrl
			assign hartinfo[((NrHarts - 1) >= 0 ? i : 0 - (i - (NrHarts - 1))) * 32+:32] = DebugHartInfo;
		end
	endgenerate
	dm_csrs #(
		.NrHarts(NrHarts),
		.BusWidth(BusWidth),
		.SelectableHarts(SelectableHarts)
	) i_dm_csrs(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.testmode_i(testmode_i),
		.dmi_rst_ni(dmi_rst_n),
		.dmi_req_valid_i(dmi_req_valid),
		.dmi_req_ready_o(dmi_req_ready),
		.dmi_req_i(dmi_req),
		.dmi_resp_valid_o(dmi_rsp_valid),
		.dmi_resp_ready_i(dmi_rsp_ready),
		.dmi_resp_o(dmi_rsp),
		.ndmreset_o(ndmreset_o),
		.dmactive_o(dmactive_o),
		.hartsel_o(hartsel),
		.hartinfo_i(hartinfo),
		.halted_i(halted),
		.unavailable_i(unavailable_i),
		.resumeack_i(resumeack),
		.haltreq_o(haltreq),
		.resumereq_o(resumereq),
		.clear_resumeack_o(clear_resumeack),
		.cmd_valid_o(cmd_valid),
		.cmd_o(cmd),
		.cmderror_valid_i(cmderror_valid),
		.cmderror_i(cmderror),
		.cmdbusy_i(cmdbusy),
		.progbuf_o(progbuf),
		.data_i(data_mem_csrs),
		.data_valid_i(data_valid),
		.data_o(data_csrs_mem),
		.sbaddress_o(sbaddress_csrs_sba),
		.sbaddress_i(sbaddress_sba_csrs),
		.sbaddress_write_valid_o(sbaddress_write_valid),
		.sbreadonaddr_o(sbreadonaddr),
		.sbautoincrement_o(sbautoincrement),
		.sbaccess_o(sbaccess),
		.sbreadondata_o(sbreadondata),
		.sbdata_o(sbdata_write),
		.sbdata_read_valid_o(sbdata_read_valid),
		.sbdata_write_valid_o(sbdata_write_valid),
		.sbdata_i(sbdata_read),
		.sbdata_valid_i(sbdata_valid),
		.sbbusy_i(sbbusy),
		.sberror_valid_i(sberror_valid),
		.sberror_i(sberror)
	);
	wire master_req;
	wire [BusWidth - 1:0] master_add;
	wire master_we;
	wire [BusWidth - 1:0] master_wdata;
	wire [(BusWidth / 8) - 1:0] master_be;
	wire master_gnt;
	wire master_r_valid;
	wire [BusWidth - 1:0] master_r_rdata;
	dm_sba #(.BusWidth(BusWidth)) i_dm_sba(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.master_req_o(master_req),
		.master_add_o(master_add),
		.master_we_o(master_we),
		.master_wdata_o(master_wdata),
		.master_be_o(master_be),
		.master_gnt_i(master_gnt),
		.master_r_valid_i(master_r_valid),
		.master_r_rdata_i(master_r_rdata),
		.dmactive_i(dmactive_o),
		.sbaddress_i(sbaddress_csrs_sba),
		.sbaddress_o(sbaddress_sba_csrs),
		.sbaddress_write_valid_i(sbaddress_write_valid),
		.sbreadonaddr_i(sbreadonaddr),
		.sbautoincrement_i(sbautoincrement),
		.sbaccess_i(sbaccess),
		.sbreadondata_i(sbreadondata),
		.sbdata_i(sbdata_write),
		.sbdata_read_valid_i(sbdata_read_valid),
		.sbdata_write_valid_i(sbdata_write_valid),
		.sbdata_o(sbdata_read),
		.sbdata_valid_o(sbdata_valid),
		.sbbusy_o(sbbusy),
		.sberror_valid_o(sberror_valid),
		.sberror_o(sberror)
	);
	tlul_adapter_host #(
		.AW(BusWidth),
		.DW(BusWidth)
	) tl_adapter_host_sba(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.req_i(master_req),
		.gnt_o(master_gnt),
		.addr_i(master_add),
		.we_i(master_we),
		.wdata_i(master_wdata),
		.be_i(master_be),
		.size_i(sbaccess[1:0]),
		.valid_o(master_r_valid),
		.rdata_o(master_r_rdata),
		.tl_o(tl_h_o),
		.tl_i(tl_h_i)
	);
	localparam [31:0] AddressWidthWords = BusWidth - 2;
	wire req;
	wire we;
	wire [(BusWidth / 8) - 1:0] be;
	wire [BusWidth - 1:0] wdata;
	wire [BusWidth - 1:0] rdata;
	reg rvalid;
	wire [BusWidth - 1:0] addr_b;
	wire [AddressWidthWords - 1:0] addr_w;
	assign be = {BusWidth / 8 {1'b1}};
	assign addr_b = {addr_w, {2 {1'b0}}};
	dm_mem #(
		.NrHarts(NrHarts),
		.BusWidth(BusWidth),
		.SelectableHarts(SelectableHarts)
	) i_dm_mem(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.debug_req_o(debug_req_o),
		.hartsel_i(hartsel),
		.haltreq_i(haltreq),
		.resumereq_i(resumereq),
		.clear_resumeack_i(clear_resumeack),
		.halted_o(halted),
		.resuming_o(resumeack),
		.cmd_valid_i(cmd_valid),
		.cmd_i(cmd),
		.cmderror_valid_o(cmderror_valid),
		.cmderror_o(cmderror),
		.cmdbusy_o(cmdbusy),
		.progbuf_i(progbuf),
		.data_i(data_csrs_mem),
		.data_o(data_mem_csrs),
		.data_valid_o(data_valid),
		.req_i(req),
		.we_i(we),
		.addr_i(addr_b),
		.wdata_i(wdata),
		.be_i(be),
		.rdata_o(rdata)
	);
	dmi_jtag #(.IdcodeValue(IdcodeValue)) dap(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.testmode_i(testmode_i),
		.dmi_rst_no(dmi_rst_n),
		.dmi_req_o(dmi_req),
		.dmi_req_valid_o(dmi_req_valid),
		.dmi_req_ready_i(dmi_req_ready),
		.dmi_resp_i(dmi_rsp),
		.dmi_resp_ready_o(dmi_rsp_ready),
		.dmi_resp_valid_i(dmi_rsp_valid),
		.tck_i(tck_i),
		.tms_i(tms_i),
		.trst_ni(trst_ni),
		.td_i(td_i),
		.td_o(td_o),
		.tdo_oe_o(tdo_oe_o)
	);
	tlul_adapter_sram #(
		.SramAw(AddressWidthWords),
		.SramDw(BusWidth),
		.Outstanding(1),
		.ByteAccess(0)
	) tl_adapter_device_mem(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.req_o(req),
		.gnt_i(1'b1),
		.we_o(we),
		.addr_o(addr_w),
		.wdata_o(wdata),
		.wmask_o(),
		.rdata_i(rdata),
		.rvalid_i(rvalid),
		.rerror_i(2'b00),
		.tl_o(tl_d_o),
		.tl_i(tl_d_i)
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rvalid <= 1'sb0;
		else
			rvalid <= req & ~we;
	function automatic [31:0] sv2v_struct_D8B87;
		input reg [31:24] zero1;
		input reg [23:20] nscratch;
		input reg [19:17] zero0;
		input reg dataaccess;
		input reg [15:12] datasize;
		input reg [11:0] dataaddr;
		sv2v_struct_D8B87 = {zero1, nscratch, zero0, dataaccess, datasize, dataaddr};
	endfunction
endmodule
