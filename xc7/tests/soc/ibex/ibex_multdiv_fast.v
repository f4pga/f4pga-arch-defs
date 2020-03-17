module ibex_multdiv_fast (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero,
	alu_operand_a_o,
	alu_operand_b_o,
	multdiv_result_o,
	valid_o
);
	localparam [2:0] MD_IDLE = 0;
	localparam [2:0] MD_ABS_A = 1;
	localparam [2:0] MD_ABS_B = 2;
	localparam [2:0] MD_COMP = 3;
	localparam [2:0] MD_LAST = 4;
	localparam [2:0] MD_CHANGE_SIGN = 5;
	localparam [2:0] MD_FINISH = 6;
	parameter SingleCycleMultiply = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	parameter [31:0] PMP_MAX_REGIONS = 16;
	parameter [31:0] PMP_CFG_W = 8;
	parameter [31:0] PMP_I = 0;
	parameter [31:0] PMP_D = 1;
	parameter [11:0] CSR_OFF_PMP_CFG = 12'h3A0;
	parameter [11:0] CSR_OFF_PMP_ADDR = 12'h3B0;
	parameter [31:0] CSR_MSTATUS_MIE_BIT = 3;
	parameter [31:0] CSR_MSTATUS_MPIE_BIT = 7;
	parameter [31:0] CSR_MSTATUS_MPP_BIT_LOW = 11;
	parameter [31:0] CSR_MSTATUS_MPP_BIT_HIGH = 12;
	parameter [31:0] CSR_MSTATUS_MPRV_BIT = 17;
	parameter [31:0] CSR_MSTATUS_TW_BIT = 21;
	parameter [31:0] CSR_MSIX_BIT = 3;
	parameter [31:0] CSR_MTIX_BIT = 7;
	parameter [31:0] CSR_MEIX_BIT = 11;
	parameter [31:0] CSR_MFIX_BIT_LOW = 16;
	parameter [31:0] CSR_MFIX_BIT_HIGH = 30;
	localparam [0:0] IMM_A_Z = 0;
	localparam [0:0] JT_ALU = 0;
	localparam [0:0] OP_B_REG_B = 0;
	localparam [1:0] CSR_OP_READ = 0;
	localparam [1:0] EXC_PC_EXC = 0;
	localparam [1:0] MD_OP_MULL = 0;
	localparam [1:0] OP_A_REG_A = 0;
	localparam [1:0] RF_WD_LSU = 0;
	localparam [2:0] IMM_B_I = 0;
	localparam [2:0] PC_BOOT = 0;
	localparam [4:0] ALU_ADD = 0;
	localparam [0:0] IMM_A_ZERO = 1;
	localparam [0:0] JT_BT_ALU = 1;
	localparam [0:0] OP_B_IMM = 1;
	localparam [1:0] CSR_OP_WRITE = 1;
	localparam [1:0] EXC_PC_IRQ = 1;
	localparam [1:0] MD_OP_MULH = 1;
	localparam [1:0] OP_A_FWD = 1;
	localparam [1:0] RF_WD_EX = 1;
	localparam [2:0] IMM_B_S = 1;
	localparam [2:0] PC_JUMP = 1;
	localparam [4:0] ALU_SUB = 1;
	localparam [4:0] ALU_GE = 10;
	localparam [4:0] ALU_GEU = 11;
	localparam [4:0] ALU_EQ = 12;
	localparam [11:0] CSR_MSTATUS = 12'h300;
	localparam [11:0] CSR_MISA = 12'h301;
	localparam [11:0] CSR_MIE = 12'h304;
	localparam [11:0] CSR_MTVEC = 12'h305;
	localparam [11:0] CSR_MCOUNTINHIBIT = 12'h320;
	localparam [11:0] CSR_MHPMEVENT3 = 12'h323;
	localparam [11:0] CSR_MHPMEVENT4 = 12'h324;
	localparam [11:0] CSR_MHPMEVENT5 = 12'h325;
	localparam [11:0] CSR_MHPMEVENT6 = 12'h326;
	localparam [11:0] CSR_MHPMEVENT7 = 12'h327;
	localparam [11:0] CSR_MHPMEVENT8 = 12'h328;
	localparam [11:0] CSR_MHPMEVENT9 = 12'h329;
	localparam [11:0] CSR_MHPMEVENT10 = 12'h32A;
	localparam [11:0] CSR_MHPMEVENT11 = 12'h32B;
	localparam [11:0] CSR_MHPMEVENT12 = 12'h32C;
	localparam [11:0] CSR_MHPMEVENT13 = 12'h32D;
	localparam [11:0] CSR_MHPMEVENT14 = 12'h32E;
	localparam [11:0] CSR_MHPMEVENT15 = 12'h32F;
	localparam [11:0] CSR_MHPMEVENT16 = 12'h330;
	localparam [11:0] CSR_MHPMEVENT17 = 12'h331;
	localparam [11:0] CSR_MHPMEVENT18 = 12'h332;
	localparam [11:0] CSR_MHPMEVENT19 = 12'h333;
	localparam [11:0] CSR_MHPMEVENT20 = 12'h334;
	localparam [11:0] CSR_MHPMEVENT21 = 12'h335;
	localparam [11:0] CSR_MHPMEVENT22 = 12'h336;
	localparam [11:0] CSR_MHPMEVENT23 = 12'h337;
	localparam [11:0] CSR_MHPMEVENT24 = 12'h338;
	localparam [11:0] CSR_MHPMEVENT25 = 12'h339;
	localparam [11:0] CSR_MHPMEVENT26 = 12'h33A;
	localparam [11:0] CSR_MHPMEVENT27 = 12'h33B;
	localparam [11:0] CSR_MHPMEVENT28 = 12'h33C;
	localparam [11:0] CSR_MHPMEVENT29 = 12'h33D;
	localparam [11:0] CSR_MHPMEVENT30 = 12'h33E;
	localparam [11:0] CSR_MHPMEVENT31 = 12'h33F;
	localparam [11:0] CSR_MSCRATCH = 12'h340;
	localparam [11:0] CSR_MEPC = 12'h341;
	localparam [11:0] CSR_MCAUSE = 12'h342;
	localparam [11:0] CSR_MTVAL = 12'h343;
	localparam [11:0] CSR_MIP = 12'h344;
	localparam [11:0] CSR_PMPCFG0 = 12'h3A0;
	localparam [11:0] CSR_PMPCFG1 = 12'h3A1;
	localparam [11:0] CSR_PMPCFG2 = 12'h3A2;
	localparam [11:0] CSR_PMPCFG3 = 12'h3A3;
	localparam [11:0] CSR_PMPADDR0 = 12'h3B0;
	localparam [11:0] CSR_PMPADDR1 = 12'h3B1;
	localparam [11:0] CSR_PMPADDR2 = 12'h3B2;
	localparam [11:0] CSR_PMPADDR3 = 12'h3B3;
	localparam [11:0] CSR_PMPADDR4 = 12'h3B4;
	localparam [11:0] CSR_PMPADDR5 = 12'h3B5;
	localparam [11:0] CSR_PMPADDR6 = 12'h3B6;
	localparam [11:0] CSR_PMPADDR7 = 12'h3B7;
	localparam [11:0] CSR_PMPADDR8 = 12'h3B8;
	localparam [11:0] CSR_PMPADDR9 = 12'h3B9;
	localparam [11:0] CSR_PMPADDR10 = 12'h3BA;
	localparam [11:0] CSR_PMPADDR11 = 12'h3BB;
	localparam [11:0] CSR_PMPADDR12 = 12'h3BC;
	localparam [11:0] CSR_PMPADDR13 = 12'h3BD;
	localparam [11:0] CSR_PMPADDR14 = 12'h3BE;
	localparam [11:0] CSR_PMPADDR15 = 12'h3BF;
	localparam [11:0] CSR_TSELECT = 12'h7A0;
	localparam [11:0] CSR_TDATA1 = 12'h7A1;
	localparam [11:0] CSR_TDATA2 = 12'h7A2;
	localparam [11:0] CSR_TDATA3 = 12'h7A3;
	localparam [11:0] CSR_MCONTEXT = 12'h7A8;
	localparam [11:0] CSR_SCONTEXT = 12'h7AA;
	localparam [11:0] CSR_DCSR = 12'h7b0;
	localparam [11:0] CSR_DPC = 12'h7b1;
	localparam [11:0] CSR_DSCRATCH0 = 12'h7b2;
	localparam [11:0] CSR_DSCRATCH1 = 12'h7b3;
	localparam [11:0] CSR_MCYCLE = 12'hB00;
	localparam [11:0] CSR_MINSTRET = 12'hB02;
	localparam [11:0] CSR_MHPMCOUNTER3 = 12'hB03;
	localparam [11:0] CSR_MHPMCOUNTER4 = 12'hB04;
	localparam [11:0] CSR_MHPMCOUNTER5 = 12'hB05;
	localparam [11:0] CSR_MHPMCOUNTER6 = 12'hB06;
	localparam [11:0] CSR_MHPMCOUNTER7 = 12'hB07;
	localparam [11:0] CSR_MHPMCOUNTER8 = 12'hB08;
	localparam [11:0] CSR_MHPMCOUNTER9 = 12'hB09;
	localparam [11:0] CSR_MHPMCOUNTER10 = 12'hB0A;
	localparam [11:0] CSR_MHPMCOUNTER11 = 12'hB0B;
	localparam [11:0] CSR_MHPMCOUNTER12 = 12'hB0C;
	localparam [11:0] CSR_MHPMCOUNTER13 = 12'hB0D;
	localparam [11:0] CSR_MHPMCOUNTER14 = 12'hB0E;
	localparam [11:0] CSR_MHPMCOUNTER15 = 12'hB0F;
	localparam [11:0] CSR_MHPMCOUNTER16 = 12'hB10;
	localparam [11:0] CSR_MHPMCOUNTER17 = 12'hB11;
	localparam [11:0] CSR_MHPMCOUNTER18 = 12'hB12;
	localparam [11:0] CSR_MHPMCOUNTER19 = 12'hB13;
	localparam [11:0] CSR_MHPMCOUNTER20 = 12'hB14;
	localparam [11:0] CSR_MHPMCOUNTER21 = 12'hB15;
	localparam [11:0] CSR_MHPMCOUNTER22 = 12'hB16;
	localparam [11:0] CSR_MHPMCOUNTER23 = 12'hB17;
	localparam [11:0] CSR_MHPMCOUNTER24 = 12'hB18;
	localparam [11:0] CSR_MHPMCOUNTER25 = 12'hB19;
	localparam [11:0] CSR_MHPMCOUNTER26 = 12'hB1A;
	localparam [11:0] CSR_MHPMCOUNTER27 = 12'hB1B;
	localparam [11:0] CSR_MHPMCOUNTER28 = 12'hB1C;
	localparam [11:0] CSR_MHPMCOUNTER29 = 12'hB1D;
	localparam [11:0] CSR_MHPMCOUNTER30 = 12'hB1E;
	localparam [11:0] CSR_MHPMCOUNTER31 = 12'hB1F;
	localparam [11:0] CSR_MCYCLEH = 12'hB80;
	localparam [11:0] CSR_MINSTRETH = 12'hB82;
	localparam [11:0] CSR_MHPMCOUNTER3H = 12'hB83;
	localparam [11:0] CSR_MHPMCOUNTER4H = 12'hB84;
	localparam [11:0] CSR_MHPMCOUNTER5H = 12'hB85;
	localparam [11:0] CSR_MHPMCOUNTER6H = 12'hB86;
	localparam [11:0] CSR_MHPMCOUNTER7H = 12'hB87;
	localparam [11:0] CSR_MHPMCOUNTER8H = 12'hB88;
	localparam [11:0] CSR_MHPMCOUNTER9H = 12'hB89;
	localparam [11:0] CSR_MHPMCOUNTER10H = 12'hB8A;
	localparam [11:0] CSR_MHPMCOUNTER11H = 12'hB8B;
	localparam [11:0] CSR_MHPMCOUNTER12H = 12'hB8C;
	localparam [11:0] CSR_MHPMCOUNTER13H = 12'hB8D;
	localparam [11:0] CSR_MHPMCOUNTER14H = 12'hB8E;
	localparam [11:0] CSR_MHPMCOUNTER15H = 12'hB8F;
	localparam [11:0] CSR_MHPMCOUNTER16H = 12'hB90;
	localparam [11:0] CSR_MHPMCOUNTER17H = 12'hB91;
	localparam [11:0] CSR_MHPMCOUNTER18H = 12'hB92;
	localparam [11:0] CSR_MHPMCOUNTER19H = 12'hB93;
	localparam [11:0] CSR_MHPMCOUNTER20H = 12'hB94;
	localparam [11:0] CSR_MHPMCOUNTER21H = 12'hB95;
	localparam [11:0] CSR_MHPMCOUNTER22H = 12'hB96;
	localparam [11:0] CSR_MHPMCOUNTER23H = 12'hB97;
	localparam [11:0] CSR_MHPMCOUNTER24H = 12'hB98;
	localparam [11:0] CSR_MHPMCOUNTER25H = 12'hB99;
	localparam [11:0] CSR_MHPMCOUNTER26H = 12'hB9A;
	localparam [11:0] CSR_MHPMCOUNTER27H = 12'hB9B;
	localparam [11:0] CSR_MHPMCOUNTER28H = 12'hB9C;
	localparam [11:0] CSR_MHPMCOUNTER29H = 12'hB9D;
	localparam [11:0] CSR_MHPMCOUNTER30H = 12'hB9E;
	localparam [11:0] CSR_MHPMCOUNTER31H = 12'hB9F;
	localparam [11:0] CSR_MHARTID = 12'hF14;
	localparam [4:0] ALU_NE = 13;
	localparam [4:0] ALU_SLT = 14;
	localparam [4:0] ALU_SLTU = 15;
	localparam [1:0] CSR_OP_SET = 2;
	localparam [1:0] EXC_PC_DBD = 2;
	localparam [1:0] MD_OP_DIV = 2;
	localparam [1:0] OP_A_CURRPC = 2;
	localparam [1:0] RF_WD_CSR = 2;
	localparam [2:0] IMM_B_B = 2;
	localparam [2:0] PC_EXC = 2;
	localparam [4:0] ALU_XOR = 2;
	localparam [1:0] PMP_ACC_EXEC = 2'b00;
	localparam [1:0] PMP_MODE_OFF = 2'b00;
	localparam [1:0] PRIV_LVL_U = 2'b00;
	localparam [1:0] PMP_ACC_WRITE = 2'b01;
	localparam [1:0] PMP_MODE_TOR = 2'b01;
	localparam [1:0] PRIV_LVL_S = 2'b01;
	localparam [1:0] PMP_ACC_READ = 2'b10;
	localparam [1:0] PMP_MODE_NA4 = 2'b10;
	localparam [1:0] PRIV_LVL_H = 2'b10;
	localparam [1:0] PMP_MODE_NAPOT = 2'b11;
	localparam [1:0] PRIV_LVL_M = 2'b11;
	localparam [1:0] CSR_OP_CLEAR = 3;
	localparam [1:0] EXC_PC_DBG_EXC = 3;
	localparam [1:0] MD_OP_REM = 3;
	localparam [1:0] OP_A_IMM = 3;
	localparam [2:0] IMM_B_U = 3;
	localparam [2:0] PC_ERET = 3;
	localparam [4:0] ALU_OR = 3;
	localparam [2:0] DBG_CAUSE_NONE = 3'h0;
	localparam [2:0] DBG_CAUSE_EBREAK = 3'h1;
	localparam [2:0] DBG_CAUSE_TRIGGER = 3'h2;
	localparam [2:0] DBG_CAUSE_HALTREQ = 3'h3;
	localparam [2:0] DBG_CAUSE_STEP = 3'h4;
	localparam [2:0] IMM_B_J = 4;
	localparam [2:0] PC_DRET = 4;
	localparam [4:0] ALU_AND = 4;
	localparam [3:0] XDEBUGVER_NO = 4'd0;
	localparam [3:0] XDEBUGVER_NONSTD = 4'd15;
	localparam [3:0] XDEBUGVER_STD = 4'd4;
	localparam [2:0] IMM_B_INCR_PC = 5;
	localparam [4:0] ALU_SRA = 5;
	localparam [2:0] IMM_B_INCR_ADDR = 6;
	localparam [4:0] ALU_SRL = 6;
	localparam [4:0] ALU_SLL = 7;
	localparam [6:0] OPCODE_LOAD = 7'h03;
	localparam [6:0] OPCODE_MISC_MEM = 7'h0f;
	localparam [6:0] OPCODE_OP_IMM = 7'h13;
	localparam [6:0] OPCODE_AUIPC = 7'h17;
	localparam [6:0] OPCODE_STORE = 7'h23;
	localparam [6:0] OPCODE_OP = 7'h33;
	localparam [6:0] OPCODE_LUI = 7'h37;
	localparam [6:0] OPCODE_BRANCH = 7'h63;
	localparam [6:0] OPCODE_JALR = 7'h67;
	localparam [6:0] OPCODE_JAL = 7'h6f;
	localparam [6:0] OPCODE_SYSTEM = 7'h73;
	localparam [4:0] ALU_LT = 8;
	localparam [4:0] ALU_LTU = 9;
	localparam [5:0] EXC_CAUSE_INSN_ADDR_MISA = {1'b0, 5'd00};
	localparam [5:0] EXC_CAUSE_INSTR_ACCESS_FAULT = {1'b0, 5'd01};
	localparam [5:0] EXC_CAUSE_ILLEGAL_INSN = {1'b0, 5'd02};
	localparam [5:0] EXC_CAUSE_BREAKPOINT = {1'b0, 5'd03};
	localparam [5:0] EXC_CAUSE_LOAD_ACCESS_FAULT = {1'b0, 5'd05};
	localparam [5:0] EXC_CAUSE_STORE_ACCESS_FAULT = {1'b0, 5'd07};
	localparam [5:0] EXC_CAUSE_ECALL_UMODE = {1'b0, 5'd08};
	localparam [5:0] EXC_CAUSE_ECALL_MMODE = {1'b0, 5'd11};
	localparam [5:0] EXC_CAUSE_IRQ_SOFTWARE_M = {1'b1, 5'd03};
	localparam [5:0] EXC_CAUSE_IRQ_TIMER_M = {1'b1, 5'd07};
	localparam [5:0] EXC_CAUSE_IRQ_EXTERNAL_M = {1'b1, 5'd11};
	localparam [5:0] EXC_CAUSE_IRQ_NM = {1'b1, 5'd31};
	wire signed [34:0] mac_res_signed;
	wire [34:0] mac_res_ext;
	reg [33:0] accum;
	reg sign_a;
	reg sign_b;
	reg mult_valid;
	wire signed_mult;
	reg [33:0] mac_res_q;
	reg [33:0] mac_res_d;
	wire [33:0] mac_res;
	reg [33:0] op_remainder_d;
	wire div_sign_a;
	wire div_sign_b;
	reg is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	wire [31:0] one_shift;
	reg [31:0] op_denominator_q;
	reg [31:0] op_numerator_q;
	reg [31:0] op_quotient_q;
	reg [31:0] op_denominator_d;
	reg [31:0] op_numerator_d;
	reg [31:0] op_quotient_d;
	wire [31:0] next_remainder;
	wire [32:0] next_quotient;
	wire [32:0] res_adder_h;
	reg div_valid;
	reg [4:0] div_counter_q;
	reg [4:0] div_counter_d;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			mac_res_q <= 1'sb0;
			div_counter_q <= 1'sb0;
			md_state_q <= MD_IDLE;
			op_denominator_q <= 1'sb0;
			op_numerator_q <= 1'sb0;
			op_quotient_q <= 1'sb0;
		end
		else begin
			if (div_en_i) begin
				div_counter_q <= div_counter_d;
				op_denominator_q <= op_denominator_d;
				op_numerator_q <= op_numerator_d;
				op_quotient_q <= op_quotient_d;
				md_state_q <= md_state_d;
			end
			case (1'b1)
				mult_en_i: mac_res_q <= mac_res_d;
				div_en_i: mac_res_q <= op_remainder_d;
				default: mac_res_q <= mac_res_q;
			endcase
		end
	assign signed_mult = (signed_mode_i != 2'b00);
	assign multdiv_result_o = (div_en_i ? mac_res_q[31:0] : mac_res_d[31:0]);
	generate
		if (SingleCycleMultiply) begin : gen_multiv_single_cycle
			reg [0:0] mult_state_q;
			reg [0:0] mult_state_d;
			wire signed [33:0] mult1_res;
			wire signed [33:0] mult2_res;
			wire signed [33:0] mult3_res;
			wire [15:0] mult1_op_a;
			wire [15:0] mult1_op_b;
			wire [15:0] mult2_op_a;
			wire [15:0] mult2_op_b;
			reg [15:0] mult3_op_a;
			reg [15:0] mult3_op_b;
			wire mult1_sign_a;
			wire mult1_sign_b;
			wire mult2_sign_a;
			wire mult2_sign_b;
			reg mult3_sign_a;
			reg mult3_sign_b;
			reg [33:0] summand1;
			reg [33:0] summand2;
			reg [33:0] summand3;
			assign mult1_res = ($signed({mult1_sign_a, mult1_op_a}) * $signed({mult1_sign_b, mult1_op_b}));
			assign mult2_res = ($signed({mult2_sign_a, mult2_op_a}) * $signed({mult2_sign_b, mult2_op_b}));
			assign mult3_res = ($signed({mult3_sign_a, mult3_op_a}) * $signed({mult3_sign_b, mult3_op_b}));
			assign mac_res_signed = (($signed(summand1) + $signed(summand2)) + $signed(summand3));
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			always @(*) sign_a = (signed_mode_i[0] & op_a_i[31]);
			always @(*) sign_b = (signed_mode_i[1] & op_b_i[31]);
			assign mult1_sign_a = 1'b0;
			assign mult1_sign_b = 1'b0;
			assign mult1_op_a = op_a_i[15:0];
			assign mult1_op_b = op_b_i[15:0];
			assign mult2_sign_a = 1'b0;
			assign mult2_sign_b = sign_b;
			assign mult2_op_a = op_a_i[15:0];
			assign mult2_op_b = op_b_i[31:16];
			always @(*) accum[17:0] = mac_res_q[33:16];
			always @(*) accum[33:18] = {16 {(signed_mult & mac_res_q[33])}};
			always @(*) begin
				mult3_sign_a = sign_a;
				mult3_sign_b = 1'b0;
				mult3_op_a = op_a_i[31:16];
				mult3_op_b = op_b_i[15:0];
				summand1 = {18'h0, mult1_res[31:16]};
				summand2 = mult2_res;
				summand3 = mult3_res;
				mac_res_d = {2'b0, mac_res[15:0], mult1_res[15:0]};
				mult_valid = mult_en_i;
				mult_state_d = MULL;
				case (mult_state_q)
					MULL:
						if ((operator_i != MD_OP_MULL)) begin
							mac_res_d = mac_res;
							mult_valid = 1'b0;
							mult_state_d = MULH;
						end
					MULH: begin
						mult3_sign_a = sign_a;
						mult3_sign_b = sign_b;
						mult3_op_a = op_a_i[31:16];
						mult3_op_b = op_b_i[31:16];
						mac_res_d = mac_res;
						summand1 = 1'sb0;
						summand2 = accum;
						summand3 = mult3_res;
						mult_state_d = MULL;
						mult_valid = 1'b1;
					end
					default: mult_state_d = MULL;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= MULL;
				else if (mult_en_i)
					mult_state_q <= mult_state_d;
		end
		else begin : gen_multdiv_fast
			reg [15:0] mult_op_a;
			reg [15:0] mult_op_b;
			reg [0:0] mult_state_q;
			reg [0:0] mult_state_d;
			assign mac_res_signed = (($signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b})) + $signed(accum));
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			always @(*) begin
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[15:0];
				sign_a = 1'b0;
				sign_b = 1'b0;
				accum = mac_res_q;
				mac_res_d = mac_res;
				mult_state_d = mult_state_q;
				mult_valid = 1'b0;
				case (mult_state_q)
					ALBL: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[15:0];
						sign_a = 1'b0;
						sign_b = 1'b0;
						accum = 1'sb0;
						mac_res_d = mac_res;
						mult_state_d = ALBH;
					end
					ALBH: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[31:16];
						sign_a = 1'b0;
						sign_b = (signed_mode_i[1] & op_b_i[31]);
						accum = {18'b0, mac_res_q[31:16]};
						if ((operator_i == MD_OP_MULL))
							mac_res_d = {2'b0, mac_res[15:0], mac_res_q[15:0]};
						else
							mac_res_d = mac_res;
						mult_state_d = AHBL;
					end
					AHBL: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[15:0];
						sign_a = (signed_mode_i[0] & op_a_i[31]);
						sign_b = 1'b0;
						if ((operator_i == MD_OP_MULL)) begin
							accum = {18'b0, mac_res_q[31:16]};
							mac_res_d = {2'b0, mac_res[15:0], mac_res_q[15:0]};
							mult_valid = 1'b1;
							mult_state_d = ALBL;
						end
						else begin
							accum = mac_res_q;
							mac_res_d = mac_res;
							mult_state_d = AHBH;
						end
					end
					AHBH: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[31:16];
						sign_a = (signed_mode_i[0] & op_a_i[31]);
						sign_b = (signed_mode_i[1] & op_b_i[31]);
						accum[17:0] = mac_res_q[33:16];
						accum[33:18] = {16 {(signed_mult & mac_res_q[33])}};
						mac_res_d = mac_res;
						mult_state_d = ALBL;
						mult_valid = 1'b1;
					end
					default: mult_state_d = ALBL;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= ALBL;
				else if (mult_en_i)
					mult_state_q <= mult_state_d;
		end
	endgenerate
	assign res_adder_h = alu_adder_ext_i[33:1];
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : mac_res_q[31:0]);
	assign next_quotient = (is_greater_equal ? ({1'b0, op_quotient_q} | {1'b0, one_shift}) : {1'b0, op_quotient_q});
	assign one_shift = ({31'b0, 1'b1} << div_counter_q);
	always @(*)
		if (((mac_res_q[31] ^ op_denominator_q[31]) == 1'b0))
			is_greater_equal = (res_adder_h[31] == 1'b0);
		else
			is_greater_equal = mac_res_q[31];
	assign div_sign_a = (op_a_i[31] & signed_mode_i[0]);
	assign div_sign_b = (op_b_i[31] & signed_mode_i[1]);
	assign div_change_sign = (div_sign_a ^ div_sign_b);
	assign rem_change_sign = div_sign_a;
	always @(*) begin
		div_counter_d = (div_counter_q - 5'h1);
		op_remainder_d = mac_res_q;
		op_quotient_d = op_quotient_q;
		md_state_d = md_state_q;
		op_numerator_d = op_numerator_q;
		op_denominator_d = op_denominator_q;
		alu_operand_a_o = {32'h0, 1'b1};
		alu_operand_b_o = {~op_b_i, 1'b1};
		div_valid = 1'b0;
		case (md_state_q)
			MD_IDLE: begin
				if ((operator_i == MD_OP_DIV)) begin
					op_remainder_d = 1'sb1;
					md_state_d = (equal_to_zero ? MD_FINISH : MD_ABS_A);
				end
				else begin
					op_remainder_d = {2'b0, op_a_i};
					md_state_d = (equal_to_zero ? MD_FINISH : MD_ABS_A);
				end
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_b_i, 1'b1};
				div_counter_d = 5'd31;
			end
			MD_ABS_A: begin
				op_quotient_d = 1'sb0;
				op_numerator_d = (div_sign_a ? alu_adder_i : op_a_i);
				md_state_d = MD_ABS_B;
				div_counter_d = 5'd31;
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_a_i, 1'b1};
			end
			MD_ABS_B: begin
				op_remainder_d = {33'h0, op_numerator_q[31]};
				op_denominator_d = (div_sign_b ? alu_adder_i : op_b_i);
				md_state_d = MD_COMP;
				div_counter_d = 5'd31;
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~op_b_i, 1'b1};
			end
			MD_COMP: begin
				op_remainder_d = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_d]};
				op_quotient_d = next_quotient[31:0];
				md_state_d = ((div_counter_q == 5'd1) ? MD_LAST : MD_COMP);
				alu_operand_a_o = {mac_res_q[31:0], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
			end
			MD_LAST: begin
				if ((operator_i == MD_OP_DIV))
					op_remainder_d = {1'b0, next_quotient};
				else
					op_remainder_d = {2'b0, next_remainder[31:0]};
				alu_operand_a_o = {mac_res_q[31:0], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
				md_state_d = MD_CHANGE_SIGN;
			end
			MD_CHANGE_SIGN: begin
				md_state_d = MD_FINISH;
				if ((operator_i == MD_OP_DIV))
					op_remainder_d = (div_change_sign ? {2'h0, alu_adder_i} : mac_res_q);
				else
					op_remainder_d = (rem_change_sign ? {2'h0, alu_adder_i} : mac_res_q);
				alu_operand_a_o = {32'h0, 1'b1};
				alu_operand_b_o = {~mac_res_q[31:0], 1'b1};
			end
			MD_FINISH: begin
				md_state_d = MD_IDLE;
				div_valid = 1'b1;
			end
			default: md_state_d = MD_IDLE;
		endcase
	end
	assign valid_o = (mult_valid | div_valid);
endmodule
