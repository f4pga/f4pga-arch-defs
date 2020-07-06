module dmi_jtag_tap (
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o,
	tdo_oe_o,
	testmode_i,
	test_logic_reset_o,
	shift_dr_o,
	update_dr_o,
	capture_dr_o,
	dmi_access_o,
	dtmcs_select_o,
	dmi_reset_o,
	dmi_error_i,
	dmi_tdi_o,
	dmi_tdo_i
);
	localparam [IrLength - 1:0] BYPASS0 = 'h0;
	localparam [IrLength - 1:0] IDCODE = 'h1;
	localparam [IrLength - 1:0] DTMCSR = 'h10;
	localparam [IrLength - 1:0] DMIACCESS = 'h11;
	localparam [IrLength - 1:0] BYPASS1 = 'h1f;
	localparam [3:0] TestLogicReset = 0;
	localparam [3:0] RunTestIdle = 1;
	localparam [3:0] CaptureIr = 10;
	localparam [3:0] ShiftIr = 11;
	localparam [3:0] Exit1Ir = 12;
	localparam [3:0] PauseIr = 13;
	localparam [3:0] Exit2Ir = 14;
	localparam [3:0] UpdateIr = 15;
	localparam [3:0] SelectDrScan = 2;
	localparam [3:0] CaptureDr = 3;
	localparam [3:0] ShiftDr = 4;
	localparam [3:0] Exit1Dr = 5;
	localparam [3:0] PauseDr = 6;
	localparam [3:0] Exit2Dr = 7;
	localparam [3:0] UpdateDr = 8;
	localparam [3:0] SelectIrScan = 9;
	parameter [31:0] IrLength = 5;
	parameter [31:0] IdcodeValue = 32'h00000001;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output reg td_o;
	output reg tdo_oe_o;
	input wire testmode_i;
	output reg test_logic_reset_o;
	output reg shift_dr_o;
	output reg update_dr_o;
	output reg capture_dr_o;
	output reg dmi_access_o;
	output reg dtmcs_select_o;
	output wire dmi_reset_o;
	input wire [1:0] dmi_error_i;
	output wire dmi_tdi_o;
	input wire dmi_tdo_i;
	assign dmi_tdi_o = td_i;
	reg [3:0] tap_state_q;
	reg [3:0] tap_state_d;
	reg [IrLength - 1:0] jtag_ir_shift_d;
	reg [IrLength - 1:0] jtag_ir_shift_q;
	reg [IrLength - 1:0] jtag_ir_d;
	reg [IrLength - 1:0] jtag_ir_q;
	reg capture_ir;
	reg shift_ir;
	reg update_ir;
	always @(*) begin : p_jtag
		jtag_ir_shift_d = jtag_ir_shift_q;
		jtag_ir_d = jtag_ir_q;
		if (shift_ir)
			jtag_ir_shift_d = {td_i, jtag_ir_shift_q[IrLength - 1:1]};
		if (capture_ir)
			jtag_ir_shift_d = sv2v_cast_AFF3E(4'b0101);
		if (update_ir)
			jtag_ir_d = sv2v_cast_5F17A(jtag_ir_shift_q);
		if (test_logic_reset_o) begin
			jtag_ir_shift_d = 1'sb0;
			jtag_ir_d = IDCODE;
		end
	end
	always @(posedge tck_i or negedge trst_ni) begin : p_jtag_ir_reg
		if (!trst_ni) begin
			jtag_ir_shift_q <= 1'sb0;
			jtag_ir_q <= IDCODE;
		end
		else begin
			jtag_ir_shift_q <= jtag_ir_shift_d;
			jtag_ir_q <= jtag_ir_d;
		end
	end
	reg [31:0] idcode_d;
	reg [31:0] idcode_q;
	reg idcode_select;
	reg bypass_select;
	reg [31:0] dtmcs_d;
	reg [31:0] dtmcs_q;
	reg bypass_d;
	reg bypass_q;
	assign dmi_reset_o = dtmcs_q[16];
	always @(*) begin
		idcode_d = idcode_q;
		bypass_d = bypass_q;
		dtmcs_d = dtmcs_q;
		if (capture_dr_o) begin
			if (idcode_select)
				idcode_d = IdcodeValue;
			if (bypass_select)
				bypass_d = 1'b0;
			if (dtmcs_select_o)
				dtmcs_d = sv2v_struct_1D1C7(1'sb0, 1'b0, 1'b0, 1'sb0, 3'd1, dmi_error_i, 6'd7, 4'd1);
		end
		if (shift_dr_o) begin
			if (idcode_select)
				idcode_d = {td_i, sv2v_cast_31(idcode_q >> 1)};
			if (bypass_select)
				bypass_d = td_i;
			if (dtmcs_select_o)
				dtmcs_d = {td_i, sv2v_cast_31(dtmcs_q >> 1)};
		end
		if (test_logic_reset_o) begin
			idcode_d = IdcodeValue;
			bypass_d = 1'b0;
		end
	end
	always @(*) begin : p_data_reg_sel
		dmi_access_o = 1'b0;
		dtmcs_select_o = 1'b0;
		idcode_select = 1'b0;
		bypass_select = 1'b0;
		case (jtag_ir_q)
			BYPASS0: bypass_select = 1'b1;
			IDCODE: idcode_select = 1'b1;
			DTMCSR: dtmcs_select_o = 1'b1;
			DMIACCESS: dmi_access_o = 1'b1;
			BYPASS1: bypass_select = 1'b1;
			default: bypass_select = 1'b1;
		endcase
	end
	reg tdo_mux;
	always @(*) begin : p_out_sel
		if (shift_ir)
			tdo_mux = jtag_ir_shift_q[0];
		else
			case (jtag_ir_q)
				IDCODE: tdo_mux = idcode_q[0];
				DTMCSR: tdo_mux = dtmcs_q[0];
				DMIACCESS: tdo_mux = dmi_tdo_i;
				default: tdo_mux = bypass_q;
			endcase
	end
	wire tck_n;
	prim_clock_inverter #(.HasScanMode(1'b1)) i_tck_inv(
		.clk_i(tck_i),
		.clk_no(tck_n),
		.scanmode_i(testmode_i)
	);
	always @(posedge tck_n or negedge trst_ni) begin : p_tdo_regs
		if (!trst_ni) begin
			td_o <= 1'b0;
			tdo_oe_o <= 1'b0;
		end
		else begin
			td_o <= tdo_mux;
			tdo_oe_o <= shift_ir | shift_dr_o;
		end
	end
	always @(*) begin : p_tap_fsm
		test_logic_reset_o = 1'b0;
		capture_dr_o = 1'b0;
		shift_dr_o = 1'b0;
		update_dr_o = 1'b0;
		capture_ir = 1'b0;
		shift_ir = 1'b0;
		update_ir = 1'b0;
		case (tap_state_q)
			TestLogicReset: begin
				tap_state_d = (tms_i ? TestLogicReset : RunTestIdle);
				test_logic_reset_o = 1'b1;
			end
			RunTestIdle: tap_state_d = (tms_i ? SelectDrScan : RunTestIdle);
			SelectDrScan: tap_state_d = (tms_i ? SelectIrScan : CaptureDr);
			CaptureDr: begin
				capture_dr_o = 1'b1;
				tap_state_d = (tms_i ? Exit1Dr : ShiftDr);
			end
			ShiftDr: begin
				shift_dr_o = 1'b1;
				tap_state_d = (tms_i ? Exit1Dr : ShiftDr);
			end
			Exit1Dr: tap_state_d = (tms_i ? UpdateDr : PauseDr);
			PauseDr: tap_state_d = (tms_i ? Exit2Dr : PauseDr);
			Exit2Dr: tap_state_d = (tms_i ? UpdateDr : ShiftDr);
			UpdateDr: begin
				update_dr_o = 1'b1;
				tap_state_d = (tms_i ? SelectDrScan : RunTestIdle);
			end
			SelectIrScan: tap_state_d = (tms_i ? TestLogicReset : CaptureIr);
			CaptureIr: begin
				capture_ir = 1'b1;
				tap_state_d = (tms_i ? Exit1Ir : ShiftIr);
			end
			ShiftIr: begin
				shift_ir = 1'b1;
				tap_state_d = (tms_i ? Exit1Ir : ShiftIr);
			end
			Exit1Ir: tap_state_d = (tms_i ? UpdateIr : PauseIr);
			PauseIr: tap_state_d = (tms_i ? Exit2Ir : PauseIr);
			Exit2Ir: tap_state_d = (tms_i ? UpdateIr : ShiftIr);
			UpdateIr: begin
				update_ir = 1'b1;
				tap_state_d = (tms_i ? SelectDrScan : RunTestIdle);
			end
			default:
				;
		endcase
	end
	always @(posedge tck_i or negedge trst_ni) begin : p_regs
		if (!trst_ni) begin
			tap_state_q <= RunTestIdle;
			idcode_q <= IdcodeValue;
			bypass_q <= 1'b0;
			dtmcs_q <= 1'sb0;
		end
		else begin
			tap_state_q <= tap_state_d;
			idcode_q <= idcode_d;
			bypass_q <= bypass_d;
			dtmcs_q <= dtmcs_d;
		end
	end
	function automatic [31:0] sv2v_struct_1D1C7;
		input reg [31:18] zero1;
		input reg dmihardreset;
		input reg dmireset;
		input reg zero0;
		input reg [14:12] idle;
		input reg [11:10] dmistat;
		input reg [9:4] abits;
		input reg [3:0] version;
		sv2v_struct_1D1C7 = {zero1, dmihardreset, dmireset, zero0, idle, dmistat, abits, version};
	endfunction
	function automatic [30:0] sv2v_cast_31;
		input reg [30:0] inp;
		sv2v_cast_31 = inp;
	endfunction
	function automatic [((IrLength - 1) >= 0 ? IrLength : 2 - IrLength) - 1:0] sv2v_cast_5F17A;
		input reg [((IrLength - 1) >= 0 ? IrLength : 2 - IrLength) - 1:0] inp;
		sv2v_cast_5F17A = inp;
	endfunction
	function automatic [IrLength - 1:0] sv2v_cast_AFF3E;
		input reg [IrLength - 1:0] inp;
		sv2v_cast_AFF3E = inp;
	endfunction
endmodule
