`timescale 1ns/10ps
module fifo_controller_model(
	 Rst_n,
	 Push_Clk,
	 Pop_Clk,

	 Fifo_Push,
	 Fifo_Push_Flush,
	 Fifo_Full,
	 Fifo_Full_Usr,

	 Fifo_Pop,
	 Fifo_Pop_Flush,
	 Fifo_Empty,
	 Fifo_Empty_Usr,

	 Write_Addr,

	 Read_Addr,

	 Fifo_Ram_Mode,
	 Fifo_Sync_Mode,
	 Fifo_Push_Width,
	 Fifo_Pop_Width
	  );

    parameter MAX_PTR_WIDTH   = 12;

    parameter DEPTH1 = (1<<(MAX_PTR_WIDTH-3));
    parameter DEPTH2 = (1<<(MAX_PTR_WIDTH-2));
    parameter DEPTH3 = (1<<(MAX_PTR_WIDTH-1));

    parameter D1_QTR_A = MAX_PTR_WIDTH - 5;
    parameter D2_QTR_A = MAX_PTR_WIDTH - 4;
    parameter D3_QTR_A = MAX_PTR_WIDTH - 3;

	input	Rst_n;
	input	Push_Clk;
	input	Pop_Clk;

	input	Fifo_Push;
	input	Fifo_Push_Flush;
	output	Fifo_Full;
	output	[3:0]  Fifo_Full_Usr;

	input	Fifo_Pop;
	input	Fifo_Pop_Flush;
	output	Fifo_Empty;
	output	[3:0]  Fifo_Empty_Usr;

	output	[MAX_PTR_WIDTH-2:0]  Write_Addr;

	output	[MAX_PTR_WIDTH-2:0]  Read_Addr;

	input  Fifo_Ram_Mode;
	input  Fifo_Sync_Mode;
	input  [1:0] Fifo_Push_Width;
	input  [1:0] Fifo_Pop_Width;

	reg    flush_pop_clk_tf;
	reg    flush_pop2push_clk1;
	reg    flush_push_clk_tf;
	reg    flush_push2pop_clk1;
	reg    pop_local_flush_mask;
	reg    push_flush_tf_pop_clk;
	reg    pop2push_ack1;
	reg    pop2push_ack2;
	reg    push_local_flush_mask;
	reg    pop_flush_tf_push_clk;
	reg    push2pop_ack1;
	reg    push2pop_ack2;

	reg    fifo_full_flag_f;
	reg    [3:0]  Fifo_Full_Usr;

	reg    fifo_empty_flag_f;
	reg    [3:0]  Fifo_Empty_Usr;

	reg    [MAX_PTR_WIDTH-1:0]  push_ptr_push_clk;
	reg    [MAX_PTR_WIDTH-1:0]  pop_ptr_push_clk;
	reg    [MAX_PTR_WIDTH-1:0]  pop_ptr_async;
	reg    [MAX_PTR_WIDTH-1:0]  pop_ptr_pop_clk ;
	reg    [MAX_PTR_WIDTH-1:0]  push_ptr_pop_clk;
	reg    [MAX_PTR_WIDTH-1:0]  push_ptr_async;

	reg    [1:0]  push_ptr_push_clk_mask;
	reg    [1:0]  pop_ptr_pop_clk_mask;

	reg    [MAX_PTR_WIDTH-1:0]  pop_ptr_push_clk_mux;
	reg    [MAX_PTR_WIDTH-1:0]  push_ptr_pop_clk_mux;

	reg    match_room4none;
	reg    match_room4one;
	reg    match_room4half;
	reg    match_room4quart;

	reg    match_all_left;
	reg    match_half_left;
	reg    match_quart_left;

 	reg   [MAX_PTR_WIDTH-1:0]   depth1_reg;
 	reg   [MAX_PTR_WIDTH-1:0]   depth2_reg;
 	reg   [MAX_PTR_WIDTH-1:0]   depth3_reg;


	wire	push_clk_rst;
	wire	push_clk_rst_mux;
	wire	push_flush_done;
	wire	pop_clk_rst;
	wire	pop_clk_rst_mux;
	wire	pop_flush_done;

	wire	push_flush_gated;
	wire	pop_flush_gated;

	wire	[MAX_PTR_WIDTH-2:0] Write_Addr;
	wire	[MAX_PTR_WIDTH-2:0] Read_Addr;

	wire	[MAX_PTR_WIDTH-1:0] push_ptr_push_clk_plus1;
	wire	[MAX_PTR_WIDTH-1:0] next_push_ptr_push_clk;
	wire	[MAX_PTR_WIDTH-1:0] pop_ptr_pop_clk_plus1;
	wire	[MAX_PTR_WIDTH-1:0] next_pop_ptr_pop_clk;
	wire	[MAX_PTR_WIDTH-1:0] next_push_ptr_push_clk_mask;
	wire	[MAX_PTR_WIDTH-1:0] next_pop_ptr_pop_clk_mask;

	wire	[MAX_PTR_WIDTH-1:0] pop_ptr_push_clk_l_shift1;
	wire	[MAX_PTR_WIDTH-1:0] pop_ptr_push_clk_l_shift2;
	wire	[MAX_PTR_WIDTH-1:0] pop_ptr_push_clk_r_shift1;
	wire	[MAX_PTR_WIDTH-1:0] pop_ptr_push_clk_r_shift2;

	wire	[MAX_PTR_WIDTH-1:0] push_ptr_pop_clk_l_shift1;
	wire	[MAX_PTR_WIDTH-1:0] push_ptr_pop_clk_l_shift2;
	wire	[MAX_PTR_WIDTH-1:0] push_ptr_pop_clk_r_shift1;
	wire	[MAX_PTR_WIDTH-1:0] push_ptr_pop_clk_r_shift2;

	wire	[MAX_PTR_WIDTH-1:0] push_diff;
	wire	[MAX_PTR_WIDTH-1:0] push_diff_plus_1;
	wire	[MAX_PTR_WIDTH-1:0] pop_diff;

	wire	match_room4all;
	wire	match_room4eight;

	wire	match_one_left;
	wire	match_one2eight_left;

	integer	depth_sel_push;
	integer depth_sel_pop;

    initial
    begin
        depth1_reg = DEPTH1;
        depth2_reg = DEPTH2;
        depth3_reg = DEPTH3;
    end

	initial
	begin
		flush_pop_clk_tf		<= 1'b0;
		push2pop_ack1			<= 1'b0;
		push2pop_ack2			<= 1'b0;
		pop_local_flush_mask	<= 1'b0;
		flush_push2pop_clk1		<= 1'b0;
		push_flush_tf_pop_clk	<= 1'b0;
		flush_push_clk_tf	    <= 1'b0;
		pop2push_ack1			<= 1'b0;
		pop2push_ack2			<= 1'b0;
		push_local_flush_mask	<= 1'b0;
		flush_pop2push_clk1		<= 1'b0;
		pop_flush_tf_push_clk	<= 1'b0;
		push_ptr_push_clk	    <= 0;
		pop_ptr_push_clk		<= 0;
		pop_ptr_async			<= 0;
		fifo_full_flag_f		<= 0;
		pop_ptr_pop_clk			<= 0;
		push_ptr_pop_clk		<= 0;
		push_ptr_async			<= 0;
		fifo_empty_flag_f		<= 1;
		Fifo_Full_Usr			<= 4'b0001;
		Fifo_Empty_Usr			<= 4'b0000;
	end

	assign	Fifo_Full	= fifo_full_flag_f;
	assign	Fifo_Empty	= fifo_empty_flag_f;

	assign	Write_Addr	= push_ptr_push_clk[MAX_PTR_WIDTH-2:0];
	assign	Read_Addr	= next_pop_ptr_pop_clk[MAX_PTR_WIDTH-2:0];

	assign	push_ptr_push_clk_plus1			= push_ptr_push_clk + 1;
	assign	next_push_ptr_push_clk			= ( Fifo_Push ) ? push_ptr_push_clk_plus1 : push_ptr_push_clk;
	assign	next_push_ptr_push_clk_mask	= { ( push_ptr_push_clk_mask & next_push_ptr_push_clk[MAX_PTR_WIDTH-1:MAX_PTR_WIDTH-2] ), next_push_ptr_push_clk[MAX_PTR_WIDTH-3:0] };

	assign	pop_ptr_pop_clk_plus1				= pop_ptr_pop_clk + 1;
	assign	next_pop_ptr_pop_clk				= ( Fifo_Pop ) ? pop_ptr_pop_clk_plus1 : pop_ptr_pop_clk;
	assign	next_pop_ptr_pop_clk_mask		= { ( pop_ptr_pop_clk_mask & next_pop_ptr_pop_clk[MAX_PTR_WIDTH-1:MAX_PTR_WIDTH-2] ), next_pop_ptr_pop_clk[MAX_PTR_WIDTH-3:0] };

	assign	pop_ptr_push_clk_l_shift1	= { pop_ptr_push_clk[MAX_PTR_WIDTH-2:0], 1'b0 };
	assign	pop_ptr_push_clk_l_shift2	= { pop_ptr_push_clk[MAX_PTR_WIDTH-3:0], 2'b0 };
	assign	pop_ptr_push_clk_r_shift1	= { 1'b0, pop_ptr_push_clk[MAX_PTR_WIDTH-1:1] };
	assign	pop_ptr_push_clk_r_shift2	= { 2'b0, pop_ptr_push_clk[MAX_PTR_WIDTH-1:2] };

	assign	push_ptr_pop_clk_l_shift1	= { push_ptr_pop_clk[MAX_PTR_WIDTH-2:0], 1'b0 };
	assign	push_ptr_pop_clk_l_shift2	= { push_ptr_pop_clk[MAX_PTR_WIDTH-3:0], 2'b0 };
	assign	push_ptr_pop_clk_r_shift1	= { 1'b0, push_ptr_pop_clk[MAX_PTR_WIDTH-1:1] };
	assign	push_ptr_pop_clk_r_shift2	= { 2'b0, push_ptr_pop_clk[MAX_PTR_WIDTH-1:2] };

	assign	push_diff					= next_push_ptr_push_clk_mask - pop_ptr_push_clk_mux;
	assign	push_diff_plus_1	= push_diff + 1;
	assign	pop_diff					= push_ptr_pop_clk_mux - next_pop_ptr_pop_clk_mask;

	assign	match_room4all		= ~|push_diff;
	assign	match_room4eight	= ( depth_sel_push == 3 ) ? ( push_diff >= DEPTH3-8 ) : ( depth_sel_push == 2 ) ? ( push_diff >= DEPTH2-8 ) : ( push_diff >= DEPTH1-8 );

	assign	match_one_left				= ( pop_diff == 1 );
	assign	match_one2eight_left	= ( pop_diff < 8 );

	assign	push_flush_gated	= Fifo_Push_Flush & ~push_local_flush_mask;
	assign	pop_flush_gated		= Fifo_Pop_Flush & ~pop_local_flush_mask;

	assign	push_clk_rst	= flush_pop2push_clk1 ^ pop_flush_tf_push_clk;
	assign	pop_clk_rst		= flush_push2pop_clk1 ^ push_flush_tf_pop_clk;

	assign	pop_flush_done	= push2pop_ack1 ^ push2pop_ack2;
	assign	push_flush_done	= pop2push_ack1 ^ pop2push_ack2;

	assign	push_clk_rst_mux	= ( Fifo_Sync_Mode ) ? ( Fifo_Push_Flush | Fifo_Pop_Flush ) : ( push_flush_gated | push_clk_rst );
	assign	pop_clk_rst_mux		= ( Fifo_Sync_Mode ) ? ( Fifo_Push_Flush | Fifo_Pop_Flush ) : ( pop_flush_gated | ( pop_local_flush_mask & ~pop_flush_done ) | pop_clk_rst );

	reg match_room_at_most63, match_at_most63_left;

	always@( push_diff or push_diff_plus_1 or depth_sel_push or match_room4none or match_room4one )
	begin
		if( depth_sel_push == 1 )
		begin
			match_room4none		<= ( push_diff[D1_QTR_A+2:0] == depth1_reg[D1_QTR_A+2:0] );

			match_room4one		<= ( push_diff_plus_1[D1_QTR_A+2:0] == depth1_reg ) | match_room4none;

			match_room4half		<= ( push_diff[D1_QTR_A+1] == 1'b1 );
			match_room4quart	<= ( push_diff[D1_QTR_A] == 1'b1 );

			match_room_at_most63    <=  push_diff[6];
		end
		else if( depth_sel_push == 2 )
		begin
			match_room4none		<= ( push_diff[D2_QTR_A+2:0] == depth2_reg[D2_QTR_A+2:0] );

			match_room4one		<= ( push_diff_plus_1[D2_QTR_A+2:0] == depth2_reg ) | match_room4none;

			match_room4half		<= ( push_diff[D2_QTR_A+1] == 1'b1 );
			match_room4quart	<= ( push_diff[D2_QTR_A] == 1'b1 );

			match_room_at_most63    <=  &push_diff[7:6];
		end
		else
		begin
			match_room4none		<= ( push_diff == depth3_reg );
			match_room4one		<= ( push_diff_plus_1 == depth3_reg ) | match_room4none;

			match_room4half		<= ( push_diff[D3_QTR_A+1] == 1'b1 );
			match_room4quart	<= ( push_diff[D3_QTR_A] == 1'b1 );

			match_room_at_most63	<= &push_diff[8:6];
		end
	end

	assign room4_32s = ~push_diff[5];
	assign room4_16s = ~push_diff[4];
	assign room4_8s  = ~push_diff[3];
	assign room4_4s  = ~push_diff[2];
	assign room4_2s  = ~push_diff[1];
	assign room4_1s  = &push_diff[1:0];

	always@( depth_sel_pop or pop_diff )
	begin
		if( depth_sel_pop == 1 )
		begin
			match_all_left		<= ( pop_diff[D1_QTR_A+2:0] == depth1_reg[D1_QTR_A+2:0] );

			match_half_left		<= ( pop_diff[D1_QTR_A+1] == 1'b1 );
			match_quart_left	<= ( pop_diff[D1_QTR_A] == 1'b1 );

			match_at_most63_left	<= ~pop_diff[6];
		end
		else if( depth_sel_pop == 2 )
		begin
			match_all_left		<= ( pop_diff[D2_QTR_A+2:0] == depth2_reg[D2_QTR_A+2:0] );

			match_half_left		<= ( pop_diff[D2_QTR_A+1] == 1'b1 );
			match_quart_left	<= ( pop_diff[D2_QTR_A] == 1'b1 );

			match_at_most63_left	<= ~|pop_diff[7:6];
		end
		else
		begin
			match_all_left		<= ( pop_diff == depth3_reg );

			match_half_left		<= ( pop_diff[D3_QTR_A+1] == 1'b1 );
			match_quart_left	<= ( pop_diff[D3_QTR_A] == 1'b1 );

			match_at_most63_left	<= ~|pop_diff[8:6];
		end
	end

	assign at_least_32 = pop_diff[5];
	assign at_least_16 = pop_diff[4];
	assign at_least_8 = pop_diff[3];
	assign at_least_4 = pop_diff[2];
	assign at_least_2 = pop_diff[1];
	assign one_left = pop_diff[0];

	always@( posedge Pop_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
			push2pop_ack1 <= 1'b0;
			push2pop_ack2 <= 1'b0;
			flush_pop_clk_tf <= 1'b0;
			pop_local_flush_mask <= 1'b0;
			flush_push2pop_clk1 <= 1'b0;
			push_flush_tf_pop_clk <= 1'b0;
		end
		else
		begin
			push2pop_ack1 <= pop_flush_tf_push_clk;
			push2pop_ack2 <= push2pop_ack1;
			flush_push2pop_clk1 <= flush_push_clk_tf;
			if( pop_flush_gated )
			begin
				flush_pop_clk_tf	<= ~flush_pop_clk_tf;
			end

			if( pop_flush_gated & ~Fifo_Sync_Mode )
			begin
				pop_local_flush_mask	<= 1'b1;
			end
			else if( pop_flush_done )
			begin
				pop_local_flush_mask	<= 1'b0;
			end

			if( pop_clk_rst )
			begin
				push_flush_tf_pop_clk	<= ~push_flush_tf_pop_clk;
			end
		end
	end

	always@( posedge Push_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
			pop2push_ack1 <= 1'b0;
			pop2push_ack2 <= 1'b0;
			flush_push_clk_tf <= 1'b0;
			push_local_flush_mask <= 1'b0;
			flush_pop2push_clk1 <= 1'b0;
			pop_flush_tf_push_clk <= 1'b0;
		end
		else
		begin
			pop2push_ack1				<= push_flush_tf_pop_clk;
			pop2push_ack2				<= pop2push_ack1;
			flush_pop2push_clk1	<= flush_pop_clk_tf;
			if( push_flush_gated )
			begin
				flush_push_clk_tf	<= ~flush_push_clk_tf;
			end

			if( push_flush_gated & ~Fifo_Sync_Mode )
			begin
				push_local_flush_mask	<= 1'b1;
			end
			else if( push_flush_done )
			begin
				push_local_flush_mask	<= 1'b0;
			end

			if( push_clk_rst )
			begin
				pop_flush_tf_push_clk	<= ~pop_flush_tf_push_clk;
			end
		end
	end

	always@( Fifo_Push_Width or Fifo_Pop_Width or pop_ptr_push_clk_l_shift1 or pop_ptr_push_clk_l_shift2 or pop_ptr_push_clk_r_shift1 or
						pop_ptr_push_clk_r_shift2 or push_ptr_pop_clk_l_shift1 or push_ptr_pop_clk_l_shift2 or push_ptr_pop_clk_r_shift1 or push_ptr_pop_clk_r_shift2 or
						pop_ptr_push_clk or push_ptr_pop_clk )
	begin
		case( { Fifo_Push_Width, Fifo_Pop_Width } )
			4'b0001:
      begin
      	push_ptr_push_clk_mask	<= 2'b11;
				pop_ptr_pop_clk_mask		<= 2'b01;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_l_shift1;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_r_shift1;
			end
			4'b0010:
      begin
      	push_ptr_push_clk_mask	<= 2'b11;
				pop_ptr_pop_clk_mask		<= 2'b00;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_l_shift2;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_r_shift2;
			end
			4'b0100:
      begin
      	push_ptr_push_clk_mask	<= 2'b01;
				pop_ptr_pop_clk_mask		<= 2'b11;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_r_shift1;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_l_shift1;
			end
      4'b0110:
      begin
      	push_ptr_push_clk_mask	<= 2'b11;
				pop_ptr_pop_clk_mask		<= 2'b01;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_l_shift1;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_r_shift1;
			end
			4'b1000:
      begin
      	push_ptr_push_clk_mask	<= 2'b00;
				pop_ptr_pop_clk_mask		<= 2'b11;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_r_shift2;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_l_shift2;
			end
			4'b1001:
      begin
      	push_ptr_push_clk_mask	<= 2'b01;
				pop_ptr_pop_clk_mask		<= 2'b11;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk_r_shift1;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk_l_shift1;
			end
      default:
      begin
      	push_ptr_push_clk_mask	<= 2'b11;
				pop_ptr_pop_clk_mask		<= 2'b11;
				pop_ptr_push_clk_mux		<= pop_ptr_push_clk;
				push_ptr_pop_clk_mux		<= push_ptr_pop_clk;
			end
  	endcase
	end

	always@( Fifo_Ram_Mode or Fifo_Push_Width )
	begin
		if( Fifo_Ram_Mode == Fifo_Push_Width[0] )
		begin
			depth_sel_push	<= 2;
		end
		else if( Fifo_Ram_Mode == Fifo_Push_Width[1] )
		begin
			depth_sel_push	<= 1;
		end
		else
		begin
			depth_sel_push	<= 3;
		end
	end

	always@( Fifo_Ram_Mode or Fifo_Pop_Width )
	begin
		if( Fifo_Ram_Mode == Fifo_Pop_Width[0] )
		begin
			depth_sel_pop	<= 2;
		end
		else if( Fifo_Ram_Mode == Fifo_Pop_Width[1] )
		begin
			depth_sel_pop	<= 1;
		end
		else
		begin
			depth_sel_pop	<= 3;
		end
	end

	always@( posedge Push_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
			push_ptr_push_clk	<= 0;
			pop_ptr_push_clk	<= 0;
			pop_ptr_async			<= 0;
			fifo_full_flag_f	<= 0;
		end
		else
		begin
			if( push_clk_rst_mux )
			begin
				push_ptr_push_clk	<= 0;
				pop_ptr_push_clk	<= 0;
				pop_ptr_async			<= 0;
				fifo_full_flag_f	<= 0;
			end
			else
			begin
				push_ptr_push_clk	<= next_push_ptr_push_clk;
				pop_ptr_push_clk	<= ( Fifo_Sync_Mode ) ? next_pop_ptr_pop_clk : pop_ptr_async;
				pop_ptr_async			<= pop_ptr_pop_clk;
				fifo_full_flag_f	<= match_room4one | match_room4none;
			end
		end
	end

	always@( posedge Pop_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
			pop_ptr_pop_clk		<= 0;
			push_ptr_pop_clk	<= 0;
			push_ptr_async		<= 0;
			fifo_empty_flag_f	<= 1;
		end
		else
		begin
			if( pop_clk_rst_mux )
			begin
				pop_ptr_pop_clk		<= 0;
				push_ptr_pop_clk	<= 0;
				push_ptr_async		<= 0;
				fifo_empty_flag_f	<= 1;
			end
			else
			begin
				pop_ptr_pop_clk		<= next_pop_ptr_pop_clk;
				push_ptr_pop_clk	<= ( Fifo_Sync_Mode ) ? next_push_ptr_push_clk : push_ptr_async;
				push_ptr_async		<= push_ptr_push_clk;
				fifo_empty_flag_f	<= ( pop_diff == 1 ) | ( pop_diff == 0 );
			end
		end
	end

	always@( posedge Push_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
 		    Fifo_Full_Usr	<= 4'b0001;
		end
		else
		begin
			if( match_room4none )
			begin
				Fifo_Full_Usr	<= 4'b0000;
			end
			else if( match_room4all )
			begin
				Fifo_Full_Usr	<= 4'b0001;
			end
			else if( ~match_room4half )
			begin
				Fifo_Full_Usr	<= 4'b0010;
			end
			else if( ~match_room4quart )
			begin
				Fifo_Full_Usr	<= 4'b0011;
			end
			else
				begin
				if (match_room_at_most63)
					begin
					if (room4_32s)
						Fifo_Full_Usr <= 4'b1010;
					else if (room4_16s)
						Fifo_Full_Usr <= 4'b1011;
					else if (room4_8s)
						Fifo_Full_Usr <= 4'b1100;
					else if (room4_4s)
						Fifo_Full_Usr <= 4'b1101;
					else if (room4_2s)
						Fifo_Full_Usr <= 4'b1110;
					else if (room4_1s)
						Fifo_Full_Usr <= 4'b1111;
					else
						Fifo_Full_Usr <= 4'b1110;
					end
				else
					Fifo_Full_Usr <= 4'b0100;
				end
		end
	end

	always@( posedge Pop_Clk or negedge Rst_n )
	begin
		if( ~Rst_n )
		begin
			Fifo_Empty_Usr	<= 4'b0000;
		end
		else
		begin
			if( Fifo_Pop_Flush | ( pop_local_flush_mask & ~pop_flush_done ) | pop_clk_rst )
			begin
				Fifo_Empty_Usr	<= 4'b0000;
			end
			else
			if( match_all_left )
			begin
				Fifo_Empty_Usr	<= 4'b1111;
			end
			else if( match_half_left )
			begin
				Fifo_Empty_Usr	<= 4'b1110;
			end
			else if( match_quart_left )
			begin
				Fifo_Empty_Usr	<= 4'b1101;
			end
			else
				begin
				if (match_at_most63_left)
					begin
					if (at_least_32)
						Fifo_Empty_Usr	<= 4'b0110;
					else if	(at_least_16)
						Fifo_Empty_Usr	<= 4'b0101;
					else if	(at_least_8)
						Fifo_Empty_Usr	<= 4'b0100;
					else if	(at_least_4)
						Fifo_Empty_Usr	<= 4'b0011;
					else if	(at_least_2)
						Fifo_Empty_Usr	<= 4'b0010;
					else if	(one_left)
						Fifo_Empty_Usr	<= 4'b0001;
					else Fifo_Empty_Usr	<= 4'b0000;
					end
				else
					Fifo_Empty_Usr	<= 4'b1000;
				end
		end
	end
endmodule
