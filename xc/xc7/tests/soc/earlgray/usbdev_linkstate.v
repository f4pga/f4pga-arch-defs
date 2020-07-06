module usbdev_linkstate (
	clk_48mhz_i,
	rst_ni,
	us_tick_i,
	usb_sense_i,
	usb_rx_d_i,
	usb_rx_se0_i,
	sof_valid_i,
	link_disconnect_o,
	link_connect_o,
	link_reset_o,
	link_suspend_o,
	link_resume_o,
	host_lost_o,
	link_state_o
);
	localparam [1:0] Active = 0;
	localparam [1:0] NoRst = 0;
	localparam [2:0] LinkDisconnect = 0;
	localparam [1:0] InactCnt = 1;
	localparam [1:0] RstCnt = 1;
	localparam [2:0] LinkPowered = 1;
	localparam [1:0] InactPend = 2;
	localparam [1:0] RstPend = 2;
	localparam [2:0] LinkPoweredSuspend = 2;
	localparam [2:0] LinkActive = 3;
	localparam [2:0] LinkSuspend = 4;
	input wire clk_48mhz_i;
	input wire rst_ni;
	input wire us_tick_i;
	input wire usb_sense_i;
	input wire usb_rx_d_i;
	input wire usb_rx_se0_i;
	input wire sof_valid_i;
	output wire link_disconnect_o;
	output wire link_connect_o;
	output wire link_reset_o;
	output wire link_suspend_o;
	output reg link_resume_o;
	output wire host_lost_o;
	output wire [2:0] link_state_o;
	localparam [11:0] SUSPEND_TIMEOUT = 12'd3000;
	localparam [2:0] RESET_TIMEOUT = 3'd3;
	reg [2:0] link_state_d;
	reg [2:0] link_state_q;
	wire link_active;
	wire line_se0_raw;
	wire line_idle_raw;
	wire see_se0;
	wire see_idle;
	wire see_pwr_sense;
	reg [2:0] link_rst_timer_d;
	reg [2:0] link_rst_timer_q;
	reg [1:0] link_rst_state_d;
	reg [1:0] link_rst_state_q;
	reg link_reset;
	reg monitor_inac;
	reg [11:0] link_inac_timer_d;
	reg [11:0] link_inac_timer_q;
	reg [1:0] link_inac_state_d;
	reg [1:0] link_inac_state_q;
	wire ev_bus_active;
	reg ev_bus_inactive;
	reg ev_reset;
	assign link_disconnect_o = link_state_q == LinkDisconnect;
	assign link_connect_o = link_state_q != LinkDisconnect;
	assign link_suspend_o = (link_state_q == LinkSuspend) || (link_state_q == LinkPoweredSuspend);
	assign link_active = link_state_q == LinkActive;
	assign link_state_o = link_state_q;
	assign line_se0_raw = usb_rx_se0_i;
	assign line_idle_raw = usb_rx_d_i && !usb_rx_se0_i;
	prim_filter #(.Cycles(6)) filter_se0(
		.clk_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.enable_i(1'b1),
		.filter_i(line_se0_raw),
		.filter_o(see_se0)
	);
	prim_filter #(.Cycles(6)) filter_idle(
		.clk_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.enable_i(1'b1),
		.filter_i(line_idle_raw),
		.filter_o(see_idle)
	);
	prim_filter #(.Cycles(6)) filter_pwr_sense(
		.clk_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.enable_i(1'b1),
		.filter_i(usb_sense_i),
		.filter_o(see_pwr_sense)
	);
	assign ev_bus_active = !see_idle;
	always @(*) begin
		link_state_d = link_state_q;
		link_resume_o = 0;
		monitor_inac = (see_pwr_sense ? (link_state_q == LinkPowered) | (link_state_q == LinkActive) : 1'b0);
		if (!see_pwr_sense)
			link_state_d = LinkDisconnect;
		else
			case (link_state_q)
				LinkDisconnect:
					if (see_pwr_sense)
						link_state_d = LinkPowered;
				LinkPowered:
					if (ev_reset)
						link_state_d = LinkActive;
					else if (ev_bus_inactive)
						link_state_d = LinkPoweredSuspend;
				LinkPoweredSuspend:
					if (ev_reset)
						link_state_d = LinkActive;
					else if (ev_bus_active) begin
						link_resume_o = 1;
						link_state_d = LinkPowered;
					end
				LinkActive:
					if (ev_bus_inactive)
						link_state_d = LinkSuspend;
				LinkSuspend:
					if (ev_reset || ev_bus_active) begin
						link_resume_o = 1;
						link_state_d = LinkActive;
					end
				default: link_state_d = LinkDisconnect;
			endcase
	end
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			link_state_q <= LinkDisconnect;
		else
			link_state_q <= link_state_d;
	always @(*) begin : proc_rst_fsm
		link_rst_state_d = link_rst_state_q;
		link_rst_timer_d = link_rst_timer_q;
		ev_reset = 1'b0;
		link_reset = 1'b0;
		case (link_rst_state_q)
			NoRst:
				if (see_se0) begin
					link_rst_state_d = RstCnt;
					link_rst_timer_d = 0;
				end
			RstCnt:
				if (!see_se0)
					link_rst_state_d = NoRst;
				else if (us_tick_i)
					if (link_rst_timer_q == RESET_TIMEOUT)
						link_rst_state_d = RstPend;
					else
						link_rst_timer_d = link_rst_timer_q + 1;
			RstPend: begin
				if (!see_se0) begin
					link_rst_state_d = NoRst;
					ev_reset = 1'b1;
				end
				link_reset = 1'b1;
			end
			default: link_rst_state_d = NoRst;
		endcase
	end
	assign link_reset_o = link_reset;
	always @(posedge clk_48mhz_i or negedge rst_ni) begin : proc_reg_rst
		if (!rst_ni) begin
			link_rst_state_q <= NoRst;
			link_rst_timer_q <= 0;
		end
		else begin
			link_rst_state_q <= link_rst_state_d;
			link_rst_timer_q <= link_rst_timer_d;
		end
	end
	always @(*) begin : proc_idle_det
		link_inac_state_d = link_inac_state_q;
		link_inac_timer_d = link_inac_timer_q;
		ev_bus_inactive = 0;
		case (link_inac_state_q)
			Active: begin
				link_inac_timer_d = 0;
				if (see_idle && monitor_inac)
					link_inac_state_d = InactCnt;
			end
			InactCnt:
				if (!see_idle || !monitor_inac)
					link_inac_state_d = Active;
				else if (us_tick_i)
					if (link_inac_timer_q == SUSPEND_TIMEOUT) begin
						link_inac_state_d = InactPend;
						ev_bus_inactive = 1;
					end
					else
						link_inac_timer_d = link_inac_timer_q + 1;
			InactPend:
				if (!see_idle || !monitor_inac)
					link_inac_state_d = Active;
			default: link_inac_state_d = Active;
		endcase
	end
	always @(posedge clk_48mhz_i or negedge rst_ni) begin : proc_reg_idle_det
		if (!rst_ni) begin
			link_inac_state_q <= Active;
			link_inac_timer_q <= 0;
		end
		else begin
			link_inac_state_q <= link_inac_state_d;
			link_inac_timer_q <= link_inac_timer_d;
		end
	end
	reg [12:0] host_presence_timer;
	assign host_lost_o = host_presence_timer[12];
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			host_presence_timer <= 1'sb0;
		else if ((sof_valid_i || !link_active) || link_reset)
			host_presence_timer <= 1'sb0;
		else if (us_tick_i && !host_lost_o)
			host_presence_timer <= host_presence_timer + 1;
endmodule
