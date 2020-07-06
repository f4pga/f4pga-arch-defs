module dm_csrs (
	clk_i,
	rst_ni,
	testmode_i,
	dmi_rst_ni,
	dmi_req_valid_i,
	dmi_req_ready_o,
	dmi_req_i,
	dmi_resp_valid_o,
	dmi_resp_ready_i,
	dmi_resp_o,
	ndmreset_o,
	dmactive_o,
	hartinfo_i,
	halted_i,
	unavailable_i,
	resumeack_i,
	hartsel_o,
	haltreq_o,
	resumereq_o,
	clear_resumeack_o,
	cmd_valid_o,
	cmd_o,
	cmderror_valid_i,
	cmderror_i,
	cmdbusy_i,
	progbuf_o,
	data_o,
	data_i,
	data_valid_i,
	sbaddress_o,
	sbaddress_i,
	sbaddress_write_valid_o,
	sbreadonaddr_o,
	sbautoincrement_o,
	sbaccess_o,
	sbreadondata_o,
	sbdata_o,
	sbdata_read_valid_o,
	sbdata_write_valid_o,
	sbdata_i,
	sbdata_valid_i,
	sbbusy_i,
	sberror_valid_i,
	sberror_i
);
	localparam [7:0] dm_AbstractAuto = 8'h18;
	localparam [7:0] dm_AbstractCS = 8'h16;
	localparam [2:0] dm_CmdErrBusy = 1;
	localparam [2:0] dm_CmdErrNone = 0;
	localparam [7:0] dm_Command = 8'h17;
	localparam [7:0] dm_DMControl = 8'h10;
	localparam [7:0] dm_DMStatus = 8'h11;
	localparam [1:0] dm_DTM_READ = 2'h1;
	localparam [1:0] dm_DTM_SUCCESS = 2'h0;
	localparam [1:0] dm_DTM_WRITE = 2'h2;
	localparam [7:0] dm_Data0 = 8'h04;
	localparam [3:0] dm_DataCount = 4'h2;
	localparam [3:0] dm_DbgVersion013 = 4'h2;
	localparam [7:0] dm_HaltSum0 = 8'h40;
	localparam [7:0] dm_HaltSum1 = 8'h13;
	localparam [7:0] dm_HaltSum2 = 8'h34;
	localparam [7:0] dm_HaltSum3 = 8'h35;
	localparam [7:0] dm_Hartinfo = 8'h12;
	localparam [7:0] dm_ProgBuf0 = 8'h20;
	localparam [4:0] dm_ProgBufSize = 5'h8;
	localparam [7:0] dm_SBAddress0 = 8'h39;
	localparam [7:0] dm_SBAddress1 = 8'h3A;
	localparam [7:0] dm_SBCS = 8'h38;
	localparam [7:0] dm_SBData0 = 8'h3C;
	localparam [7:0] dm_SBData1 = 8'h3D;
	parameter [31:0] NrHarts = 1;
	parameter [31:0] BusWidth = 32;
	parameter [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	input wire dmi_rst_ni;
	input wire dmi_req_valid_i;
	output wire dmi_req_ready_o;
	input wire [40:0] dmi_req_i;
	output wire dmi_resp_valid_o;
	input wire dmi_resp_ready_i;
	output wire [33:0] dmi_resp_o;
	output wire ndmreset_o;
	output wire dmactive_o;
	input wire [((NrHarts - 1) >= 0 ? (NrHarts * 32) + -1 : ((2 - NrHarts) * 32) + (((NrHarts - 1) * 32) - 1)):((NrHarts - 1) >= 0 ? 0 : (NrHarts - 1) * 32)] hartinfo_i;
	input wire [NrHarts - 1:0] halted_i;
	input wire [NrHarts - 1:0] unavailable_i;
	input wire [NrHarts - 1:0] resumeack_i;
	output wire [19:0] hartsel_o;
	output reg [NrHarts - 1:0] haltreq_o;
	output reg [NrHarts - 1:0] resumereq_o;
	output reg clear_resumeack_o;
	output wire cmd_valid_o;
	output wire [31:0] cmd_o;
	input wire cmderror_valid_i;
	input wire [2:0] cmderror_i;
	input wire cmdbusy_i;
	output wire [((dm_ProgBufSize - 1) >= 0 ? (dm_ProgBufSize * 32) + -1 : ((2 - dm_ProgBufSize) * 32) + (((dm_ProgBufSize - 1) * 32) - 1)):((dm_ProgBufSize - 1) >= 0 ? 0 : (dm_ProgBufSize - 1) * 32)] progbuf_o;
	output wire [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_o;
	input wire [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_i;
	input wire data_valid_i;
	output wire [BusWidth - 1:0] sbaddress_o;
	input wire [BusWidth - 1:0] sbaddress_i;
	output reg sbaddress_write_valid_o;
	output wire sbreadonaddr_o;
	output wire sbautoincrement_o;
	output wire [2:0] sbaccess_o;
	output wire sbreadondata_o;
	output wire [BusWidth - 1:0] sbdata_o;
	output reg sbdata_read_valid_o;
	output reg sbdata_write_valid_o;
	input wire [BusWidth - 1:0] sbdata_i;
	input wire sbdata_valid_i;
	input wire sbbusy_i;
	input wire sberror_valid_i;
	input wire [2:0] sberror_i;
	localparam [31:0] HartSelLen = (NrHarts == 1 ? 1 : $clog2(NrHarts));
	localparam [31:0] NrHartsAligned = 2 ** HartSelLen;
	wire [1:0] dtm_op;
	assign dtm_op = sv2v_cast_2(dmi_req_i[33-:2]);
	reg [31:0] resp_queue_data;
	localparam [7:0] DataEnd = sv2v_cast_8(dm_Data0 + {4'b0, dm_DataCount});
	localparam [7:0] ProgBufEnd = sv2v_cast_8(dm_ProgBuf0 + {4'b0, dm_ProgBufSize});
	reg [31:0] haltsum0;
	reg [31:0] haltsum1;
	reg [31:0] haltsum2;
	reg [31:0] haltsum3;
	reg [((((NrHarts - 1) / (2 ** 5)) + 1) * 32) - 1:0] halted;
	reg [(((NrHarts - 1) / (2 ** 5)) >= 0 ? ((((NrHarts - 1) / (2 ** 5)) + 1) * 32) + -1 : ((1 - ((NrHarts - 1) / (2 ** 5))) * 32) + ((((NrHarts - 1) / (2 ** 5)) * 32) - 1)):(((NrHarts - 1) / (2 ** 5)) >= 0 ? 0 : ((NrHarts - 1) / (2 ** 5)) * 32)] halted_reshaped0;
	reg [((NrHarts / (2 ** 10)) >= 0 ? (((NrHarts / (2 ** 10)) + 1) * 32) + -1 : ((1 - (NrHarts / (2 ** 10))) * 32) + (((NrHarts / (2 ** 10)) * 32) - 1)):((NrHarts / (2 ** 10)) >= 0 ? 0 : (NrHarts / (2 ** 10)) * 32)] halted_reshaped1;
	reg [((NrHarts / (2 ** 15)) >= 0 ? (((NrHarts / (2 ** 15)) + 1) * 32) + -1 : ((1 - (NrHarts / (2 ** 15))) * 32) + (((NrHarts / (2 ** 15)) * 32) - 1)):((NrHarts / (2 ** 15)) >= 0 ? 0 : (NrHarts / (2 ** 15)) * 32)] halted_reshaped2;
	reg [(((NrHarts / (2 ** 10)) + 1) * 32) - 1:0] halted_flat1;
	reg [(((NrHarts / (2 ** 15)) + 1) * 32) - 1:0] halted_flat2;
	reg [31:0] halted_flat3;
	reg [14:0] hartsel_idx0;
	always @(*) begin : p_haltsum0
		halted = 1'sb0;
		haltsum0 = 1'sb0;
		hartsel_idx0 = hartsel_o[19:5];
		halted[NrHarts - 1:0] = halted_i;
		halted_reshaped0 = halted;
		if (hartsel_idx0 < sv2v_cast_15(((NrHarts - 1) / (2 ** 5)) + 1))
			haltsum0 = halted_reshaped0[(((NrHarts - 1) / (2 ** 5)) >= 0 ? hartsel_idx0 : 0 - (hartsel_idx0 - ((NrHarts - 1) / (2 ** 5)))) * 32+:32];
	end
	reg [9:0] hartsel_idx1;
	always @(*) begin : p_reduction1
		halted_flat1 = 1'sb0;
		haltsum1 = 1'sb0;
		hartsel_idx1 = hartsel_o[19:10];
		begin : sv2v_autoblock_154
			reg [31:0] k;
			for (k = 0; k < ((NrHarts / (2 ** 5)) + 1); k = k + 1)
				halted_flat1[k] = |halted_reshaped0[(((NrHarts - 1) / (2 ** 5)) >= 0 ? k : 0 - (k - ((NrHarts - 1) / (2 ** 5)))) * 32+:32];
		end
		halted_reshaped1 = halted_flat1;
		if (hartsel_idx1 < sv2v_cast_10((NrHarts / (2 ** 10)) + 1))
			haltsum1 = halted_reshaped1[((NrHarts / (2 ** 10)) >= 0 ? hartsel_idx1 : 0 - (hartsel_idx1 - (NrHarts / (2 ** 10)))) * 32+:32];
	end
	reg [4:0] hartsel_idx2;
	always @(*) begin : p_reduction2
		halted_flat2 = 1'sb0;
		haltsum2 = 1'sb0;
		hartsel_idx2 = hartsel_o[19:15];
		begin : sv2v_autoblock_155
			reg [31:0] k;
			for (k = 0; k < ((NrHarts / (2 ** 10)) + 1); k = k + 1)
				halted_flat2[k] = |halted_reshaped1[((NrHarts / (2 ** 10)) >= 0 ? k : 0 - (k - (NrHarts / (2 ** 10)))) * 32+:32];
		end
		halted_reshaped2 = halted_flat2;
		if (hartsel_idx2 < sv2v_cast_5((NrHarts / (2 ** 15)) + 1))
			haltsum2 = halted_reshaped2[((NrHarts / (2 ** 15)) >= 0 ? hartsel_idx2 : 0 - (hartsel_idx2 - (NrHarts / (2 ** 15)))) * 32+:32];
	end
	always @(*) begin : p_reduction3
		halted_flat3 = 1'sb0;
		begin : sv2v_autoblock_156
			reg [31:0] k;
			for (k = 0; k < ((NrHarts / (2 ** 15)) + 1); k = k + 1)
				halted_flat3[k] = |halted_reshaped2[((NrHarts / (2 ** 15)) >= 0 ? k : 0 - (k - (NrHarts / (2 ** 15)))) * 32+:32];
		end
		haltsum3 = halted_flat3;
	end
	reg [31:0] dmstatus;
	reg [31:0] dmcontrol_d;
	reg [31:0] dmcontrol_q;
	reg [31:0] abstractcs;
	reg [2:0] cmderr_d;
	reg [2:0] cmderr_q;
	reg [31:0] command_d;
	reg [31:0] command_q;
	reg cmd_valid_d;
	reg cmd_valid_q;
	reg [31:0] abstractauto_d;
	reg [31:0] abstractauto_q;
	reg [31:0] sbcs_d;
	reg [31:0] sbcs_q;
	reg [63:0] sbaddr_d;
	reg [63:0] sbaddr_q;
	reg [63:0] sbdata_d;
	reg [63:0] sbdata_q;
	wire [NrHarts - 1:0] havereset_d;
	reg [NrHarts - 1:0] havereset_q;
	reg [((dm_ProgBufSize - 1) >= 0 ? (dm_ProgBufSize * 32) + -1 : ((2 - dm_ProgBufSize) * 32) + (((dm_ProgBufSize - 1) * 32) - 1)):((dm_ProgBufSize - 1) >= 0 ? 0 : (dm_ProgBufSize - 1) * 32)] progbuf_d;
	reg [((dm_ProgBufSize - 1) >= 0 ? (dm_ProgBufSize * 32) + -1 : ((2 - dm_ProgBufSize) * 32) + (((dm_ProgBufSize - 1) * 32) - 1)):((dm_ProgBufSize - 1) >= 0 ? 0 : (dm_ProgBufSize - 1) * 32)] progbuf_q;
	reg [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_d;
	reg [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_q;
	reg [HartSelLen - 1:0] selected_hart;
	assign dmi_resp_o[1-:2] = dm_DTM_SUCCESS;
	assign sbautoincrement_o = sbcs_q[16];
	assign sbreadonaddr_o = sbcs_q[20];
	assign sbreadondata_o = sbcs_q[15];
	assign sbaccess_o = sbcs_q[19-:3];
	assign sbdata_o = sbdata_q[BusWidth - 1:0];
	assign sbaddress_o = sbaddr_q[BusWidth - 1:0];
	assign hartsel_o = {dmcontrol_q[15-:10], dmcontrol_q[25-:10]};
	reg [NrHartsAligned - 1:0] havereset_d_aligned;
	wire [NrHartsAligned - 1:0] havereset_q_aligned;
	wire [NrHartsAligned - 1:0] resumeack_aligned;
	wire [NrHartsAligned - 1:0] unavailable_aligned;
	wire [NrHartsAligned - 1:0] halted_aligned;
	assign resumeack_aligned = sv2v_cast_4CE25(resumeack_i);
	assign unavailable_aligned = sv2v_cast_4CE25(unavailable_i);
	assign halted_aligned = sv2v_cast_4CE25(halted_i);
	assign havereset_d = sv2v_cast_50608(havereset_d_aligned);
	assign havereset_q_aligned = sv2v_cast_4CE25(havereset_q);
	reg [((NrHartsAligned - 1) >= 0 ? (NrHartsAligned * 32) + -1 : ((2 - NrHartsAligned) * 32) + (((NrHartsAligned - 1) * 32) - 1)):((NrHartsAligned - 1) >= 0 ? 0 : (NrHartsAligned - 1) * 32)] hartinfo_aligned;
	always @(*) begin : p_hartinfo_align
		hartinfo_aligned = {((NrHartsAligned - 1) >= 0 ? NrHartsAligned : 2 - NrHartsAligned) {1'sb0}};
		hartinfo_aligned[32 * ((NrHartsAligned - 1) >= 0 ? ((NrHartsAligned - 1) >= 0 ? ((NrHarts - 1) >= 0 ? NrHarts - 1 : ((NrHarts - 1) + ((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts)) - 1) - (((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts) - 1) : ((NrHarts - 1) >= 0 ? NrHarts - 1 : ((NrHarts - 1) + ((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts)) - 1)) : 0 - (((NrHartsAligned - 1) >= 0 ? ((NrHarts - 1) >= 0 ? NrHarts - 1 : ((NrHarts - 1) + ((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts)) - 1) - (((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts) - 1) : ((NrHarts - 1) >= 0 ? NrHarts - 1 : ((NrHarts - 1) + ((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts)) - 1)) - (NrHartsAligned - 1)))+:32 * ((NrHarts - 1) >= 0 ? NrHarts : 2 - NrHarts)] = hartinfo_i;
	end
	reg [31:0] sbcs;
	reg [31:0] dmcontrol;
	reg [31:0] a_abstractcs;
	reg [4:0] autoexecdata_idx;
	always @(*) begin : csr_read_write
		dmstatus = 1'sb0;
		dmstatus[3-:4] = dm_DbgVersion013;
		dmstatus[7] = 1'b1;
		dmstatus[5] = 1'b0;
		dmstatus[19] = havereset_q_aligned[selected_hart];
		dmstatus[18] = havereset_q_aligned[selected_hart];
		dmstatus[17] = resumeack_aligned[selected_hart];
		dmstatus[16] = resumeack_aligned[selected_hart];
		dmstatus[13] = unavailable_aligned[selected_hart];
		dmstatus[12] = unavailable_aligned[selected_hart];
		dmstatus[15] = sv2v_cast_1(sv2v_cast_32(hartsel_o) > (NrHarts - 1));
		dmstatus[14] = sv2v_cast_1(sv2v_cast_32(hartsel_o) > (NrHarts - 1));
		dmstatus[9] = halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
		dmstatus[8] = halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
		dmstatus[11] = ~halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
		dmstatus[10] = ~halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
		abstractcs = 1'sb0;
		abstractcs[3-:4] = dm_DataCount;
		abstractcs[28-:5] = dm_ProgBufSize;
		abstractcs[12] = cmdbusy_i;
		abstractcs[10-:3] = cmderr_q;
		abstractauto_d = abstractauto_q;
		abstractauto_d[15-:4] = 1'sb0;
		havereset_d_aligned = sv2v_cast_4CE25(havereset_q);
		dmcontrol_d = dmcontrol_q;
		cmderr_d = cmderr_q;
		command_d = command_q;
		progbuf_d = progbuf_q;
		data_d = data_q;
		sbcs_d = sbcs_q;
		sbaddr_d = sv2v_cast_64(sbaddress_i);
		sbdata_d = sbdata_q;
		resp_queue_data = 32'b0;
		cmd_valid_d = 1'b0;
		sbaddress_write_valid_o = 1'b0;
		sbdata_read_valid_o = 1'b0;
		sbdata_write_valid_o = 1'b0;
		clear_resumeack_o = 1'b0;
		sbcs = 1'sb0;
		dmcontrol = 1'sb0;
		a_abstractcs = 1'sb0;
		autoexecdata_idx = dmi_req_i[38:34] - sv2v_cast_5(dm_Data0);
		if ((dmi_req_ready_o && dmi_req_valid_i) && (dtm_op == dm_DTM_READ))
			if ((dm_Data0 <= {1'b0, dmi_req_i[40-:7]}) && (DataEnd >= {1'b0, dmi_req_i[40-:7]})) begin
				resp_queue_data = data_q[((dm_DataCount - 1) >= 0 ? sv2v_cast_48325(autoexecdata_idx) : 0 - (sv2v_cast_48325(autoexecdata_idx) - (dm_DataCount - 1))) * 32+:32];
				if (!cmdbusy_i)
					if (autoexecdata_idx < 12)
						cmd_valid_d = abstractauto_q[autoexecdata_idx];
			end
			else if (((dm_DMControl ^ dm_DMControl) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_DMControl ^ dm_DMControl)) ? 1'bx : (dm_DMControl ^ dm_DMControl) === (dm_DMControl ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = dmcontrol_q;
			else if (((dm_DMStatus ^ dm_DMStatus) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_DMStatus ^ dm_DMStatus)) ? 1'bx : (dm_DMStatus ^ dm_DMStatus) === (dm_DMStatus ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = dmstatus;
			else if (((dm_Hartinfo ^ dm_Hartinfo) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_Hartinfo ^ dm_Hartinfo)) ? 1'bx : (dm_Hartinfo ^ dm_Hartinfo) === (dm_Hartinfo ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = hartinfo_aligned[((NrHartsAligned - 1) >= 0 ? selected_hart : 0 - (selected_hart - (NrHartsAligned - 1))) * 32+:32];
			else if (((dm_AbstractCS ^ dm_AbstractCS) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_AbstractCS ^ dm_AbstractCS)) ? 1'bx : (dm_AbstractCS ^ dm_AbstractCS) === (dm_AbstractCS ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = abstractcs;
			else if (((dm_AbstractAuto ^ dm_AbstractAuto) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_AbstractAuto ^ dm_AbstractAuto)) ? 1'bx : (dm_AbstractAuto ^ dm_AbstractAuto) === (dm_AbstractAuto ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = abstractauto_q;
			else if (((dm_Command ^ dm_Command) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_Command ^ dm_Command)) ? 1'bx : (dm_Command ^ dm_Command) === (dm_Command ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = 1'sb0;
			else if ((dm_ProgBuf0 <= {1'b0, dmi_req_i[40-:7]}) && (ProgBufEnd >= {1'b0, dmi_req_i[40-:7]})) begin
				resp_queue_data = progbuf_q[((dm_ProgBufSize - 1) >= 0 ? dmi_req_i[34 + ($clog2(5'h8) - 1):34] : 0 - (dmi_req_i[34 + ($clog2(5'h8) - 1):34] - (dm_ProgBufSize - 1))) * 32+:32];
				if (!cmdbusy_i)
					cmd_valid_d = abstractauto_q[{1'b1, dmi_req_i[37:34]}];
			end
			else if (((dm_HaltSum0 ^ dm_HaltSum0) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_HaltSum0 ^ dm_HaltSum0)) ? 1'bx : (dm_HaltSum0 ^ dm_HaltSum0) === (dm_HaltSum0 ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = haltsum0;
			else if (((dm_HaltSum1 ^ dm_HaltSum1) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_HaltSum1 ^ dm_HaltSum1)) ? 1'bx : (dm_HaltSum1 ^ dm_HaltSum1) === (dm_HaltSum1 ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = haltsum1;
			else if (((dm_HaltSum2 ^ dm_HaltSum2) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_HaltSum2 ^ dm_HaltSum2)) ? 1'bx : (dm_HaltSum2 ^ dm_HaltSum2) === (dm_HaltSum2 ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = haltsum2;
			else if (((dm_HaltSum3 ^ dm_HaltSum3) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_HaltSum3 ^ dm_HaltSum3)) ? 1'bx : (dm_HaltSum3 ^ dm_HaltSum3) === (dm_HaltSum3 ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = haltsum3;
			else if (((dm_SBCS ^ dm_SBCS) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_SBCS ^ dm_SBCS)) ? 1'bx : (dm_SBCS ^ dm_SBCS) === (dm_SBCS ^ {1'b0, dmi_req_i[40-:7]})))
				resp_queue_data = sbcs_q;
			else if (((dm_SBAddress0 ^ dm_SBAddress0) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_SBAddress0 ^ dm_SBAddress0)) ? 1'bx : (dm_SBAddress0 ^ dm_SBAddress0) === (dm_SBAddress0 ^ {1'b0, dmi_req_i[40-:7]}))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else
					resp_queue_data = sbaddr_q[31:0];
			end
			else if (((dm_SBAddress1 ^ dm_SBAddress1) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_SBAddress1 ^ dm_SBAddress1)) ? 1'bx : (dm_SBAddress1 ^ dm_SBAddress1) === (dm_SBAddress1 ^ {1'b0, dmi_req_i[40-:7]}))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else
					resp_queue_data = sbaddr_q[63:32];
			end
			else if (((dm_SBData0 ^ dm_SBData0) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_SBData0 ^ dm_SBData0)) ? 1'bx : (dm_SBData0 ^ dm_SBData0) === (dm_SBData0 ^ {1'b0, dmi_req_i[40-:7]}))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else begin
					sbdata_read_valid_o = sbcs_q[14-:3] == 1'sb0;
					resp_queue_data = sbdata_q[31:0];
				end
			end
			else if (((dm_SBData1 ^ dm_SBData1) !== (({1'b0, dmi_req_i[40-:7]} ^ {1'b0, dmi_req_i[40-:7]}) ^ (dm_SBData1 ^ dm_SBData1)) ? 1'bx : (dm_SBData1 ^ dm_SBData1) === (dm_SBData1 ^ {1'b0, dmi_req_i[40-:7]})))
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else
					resp_queue_data = sbdata_q[63:32];
		if ((dmi_req_ready_o && dmi_req_valid_i) && (dtm_op == dm_DTM_WRITE))
			if ((dm_Data0 <= sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) && (DataEnd >= sv2v_cast_8({1'b0, dmi_req_i[40-:7]}))) begin
				if (!cmdbusy_i && (dm_DataCount > 0)) begin
					data_d[((dm_DataCount - 1) >= 0 ? dmi_req_i[34 + ($clog2(4'h2) - 1):34] : 0 - (dmi_req_i[34 + ($clog2(4'h2) - 1):34] - (dm_DataCount - 1))) * 32+:32] = dmi_req_i[31-:32];
					if (autoexecdata_idx < 12)
						cmd_valid_d = abstractauto_q[autoexecdata_idx];
				end
			end
			else if (((dm_DMControl ^ dm_DMControl) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_DMControl ^ dm_DMControl)) ? 1'bx : (dm_DMControl ^ dm_DMControl) === (dm_DMControl ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				dmcontrol = sv2v_cast_32(dmi_req_i[31-:32]);
				if (dmcontrol[28])
					havereset_d_aligned[selected_hart] = 1'b0;
				dmcontrol_d = dmi_req_i[31-:32];
			end
			else if (((dm_DMStatus ^ dm_DMStatus) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_DMStatus ^ dm_DMStatus)) ? 1'bx : (dm_DMStatus ^ dm_DMStatus) === (dm_DMStatus ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]}))))
				;
			else if (((dm_Hartinfo ^ dm_Hartinfo) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_Hartinfo ^ dm_Hartinfo)) ? 1'bx : (dm_Hartinfo ^ dm_Hartinfo) === (dm_Hartinfo ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]}))))
				;
			else if (((dm_AbstractCS ^ dm_AbstractCS) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_AbstractCS ^ dm_AbstractCS)) ? 1'bx : (dm_AbstractCS ^ dm_AbstractCS) === (dm_AbstractCS ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				a_abstractcs = sv2v_cast_32(dmi_req_i[31-:32]);
				if (!cmdbusy_i)
					cmderr_d = sv2v_cast_3(~a_abstractcs[10-:3] & cmderr_q);
				else if (cmderr_q == dm_CmdErrNone)
					cmderr_d = dm_CmdErrBusy;
			end
			else if (((dm_Command ^ dm_Command) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_Command ^ dm_Command)) ? 1'bx : (dm_Command ^ dm_Command) === (dm_Command ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (!cmdbusy_i) begin
					cmd_valid_d = 1'b1;
					command_d = sv2v_cast_32(dmi_req_i[31-:32]);
				end
				else if (cmderr_q == dm_CmdErrNone)
					cmderr_d = dm_CmdErrBusy;
			end
			else if (((dm_AbstractAuto ^ dm_AbstractAuto) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_AbstractAuto ^ dm_AbstractAuto)) ? 1'bx : (dm_AbstractAuto ^ dm_AbstractAuto) === (dm_AbstractAuto ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (!cmdbusy_i) begin
					abstractauto_d = 32'b0;
					abstractauto_d[11-:12] = sv2v_cast_12(dmi_req_i[dm_DataCount - 1:0]);
					abstractauto_d[31-:16] = sv2v_cast_16(dmi_req_i[(dm_ProgBufSize - 1) + 16:16]);
				end
				else if (cmderr_q == dm_CmdErrNone)
					cmderr_d = dm_CmdErrBusy;
			end
			else if ((dm_ProgBuf0 <= sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) && (ProgBufEnd >= sv2v_cast_8({1'b0, dmi_req_i[40-:7]}))) begin
				if (!cmdbusy_i) begin
					progbuf_d[((dm_ProgBufSize - 1) >= 0 ? dmi_req_i[34 + ($clog2(5'h8) - 1):34] : 0 - (dmi_req_i[34 + ($clog2(5'h8) - 1):34] - (dm_ProgBufSize - 1))) * 32+:32] = dmi_req_i[31-:32];
					cmd_valid_d = abstractauto_q[{1'b1, dmi_req_i[37:34]}];
				end
			end
			else if (((dm_SBCS ^ dm_SBCS) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_SBCS ^ dm_SBCS)) ? 1'bx : (dm_SBCS ^ dm_SBCS) === (dm_SBCS ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else begin
					sbcs = sv2v_cast_32(dmi_req_i[31-:32]);
					sbcs_d = sbcs;
					sbcs_d[22] = sbcs_q[22] & ~sbcs[22];
					sbcs_d[14-:3] = sbcs_q[14-:3] & ~sbcs[14-:3];
				end
			end
			else if (((dm_SBAddress0 ^ dm_SBAddress0) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_SBAddress0 ^ dm_SBAddress0)) ? 1'bx : (dm_SBAddress0 ^ dm_SBAddress0) === (dm_SBAddress0 ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else begin
					sbaddr_d[31:0] = dmi_req_i[31-:32];
					sbaddress_write_valid_o = sbcs_q[14-:3] == 1'sb0;
				end
			end
			else if (((dm_SBAddress1 ^ dm_SBAddress1) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_SBAddress1 ^ dm_SBAddress1)) ? 1'bx : (dm_SBAddress1 ^ dm_SBAddress1) === (dm_SBAddress1 ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else
					sbaddr_d[63:32] = dmi_req_i[31-:32];
			end
			else if (((dm_SBData0 ^ dm_SBData0) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_SBData0 ^ dm_SBData0)) ? 1'bx : (dm_SBData0 ^ dm_SBData0) === (dm_SBData0 ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})))) begin
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else begin
					sbdata_d[31:0] = dmi_req_i[31-:32];
					sbdata_write_valid_o = sbcs_q[14-:3] == 1'sb0;
				end
			end
			else if (((dm_SBData1 ^ dm_SBData1) !== ((sv2v_cast_8({1'b0, dmi_req_i[40-:7]}) ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]})) ^ (dm_SBData1 ^ dm_SBData1)) ? 1'bx : (dm_SBData1 ^ dm_SBData1) === (dm_SBData1 ^ sv2v_cast_8({1'b0, dmi_req_i[40-:7]}))))
				if (sbbusy_i)
					sbcs_d[22] = 1'b1;
				else
					sbdata_d[63:32] = dmi_req_i[31-:32];
		if (cmderror_valid_i)
			cmderr_d = cmderror_i;
		if (data_valid_i)
			data_d = data_i;
		if (ndmreset_o)
			havereset_d_aligned[NrHarts - 1:0] = 1'sb1;
		if (sberror_valid_i)
			sbcs_d[14-:3] = sberror_i;
		if (sbdata_valid_i)
			sbdata_d = sv2v_cast_64(sbdata_i);
		dmcontrol_d[26] = 1'b0;
		dmcontrol_d[29] = 1'b0;
		dmcontrol_d[3] = 1'b0;
		dmcontrol_d[2] = 1'b0;
		dmcontrol_d[27] = 1'sb0;
		dmcontrol_d[5-:2] = 1'sb0;
		dmcontrol_d[28] = 1'b0;
		if (!dmcontrol_q[30] && dmcontrol_d[30])
			clear_resumeack_o = 1'b1;
		if (dmcontrol_q[30] && resumeack_i)
			dmcontrol_d[30] = 1'b0;
		sbcs_d[31-:3] = 3'b1;
		sbcs_d[21] = sbbusy_i;
		sbcs_d[11-:7] = sv2v_cast_7(BusWidth);
		sbcs_d[4] = 1'b0;
		sbcs_d[3] = sv2v_cast_1(BusWidth == 32'd64);
		sbcs_d[2] = sv2v_cast_1(BusWidth == 32'd32);
		sbcs_d[1] = 1'b0;
		sbcs_d[0] = 1'b0;
		sbcs_d[19-:3] = (BusWidth == 32'd64 ? 3'd3 : 3'd2);
	end
	always @(*) begin : p_outmux
		selected_hart = hartsel_o[HartSelLen - 1:0];
		haltreq_o = 1'sb0;
		resumereq_o = 1'sb0;
		if (selected_hart < sv2v_cast_311A9(NrHarts)) begin
			haltreq_o[selected_hart] = dmcontrol_q[31];
			resumereq_o[selected_hart] = dmcontrol_q[30];
		end
	end
	assign dmactive_o = dmcontrol_q[0];
	assign cmd_o = command_q;
	assign cmd_valid_o = cmd_valid_q;
	assign progbuf_o = progbuf_q;
	assign data_o = data_q;
	assign ndmreset_o = dmcontrol_q[1];
	wire unused_testmode;
	assign unused_testmode = testmode_i;
	prim_fifo_sync #(
		.Width(32),
		.Pass(1'b0),
		.Depth(2)
	) i_fifo(
		.clk_i(clk_i),
		.rst_ni(dmi_rst_ni),
		.clr_i(1'b0),
		.wdata(resp_queue_data),
		.wvalid(dmi_req_valid_i),
		.wready(dmi_req_ready_o),
		.rdata(dmi_resp_o[33-:32]),
		.rvalid(dmi_resp_valid_o),
		.rready(dmi_resp_ready_i),
		.depth()
	);
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			dmcontrol_q <= 1'sb0;
			cmderr_q <= dm_CmdErrNone;
			command_q <= 1'sb0;
			abstractauto_q <= 1'sb0;
			progbuf_q <= 1'sb0;
			data_q <= 1'sb0;
			sbcs_q <= 1'sb0;
			sbaddr_q <= 1'sb0;
			sbdata_q <= 1'sb0;
			havereset_q <= 1'sb1;
		end
		else begin
			havereset_q <= SelectableHarts & havereset_d;
			if (!dmcontrol_q[0]) begin
				dmcontrol_q[31] <= 1'sb0;
				dmcontrol_q[30] <= 1'sb0;
				dmcontrol_q[29] <= 1'sb0;
				dmcontrol_q[28] <= 1'sb0;
				dmcontrol_q[27] <= 1'sb0;
				dmcontrol_q[26] <= 1'sb0;
				dmcontrol_q[25-:10] <= 1'sb0;
				dmcontrol_q[15-:10] <= 1'sb0;
				dmcontrol_q[5-:2] <= 1'sb0;
				dmcontrol_q[3] <= 1'sb0;
				dmcontrol_q[2] <= 1'sb0;
				dmcontrol_q[1] <= 1'sb0;
				dmcontrol_q[0] <= dmcontrol_d[0];
				cmderr_q <= dm_CmdErrNone;
				command_q <= 1'sb0;
				cmd_valid_q <= 1'sb0;
				abstractauto_q <= 1'sb0;
				progbuf_q <= 1'sb0;
				data_q <= 1'sb0;
				sbcs_q <= 1'sb0;
				sbaddr_q <= 1'sb0;
				sbdata_q <= 1'sb0;
			end
			else begin
				dmcontrol_q <= dmcontrol_d;
				cmderr_q <= cmderr_d;
				command_q <= command_d;
				cmd_valid_q <= cmd_valid_d;
				abstractauto_q <= abstractauto_d;
				progbuf_q <= progbuf_d;
				data_q <= data_d;
				sbcs_q <= sbcs_d;
				sbaddr_q <= sbaddr_d;
				sbdata_q <= sbdata_d;
			end
		end
	end
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	function automatic [15:0] sv2v_cast_16;
		input reg [15:0] inp;
		sv2v_cast_16 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [$clog2(dm_DataCount) - 1:0] sv2v_cast_48325;
		input reg [$clog2(dm_DataCount) - 1:0] inp;
		sv2v_cast_48325 = inp;
	endfunction
	function automatic [(2 ** (NrHarts == 1 ? 1 : $clog2(NrHarts))) - 1:0] sv2v_cast_4CE25;
		input reg [(2 ** (NrHarts == 1 ? 1 : $clog2(NrHarts))) - 1:0] inp;
		sv2v_cast_4CE25 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	function automatic [NrHarts - 1:0] sv2v_cast_50608;
		input reg [NrHarts - 1:0] inp;
		sv2v_cast_50608 = inp;
	endfunction
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	function automatic [9:0] sv2v_cast_10;
		input reg [9:0] inp;
		sv2v_cast_10 = inp;
	endfunction
	function automatic [14:0] sv2v_cast_15;
		input reg [14:0] inp;
		sv2v_cast_15 = inp;
	endfunction
	function automatic [((NrHarts == 1 ? 1 : $clog2(NrHarts)) + 1) - 1:0] sv2v_cast_311A9;
		input reg [((NrHarts == 1 ? 1 : $clog2(NrHarts)) + 1) - 1:0] inp;
		sv2v_cast_311A9 = inp;
	endfunction
	function automatic [6:0] sv2v_cast_7;
		input reg [6:0] inp;
		sv2v_cast_7 = inp;
	endfunction
endmodule
