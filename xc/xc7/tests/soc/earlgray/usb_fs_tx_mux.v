module usb_fs_tx_mux (
	in_tx_pkt_start_i,
	in_tx_pid_i,
	out_tx_pkt_start_i,
	out_tx_pid_i,
	tx_pkt_start_o,
	tx_pid_o
);
	input wire in_tx_pkt_start_i;
	input wire [3:0] in_tx_pid_i;
	input wire out_tx_pkt_start_i;
	input wire [3:0] out_tx_pid_i;
	output wire tx_pkt_start_o;
	output wire [3:0] tx_pid_o;
	assign tx_pkt_start_o = in_tx_pkt_start_i | out_tx_pkt_start_i;
	assign tx_pid_o = (out_tx_pkt_start_i ? out_tx_pid_i : in_tx_pid_i);
endmodule
