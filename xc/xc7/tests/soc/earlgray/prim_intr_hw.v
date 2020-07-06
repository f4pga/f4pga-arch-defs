module prim_intr_hw (
	event_intr_i,
	reg2hw_intr_enable_q_i,
	reg2hw_intr_test_q_i,
	reg2hw_intr_test_qe_i,
	reg2hw_intr_state_q_i,
	hw2reg_intr_state_de_o,
	hw2reg_intr_state_d_o,
	intr_o
);
	parameter [31:0] Width = 1;
	input [Width - 1:0] event_intr_i;
	input [Width - 1:0] reg2hw_intr_enable_q_i;
	input [Width - 1:0] reg2hw_intr_test_q_i;
	input reg2hw_intr_test_qe_i;
	input [Width - 1:0] reg2hw_intr_state_q_i;
	output hw2reg_intr_state_de_o;
	output [Width - 1:0] hw2reg_intr_state_d_o;
	output [Width - 1:0] intr_o;
	wire [Width - 1:0] new_event;
	assign new_event = ({Width {reg2hw_intr_test_qe_i}} & reg2hw_intr_test_q_i) | event_intr_i;
	assign hw2reg_intr_state_de_o = |new_event;
	assign hw2reg_intr_state_d_o = new_event | reg2hw_intr_state_q_i;
	assign intr_o = reg2hw_intr_state_q_i & reg2hw_intr_enable_q_i;
endmodule
