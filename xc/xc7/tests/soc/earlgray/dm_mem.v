module dm_mem (
	clk_i,
	rst_ni,
	debug_req_o,
	hartsel_i,
	haltreq_i,
	resumereq_i,
	clear_resumeack_i,
	halted_o,
	resuming_o,
	progbuf_i,
	data_i,
	data_o,
	data_valid_o,
	cmd_valid_i,
	cmd_i,
	cmderror_valid_o,
	cmderror_o,
	cmdbusy_o,
	req_i,
	we_i,
	addr_i,
	wdata_i,
	be_i,
	rdata_o
);
	localparam [7:0] dm_AccessRegister = 8'h0;
	localparam [11:0] dm_CSR_DSCRATCH0 = 12'h7b2;
	localparam [11:0] dm_CSR_DSCRATCH1 = 12'h7b3;
	localparam [2:0] dm_CmdErrNone = 0;
	localparam [2:0] dm_CmdErrNotSupported = 2;
	localparam [2:0] dm_CmdErrorException = 3;
	localparam [2:0] dm_CmdErrorHaltResume = 4;
	localparam [11:0] dm_DataAddr = 12'h380;
	localparam [3:0] dm_DataCount = 4'h2;
	localparam [63:0] dm_HaltAddress = 64'h800;
	localparam [4:0] dm_ProgBufSize = 5'h8;
	localparam [63:0] dm_ResumeAddress = dm_HaltAddress + 4;
	localparam [1:0] Idle = 0;
	localparam [1:0] Go = 1;
	localparam [1:0] Resume = 2;
	localparam [1:0] CmdExecuting = 3;
	parameter [31:0] NrHarts = 1;
	parameter [31:0] BusWidth = 32;
	parameter [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	input wire clk_i;
	input wire rst_ni;
	output wire [NrHarts - 1:0] debug_req_o;
	input wire [19:0] hartsel_i;
	input wire [NrHarts - 1:0] haltreq_i;
	input wire [NrHarts - 1:0] resumereq_i;
	input wire clear_resumeack_i;
	output wire [NrHarts - 1:0] halted_o;
	output wire [NrHarts - 1:0] resuming_o;
	input wire [((dm_ProgBufSize - 1) >= 0 ? (dm_ProgBufSize * 32) + -1 : ((2 - dm_ProgBufSize) * 32) + (((dm_ProgBufSize - 1) * 32) - 1)):((dm_ProgBufSize - 1) >= 0 ? 0 : (dm_ProgBufSize - 1) * 32)] progbuf_i;
	input wire [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_i;
	output reg [((dm_DataCount - 1) >= 0 ? (dm_DataCount * 32) + -1 : ((2 - dm_DataCount) * 32) + (((dm_DataCount - 1) * 32) - 1)):((dm_DataCount - 1) >= 0 ? 0 : (dm_DataCount - 1) * 32)] data_o;
	output reg data_valid_o;
	input wire cmd_valid_i;
	input wire [31:0] cmd_i;
	output reg cmderror_valid_o;
	output reg [2:0] cmderror_o;
	output reg cmdbusy_o;
	input wire req_i;
	input wire we_i;
	input wire [BusWidth - 1:0] addr_i;
	input wire [BusWidth - 1:0] wdata_i;
	input wire [(BusWidth / 8) - 1:0] be_i;
	output wire [BusWidth - 1:0] rdata_o;
	localparam [31:0] DbgAddressBits = 12;
	localparam [31:0] HartSelLen = (NrHarts == 1 ? 1 : $clog2(NrHarts));
	localparam [31:0] NrHartsAligned = 2 ** HartSelLen;
	localparam [31:0] MaxAar = (BusWidth == 64 ? 4 : 3);
	localparam [DbgAddressBits - 1:0] DataBaseAddr = dm_DataAddr;
	localparam [DbgAddressBits - 1:0] DataEndAddr = dm_DataAddr + (4 * dm_DataCount);
	localparam [DbgAddressBits - 1:0] ProgBufBaseAddr = dm_DataAddr - (4 * dm_ProgBufSize);
	localparam [DbgAddressBits - 1:0] ProgBufEndAddr = dm_DataAddr - 1;
	localparam [DbgAddressBits - 1:0] AbstractCmdBaseAddr = ProgBufBaseAddr - 40;
	localparam [DbgAddressBits - 1:0] AbstractCmdEndAddr = ProgBufBaseAddr - 1;
	localparam [DbgAddressBits - 1:0] WhereToAddr = 'h300;
	localparam [DbgAddressBits - 1:0] FlagsBaseAddr = 'h400;
	localparam [DbgAddressBits - 1:0] FlagsEndAddr = 'h7FF;
	localparam [DbgAddressBits - 1:0] HaltedAddr = 'h100;
	localparam [DbgAddressBits - 1:0] GoingAddr = 'h104;
	localparam [DbgAddressBits - 1:0] ResumingAddr = 'h108;
	localparam [DbgAddressBits - 1:0] ExceptionAddr = 'h10C;
	wire [(((dm_ProgBufSize / 2) - 1) >= 0 ? ((dm_ProgBufSize / 2) * 64) + -1 : ((2 - (dm_ProgBufSize / 2)) * 64) + ((((dm_ProgBufSize / 2) - 1) * 64) - 1)):(((dm_ProgBufSize / 2) - 1) >= 0 ? 0 : ((dm_ProgBufSize / 2) - 1) * 64)] progbuf;
	reg [511:0] abstract_cmd;
	wire [NrHarts - 1:0] halted_d;
	reg [NrHarts - 1:0] halted_q;
	wire [NrHarts - 1:0] resuming_d;
	reg [NrHarts - 1:0] resuming_q;
	reg resume;
	reg go;
	reg going;
	reg exception;
	reg unsupported_command;
	wire [63:0] rom_rdata;
	reg [63:0] rdata_d;
	reg [63:0] rdata_q;
	reg word_enable32_q;
	wire [HartSelLen - 1:0] hartsel;
	wire [HartSelLen - 1:0] wdata_hartsel;
	assign hartsel = hartsel_i[HartSelLen - 1:0];
	assign wdata_hartsel = wdata_i[HartSelLen - 1:0];
	wire [NrHartsAligned - 1:0] resumereq_aligned;
	wire [NrHartsAligned - 1:0] haltreq_aligned;
	reg [NrHartsAligned - 1:0] halted_d_aligned;
	wire [NrHartsAligned - 1:0] halted_q_aligned;
	reg [NrHartsAligned - 1:0] halted_aligned;
	wire [NrHartsAligned - 1:0] resumereq_wdata_aligned;
	reg [NrHartsAligned - 1:0] resuming_d_aligned;
	wire [NrHartsAligned - 1:0] resuming_q_aligned;
	assign resumereq_aligned = sv2v_cast_4CE25(resumereq_i);
	assign haltreq_aligned = sv2v_cast_4CE25(haltreq_i);
	assign resumereq_wdata_aligned = sv2v_cast_4CE25(resumereq_i);
	assign halted_q_aligned = sv2v_cast_4CE25(halted_q);
	assign halted_d = sv2v_cast_50608(halted_d_aligned);
	assign resuming_q_aligned = sv2v_cast_4CE25(resuming_q);
	assign resuming_d = sv2v_cast_50608(resuming_d_aligned);
	wire fwd_rom_d;
	reg fwd_rom_q;
	wire [23:0] ac_ar;
	assign ac_ar = sv2v_cast_24(cmd_i[23-:24]);
	assign debug_req_o = haltreq_i;
	assign halted_o = halted_q;
	assign resuming_o = resuming_q;
	assign progbuf = progbuf_i;
	reg [1:0] state_d;
	reg [1:0] state_q;
	always @(*) begin : p_hart_ctrl_queue
		cmderror_valid_o = 1'b0;
		cmderror_o = dm_CmdErrNone;
		state_d = state_q;
		go = 1'b0;
		resume = 1'b0;
		cmdbusy_o = 1'b1;
		case (state_q)
			Idle: begin
				cmdbusy_o = 1'b0;
				if ((cmd_valid_i && halted_q_aligned[hartsel]) && !unsupported_command)
					state_d = Go;
				else if (cmd_valid_i) begin
					cmderror_valid_o = 1'b1;
					cmderror_o = dm_CmdErrorHaltResume;
				end
				if (((resumereq_aligned[hartsel] && !resuming_q_aligned[hartsel]) && !haltreq_aligned[hartsel]) && halted_q_aligned[hartsel])
					state_d = Resume;
			end
			Go: begin
				cmdbusy_o = 1'b1;
				go = 1'b1;
				if (going)
					state_d = CmdExecuting;
			end
			Resume: begin
				cmdbusy_o = 1'b1;
				resume = 1'b1;
				if (resuming_q_aligned[hartsel])
					state_d = Idle;
			end
			CmdExecuting: begin
				cmdbusy_o = 1'b1;
				go = 1'b0;
				if (halted_aligned[hartsel])
					state_d = Idle;
			end
			default:
				;
		endcase
		if (unsupported_command && cmd_valid_i) begin
			cmderror_valid_o = 1'b1;
			cmderror_o = dm_CmdErrNotSupported;
		end
		if (exception) begin
			cmderror_valid_o = 1'b1;
			cmderror_o = dm_CmdErrorException;
		end
	end
	wire [63:0] word_mux;
	assign word_mux = (fwd_rom_q ? rom_rdata : rdata_q);
	generate
		if (BusWidth == 64) begin : gen_word_mux64
			assign rdata_o = word_mux;
		end
		else begin : gen_word_mux32
			assign rdata_o = (word_enable32_q ? word_mux[32+:32] : word_mux[0+:32]);
		end
	endgenerate
	reg [63:0] data_bits;
	reg [63:0] rdata;
	always @(*) begin : p_rw_logic
		halted_d_aligned = sv2v_cast_4CE25(halted_q);
		resuming_d_aligned = sv2v_cast_4CE25(resuming_q);
		rdata_d = rdata_q;
		data_bits = data_i;
		rdata = 1'sb0;
		data_valid_o = 1'b0;
		exception = 1'b0;
		halted_aligned = 1'sb0;
		going = 1'b0;
		if (clear_resumeack_i)
			resuming_d_aligned[hartsel] = 1'b0;
		if (req_i)
			if (we_i) begin
				if (((HaltedAddr ^ HaltedAddr) !== ((addr_i[DbgAddressBits - 1:0] ^ addr_i[DbgAddressBits - 1:0]) ^ (HaltedAddr ^ HaltedAddr)) ? 1'bx : (HaltedAddr ^ HaltedAddr) === (HaltedAddr ^ addr_i[DbgAddressBits - 1:0]))) begin
					halted_aligned[wdata_hartsel] = 1'b1;
					halted_d_aligned[wdata_hartsel] = 1'b1;
				end
				else if (((GoingAddr ^ GoingAddr) !== ((addr_i[DbgAddressBits - 1:0] ^ addr_i[DbgAddressBits - 1:0]) ^ (GoingAddr ^ GoingAddr)) ? 1'bx : (GoingAddr ^ GoingAddr) === (GoingAddr ^ addr_i[DbgAddressBits - 1:0])))
					going = 1'b1;
				else if (((ResumingAddr ^ ResumingAddr) !== ((addr_i[DbgAddressBits - 1:0] ^ addr_i[DbgAddressBits - 1:0]) ^ (ResumingAddr ^ ResumingAddr)) ? 1'bx : (ResumingAddr ^ ResumingAddr) === (ResumingAddr ^ addr_i[DbgAddressBits - 1:0]))) begin
					halted_d_aligned[wdata_hartsel] = 1'b0;
					resuming_d_aligned[wdata_hartsel] = 1'b1;
				end
				else if (((ExceptionAddr ^ ExceptionAddr) !== ((addr_i[DbgAddressBits - 1:0] ^ addr_i[DbgAddressBits - 1:0]) ^ (ExceptionAddr ^ ExceptionAddr)) ? 1'bx : (ExceptionAddr ^ ExceptionAddr) === (ExceptionAddr ^ addr_i[DbgAddressBits - 1:0])))
					exception = 1'b1;
				else if ((dm_DataAddr <= addr_i[DbgAddressBits - 1:0]) && (DataEndAddr >= addr_i[DbgAddressBits - 1:0])) begin
					data_valid_o = 1'b1;
					begin : sv2v_autoblock_150
						reg signed [31:0] i;
						for (i = 0; i < (((BusWidth / 8) - 1) >= 0 ? BusWidth / 8 : 2 - (BusWidth / 8)); i = i + 1)
							if (be_i[i])
								data_bits[i * 8+:8] = wdata_i[i * 8+:8];
					end
				end
			end
			else if (((WhereToAddr ^ WhereToAddr) !== ((addr_i[DbgAddressBits - 1:0] ^ addr_i[DbgAddressBits - 1:0]) ^ (WhereToAddr ^ WhereToAddr)) ? 1'bx : (WhereToAddr ^ WhereToAddr) === (WhereToAddr ^ addr_i[DbgAddressBits - 1:0]))) begin
				if (resumereq_wdata_aligned[wdata_hartsel])
					rdata_d = {32'b0, dm_jal(1'sb0, sv2v_cast_21(dm_ResumeAddress[11:0]) - sv2v_cast_21(WhereToAddr))};
				if (cmdbusy_o)
					if (((cmd_i[31-:8] == dm_AccessRegister) && !ac_ar[17]) && ac_ar[18])
						rdata_d = {32'b0, dm_jal(1'sb0, sv2v_cast_21(ProgBufBaseAddr) - sv2v_cast_21(WhereToAddr))};
					else
						rdata_d = {32'b0, dm_jal(1'sb0, sv2v_cast_21(AbstractCmdBaseAddr) - sv2v_cast_21(WhereToAddr))};
			end
			else if ((DataBaseAddr <= addr_i[DbgAddressBits - 1:0]) && (DataEndAddr >= addr_i[DbgAddressBits - 1:0]))
				rdata_d = {data_i[((dm_DataCount - 1) >= 0 ? sv2v_cast_D971A((addr_i[DbgAddressBits - 1:3] - DataBaseAddr[DbgAddressBits - 1:3]) + 1'b1) : 0 - (sv2v_cast_D971A((addr_i[DbgAddressBits - 1:3] - DataBaseAddr[DbgAddressBits - 1:3]) + 1'b1) - (dm_DataCount - 1))) * 32+:32], data_i[((dm_DataCount - 1) >= 0 ? sv2v_cast_D971A(addr_i[DbgAddressBits - 1:3] - DataBaseAddr[DbgAddressBits - 1:3]) : 0 - (sv2v_cast_D971A(addr_i[DbgAddressBits - 1:3] - DataBaseAddr[DbgAddressBits - 1:3]) - (dm_DataCount - 1))) * 32+:32]};
			else if ((ProgBufBaseAddr <= addr_i[DbgAddressBits - 1:0]) && (ProgBufEndAddr >= addr_i[DbgAddressBits - 1:0]))
				rdata_d = progbuf[(((dm_ProgBufSize / 2) - 1) >= 0 ? sv2v_cast_D971A(addr_i[DbgAddressBits - 1:3] - ProgBufBaseAddr[DbgAddressBits - 1:3]) : 0 - (sv2v_cast_D971A(addr_i[DbgAddressBits - 1:3] - ProgBufBaseAddr[DbgAddressBits - 1:3]) - ((dm_ProgBufSize / 2) - 1))) * 64+:64];
			else if ((AbstractCmdBaseAddr <= addr_i[DbgAddressBits - 1:0]) && (AbstractCmdEndAddr >= addr_i[DbgAddressBits - 1:0]))
				rdata_d = abstract_cmd[sv2v_cast_3(addr_i[DbgAddressBits - 1:3] - AbstractCmdBaseAddr[DbgAddressBits - 1:3]) * 64+:64];
			else if ((FlagsBaseAddr <= addr_i[DbgAddressBits - 1:0]) && (FlagsEndAddr >= addr_i[DbgAddressBits - 1:0])) begin
				if (({addr_i[DbgAddressBits - 1:3], 3'b0} - FlagsBaseAddr[DbgAddressBits - 1:0]) == (sv2v_cast_12(hartsel) & {{DbgAddressBits - 3 {1'b1}}, 3'b0}))
					rdata[(sv2v_cast_12(hartsel) & sv2v_cast_12(3'b111)) * 8+:8] = {6'b0, resume, go};
				rdata_d = rdata;
			end
		data_o = data_bits;
	end
	always @(*) begin : p_abstract_cmd_rom
		unsupported_command = 1'b0;
		abstract_cmd[31-:32] = dm_illegal(0);
		abstract_cmd[63-:32] = dm_auipc(5'd10, 1'sb0);
		abstract_cmd[95-:32] = dm_srli(5'd10, 5'd10, 6'd12);
		abstract_cmd[127-:32] = dm_slli(5'd10, 5'd10, 6'd12);
		abstract_cmd[159-:32] = dm_nop(0);
		abstract_cmd[191-:32] = dm_nop(0);
		abstract_cmd[223-:32] = dm_nop(0);
		abstract_cmd[255-:32] = dm_nop(0);
		abstract_cmd[287-:32] = dm_csrr(dm_CSR_DSCRATCH1, 5'd10);
		abstract_cmd[319-:32] = dm_ebreak(0);
		abstract_cmd[320+:192] = 1'sb0;
		case (cmd_i[31-:8])
			dm_AccessRegister: begin
				if (((sv2v_cast_32(ac_ar[22-:3]) < MaxAar) && ac_ar[17]) && ac_ar[16]) begin
					abstract_cmd[31-:32] = dm_csrw(dm_CSR_DSCRATCH1, 5'd10);
					if (ac_ar[15:14] != 1'sb0) begin
						abstract_cmd[31-:32] = dm_ebreak(0);
						unsupported_command = 1'b1;
					end
					else if ((ac_ar[12] && !ac_ar[5]) && (ac_ar[4:0] == 5'd10)) begin
						abstract_cmd[159-:32] = dm_csrw(dm_CSR_DSCRATCH0, 5'd8);
						abstract_cmd[191-:32] = dm_load(ac_ar[22-:3], 5'd8, 5'd10, dm_DataAddr);
						abstract_cmd[223-:32] = dm_csrw(dm_CSR_DSCRATCH1, 5'd8);
						abstract_cmd[255-:32] = dm_csrr(dm_CSR_DSCRATCH0, 5'd8);
					end
					else if (ac_ar[12]) begin
						if (ac_ar[5])
							abstract_cmd[159-:32] = dm_float_load(ac_ar[22-:3], ac_ar[4:0], 5'd10, dm_DataAddr);
						else
							abstract_cmd[159-:32] = dm_load(ac_ar[22-:3], ac_ar[4:0], 5'd10, dm_DataAddr);
					end
					else begin
						abstract_cmd[159-:32] = dm_csrw(dm_CSR_DSCRATCH0, 5'd8);
						abstract_cmd[191-:32] = dm_load(ac_ar[22-:3], 5'd8, 5'd10, dm_DataAddr);
						abstract_cmd[223-:32] = dm_csrw(sv2v_cast_12(ac_ar[11:0]), 5'd8);
						abstract_cmd[255-:32] = dm_csrr(dm_CSR_DSCRATCH0, 5'd8);
					end
				end
				else if (((sv2v_cast_32(ac_ar[22-:3]) < MaxAar) && ac_ar[17]) && !ac_ar[16]) begin
					abstract_cmd[31-:32] = dm_csrw(dm_CSR_DSCRATCH1, 5'd10);
					if (ac_ar[15:14] != 1'sb0) begin
						abstract_cmd[31-:32] = dm_ebreak(0);
						unsupported_command = 1'b1;
					end
					else if ((ac_ar[12] && !ac_ar[5]) && (ac_ar[4:0] == 5'd10)) begin
						abstract_cmd[159-:32] = dm_csrw(dm_CSR_DSCRATCH0, 5'd8);
						abstract_cmd[191-:32] = dm_csrr(dm_CSR_DSCRATCH1, 5'd8);
						abstract_cmd[223-:32] = dm_store(ac_ar[22-:3], 5'd8, 5'd10, dm_DataAddr);
						abstract_cmd[255-:32] = dm_csrr(dm_CSR_DSCRATCH0, 5'd8);
					end
					else if (ac_ar[12]) begin
						if (ac_ar[5])
							abstract_cmd[159-:32] = dm_float_store(ac_ar[22-:3], ac_ar[4:0], 5'd10, dm_DataAddr);
						else
							abstract_cmd[159-:32] = dm_store(ac_ar[22-:3], ac_ar[4:0], 5'd10, dm_DataAddr);
					end
					else begin
						abstract_cmd[159-:32] = dm_csrw(dm_CSR_DSCRATCH0, 5'd8);
						abstract_cmd[191-:32] = dm_csrr(sv2v_cast_12(ac_ar[11:0]), 5'd8);
						abstract_cmd[223-:32] = dm_store(ac_ar[22-:3], 5'd8, 5'd10, dm_DataAddr);
						abstract_cmd[255-:32] = dm_csrr(dm_CSR_DSCRATCH0, 5'd8);
					end
				end
				else if ((sv2v_cast_32(ac_ar[22-:3]) >= MaxAar) || (ac_ar[19] == 1'b1)) begin
					abstract_cmd[31-:32] = dm_ebreak(0);
					unsupported_command = 1'b1;
				end
				if (ac_ar[18] && !unsupported_command)
					abstract_cmd[319-:32] = dm_nop(0);
			end
			default: begin
				abstract_cmd[31-:32] = dm_ebreak(0);
				unsupported_command = 1'b1;
			end
		endcase
	end
	wire [63:0] rom_addr;
	assign rom_addr = sv2v_cast_64(addr_i);
	debug_rom i_debug_rom(
		.clk_i(clk_i),
		.req_i(req_i),
		.addr_i(rom_addr),
		.rdata_o(rom_rdata)
	);
	assign fwd_rom_d = sv2v_cast_1(addr_i[DbgAddressBits - 1:0] >= dm_HaltAddress[DbgAddressBits - 1:0]);
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			fwd_rom_q <= 1'b0;
			rdata_q <= 1'sb0;
			state_q <= Idle;
			word_enable32_q <= 1'b0;
		end
		else begin
			fwd_rom_q <= fwd_rom_d;
			rdata_q <= rdata_d;
			state_q <= state_d;
			word_enable32_q <= addr_i[2];
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			halted_q <= 1'b0;
			resuming_q <= 1'b0;
		end
		else begin
			halted_q <= SelectableHarts & halted_d;
			resuming_q <= SelectableHarts & resuming_d;
		end
	function automatic [31:0] dm_auipc;
		input reg [4:0] rd;
		input reg [20:0] imm;
		dm_auipc = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
	endfunction
	function automatic [31:0] dm_csrr;
		input reg [11:0] csr;
		input reg [4:0] dest;
		dm_csrr = {csr, 5'h0, 3'h2, dest, 7'h73};
	endfunction
	function automatic [31:0] dm_csrw;
		input reg [11:0] csr;
		input reg [4:0] rs1;
		dm_csrw = {csr, rs1, 3'h1, 5'h0, 7'h73};
	endfunction
	function automatic [31:0] dm_ebreak;
		input _sv2v_unused;
		dm_ebreak = 32'h00100073;
	endfunction
	function automatic [31:0] dm_float_load;
		input reg [2:0] size;
		input reg [4:0] dest;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_float_load = {offset[11:0], base, size, dest, 7'b00_001_11};
	endfunction
	function automatic [31:0] dm_float_store;
		input reg [2:0] size;
		input reg [4:0] src;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_float_store = {offset[11:5], src, base, size, offset[4:0], 7'b01_001_11};
	endfunction
	function automatic [31:0] dm_illegal;
		input _sv2v_unused;
		dm_illegal = 32'h00000000;
	endfunction
	function automatic [31:0] dm_jal;
		input reg [4:0] rd;
		input reg [20:0] imm;
		dm_jal = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
	endfunction
	function automatic [31:0] dm_load;
		input reg [2:0] size;
		input reg [4:0] dest;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_load = {offset[11:0], base, size, dest, 7'h03};
	endfunction
	function automatic [31:0] dm_nop;
		input _sv2v_unused;
		dm_nop = 32'h00000013;
	endfunction
	function automatic [31:0] dm_slli;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [5:0] shamt;
		dm_slli = {6'b0, shamt[5:0], rs1, 3'h1, rd, 7'h13};
	endfunction
	function automatic [31:0] dm_srli;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [5:0] shamt;
		dm_srli = {6'b0, shamt[5:0], rs1, 3'h5, rd, 7'h13};
	endfunction
	function automatic [31:0] dm_store;
		input reg [2:0] size;
		input reg [4:0] src;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_store = {offset[11:5], src, base, size, offset[4:0], 7'h23};
	endfunction
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	function automatic [20:0] sv2v_cast_21;
		input reg [20:0] inp;
		sv2v_cast_21 = inp;
	endfunction
	function automatic [23:0] sv2v_cast_24;
		input reg [23:0] inp;
		sv2v_cast_24 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [(2 ** (NrHarts == 1 ? 1 : $clog2(NrHarts))) - 1:0] sv2v_cast_4CE25;
		input reg [(2 ** (NrHarts == 1 ? 1 : $clog2(NrHarts))) - 1:0] inp;
		sv2v_cast_4CE25 = inp;
	endfunction
	function automatic [NrHarts - 1:0] sv2v_cast_50608;
		input reg [NrHarts - 1:0] inp;
		sv2v_cast_50608 = inp;
	endfunction
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	function automatic [$clog2(dm_ProgBufSize) - 1:0] sv2v_cast_D971A;
		input reg [$clog2(dm_ProgBufSize) - 1:0] inp;
		sv2v_cast_D971A = inp;
	endfunction
endmodule
