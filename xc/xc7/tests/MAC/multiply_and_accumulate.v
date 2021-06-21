// This test is to use the MAC operation inside the dsp.

module mac(
    input clk,
    input signed  [10:0] sw,
    output signed [11:0] led;
);

//input output declartion			
wire [3:0] 	 in_a, in_b;
wire 	     in_valid_a, in_valid_b;
wire	     reset;
reg  [10:0]  mac_out;
reg          out_valid;

// Assignment
assign reset = sw[10]; // Declaration of synchronous reset
assign in_valid_a = sw[9]; // Declaration of which input is valid, here it is a
assign in_valid_b = sw[8]; // Declaration of which input is valid, here it is b
assign mac_out = led[10:0]; // Declaration of output
assign out_valid = led[11]; // Declaration if the output is valid
//////////////////////////////////////////////////////////////////////////
parameter  IDLE  = 2'b000 ;
parameter WAIT_A = 2'b001 ;
parameter WAIT_B = 2'b010 ;
parameter  MAC   = 2'b011 ;

reg out_sig ;
reg [3:0] counter ;
reg [1:0] state_Next , state ;
reg signed [3:0] reg_a , reg_b ;
reg signed [10:0] reg_c , temp_out;

always@(negedge clk)
begin
	if(reset)
		counter <= 4'd0 ;
	else if(counter==4'd8)
		if(in_valid_a&in_valid_b)
		counter <= 4'd1 ;
		else
		counter <= 4'd0 ;
	else if(state==MAC)
		counter <= counter + 4'd1 ;
end

always@(posedge clk )
begin
	if(reset)
		state <= IDLE ;
	else
		state <= state_Next ;
end

always@(*)
begin
	case(state)
		IDLE : if(in_valid_a&in_valid_b) 
				 state_Next = MAC   ;
			   else if(in_valid_a) 
				state_Next = WAIT_B ; 
			   else if(in_valid_b) 
			    state_Next = WAIT_A ; 
			   else	        state_Next = IDLE   ;
		
		WAIT_A : if(in_valid_a) 
				  state_Next = MAC ; 
				 else state_Next = WAIT_A ;
				 
		WAIT_B : if(in_valid_b) 
		          state_Next = MAC ; 
				 else state_Next = WAIT_B ;
		
		MAC    : if(in_valid_a&in_valid_b) 
				 state_Next = MAC ; 
				 else if(in_valid_a)
					state_Next = WAIT_B ;
				 else if(in_valid_b)
					state_Next = WAIT_A ;
				 else state_Next = IDLE ;
		default : state_Next = IDLE ;
	endcase
end

always@(posedge clk)
begin
	if(in_valid_a)
		reg_a <= in_a ;
end

always@(posedge clk)
begin
	if(in_valid_b)
		reg_b <= in_b ;
end

always@(negedge clk)
begin
	if(reset)
		reg_c <= 11'd0 ;
	else if(counter==4'd8)
		if(in_valid_a&in_valid_b)
		reg_c <= reg_a*reg_b ;
		else
		reg_c <= 11'd0 ;
	else if(state==MAC)
		reg_c <= reg_c + (reg_a*reg_b) ;
	
end

always@(posedge clk)
begin
	if(counter>=4'd1&&counter<=4'd8)
		temp_out <= reg_c ;
end

always@(posedge clk)
begin
	if(counter==4'd8)
		out_sig <= 1 ;
	else
		out_sig <= 0 ;
end

always@(posedge clk)
begin
	if(out_sig)
		out_valid <= 1 ;
	else
		out_valid <= 0 ;
end

always@(posedge clk)
begin
	if(out_sig)
		mac_out <= temp_out ;
	
end

endmodule