// -----------------------------------------------------------------------------
// title          : AL4S3B Fabric Intel VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : Serializer_Deserializer.v
// author         : Rakesh Moolacheri
// company        : QuickLogic Corp
// created        : 2019/03/07	
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: 
// -----------------------------------------------------------------------------
// copyright (c) 2018
// -----------------------------------------------------------------------------
// revisions  :
// date            version     author               description
// 2019/03/07      1.0        Rakesh Moolacheri    Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

module Serializer_Deserializer ( 

			clk_i,          
			rst_i,   

			//sensor_wr_dat_i,  
			spi_start_i, 
			spi_rden_i,
			spi_tfer_done_o,  
			
			spi_ss_o,        
			spi_sck_o,        
			spi_mosi_o,       
			spi_miso_i,  

			spi_clk_o,
			
			spi_fsm_st_o,
			
			rx_fifo_full_i,   
			Sensor_RD_Data_o, 
			Sensor_RD_Push_o      

			);
			
			
input			clk_i;
input			rst_i;

//input	[7:0]	sensor_wr_dat_i;
input			spi_start_i; 
input			spi_rden_i;
output			spi_tfer_done_o;

output			spi_ss_o;
output			spi_sck_o;
output			spi_mosi_o;
input	    	spi_miso_i;

input			rx_fifo_full_i;
output	[31:0]	Sensor_RD_Data_o;
output			Sensor_RD_Push_o;

output 			spi_clk_o;

output    [1:0]	spi_fsm_st_o;

wire			clk_i;
wire			rst_i;

//wire	[7:0]	sensor_wr_dat_i;
wire			spi_start_i;
wire			spi_rden_i;
wire			spi_tfer_done_o;

wire			spi_ss_o;
wire			spi_sck_o;
wire			spi_mosi_o;
wire	    	spi_miso_i;

wire			rx_fifo_full_i;
wire	[31:0]	Sensor_RD_Data_o;
wire			Sensor_RD_Push_o; 

reg	    [3:0]	bit_count; 

//reg	    [15:0]	Shift_Reg; 
//wire    [15:0]	SPIDR;

reg	    [15:0]	read_fifo_receive_data;
reg	    [15:0]	read_fifo_receive_data_l;

reg 			SS_bar; 
reg 			toggle_r;

wire 			Baud_Rate; 

wire 			spi_clk_o; 
wire 			spi_done;

//reg 			Sensor_RD_Push_r;
//wire			Sensor_RD_Push;

wire    [1:0]	spi_fsm_st_o;


reg [1:0] FSM_spi_state;
parameter IDLE_ST = 0;
parameter Transmit_ST = 1; 
parameter Done_ST = 2;

//gclkbuff u_gclkbuff_spi_clk ( .A(Baud_Rate_r ) , .Z(Baud_Rate) );
assign Baud_Rate = clk_i;

assign spi_fsm_st_o = FSM_spi_state;

assign spi_clk_o = Baud_Rate;
//assign spi_mosi_o = Shift_Reg[15]; 
assign spi_mosi_o = 1'b0;
assign spi_ss_o = SS_bar;
//assign spi_sck_o = (Baud_Rate & (~SS_bar));
assign spi_sck_o = (Baud_Rate | SS_bar);

//assign spi_tfer_done_o = (FSM_spi_state == Done_ST)? 1'b1: 1'b0;
assign spi_tfer_done_o = (FSM_spi_state == Transmit_ST) && (bit_count == 4'hF);

assign Sensor_RD_Data_o = {read_fifo_receive_data, read_fifo_receive_data_l};
//assign Sensor_RD_Push_o   = (toggle_r & spi_done);
assign Sensor_RD_Push_o   = spi_done;

/*
assign Sensor_RD_Push_o = (Sensor_RD_Push & ~Sensor_RD_Push_r);

always @( posedge clk_i or posedge rst_i ) 
begin
    if (rst_i)
    begin
	    Sensor_RD_Push_r   <= 1'b0;
	end
	else
	begin
		Sensor_RD_Push_r   <= Sensor_RD_Push;
	end
end	
*/

always @ (posedge Baud_Rate or posedge rst_i)
begin
	if(rst_i)
		bit_count <= 4'h0;
	else
        if(FSM_spi_state== Transmit_ST)
			bit_count <= bit_count + 1;	
		else 
			bit_count <= 4'h0; 
end


// SPI state machine	
always @ (posedge Baud_Rate or posedge rst_i)
begin
	if(rst_i) begin
				FSM_spi_state <= IDLE_ST;
				SS_bar		  <= 1'b1;
	          end
	else begin
		case (FSM_spi_state)
		IDLE_ST :     begin  
						if(spi_start_i) 
						begin
							FSM_spi_state <= Transmit_ST; 
							SS_bar		  <= 1'b0;
						end
						else
						begin
							FSM_spi_state <= IDLE_ST;
							SS_bar		  <= 1'b1;
						end
					  end
					
		Transmit_ST : begin
						if(bit_count == 4'hF) 
						begin
							FSM_spi_state <= Done_ST;
							SS_bar		  <= 1'b1;
						end
						else 
						begin
							FSM_spi_state <= Transmit_ST;
							SS_bar		  <= 1'b0;
						end
					  end
					
		Done_ST : 	  begin
							FSM_spi_state <= IDLE_ST;
							SS_bar		  <= 1'b1;
					  end
					
					default:FSM_spi_state <= IDLE_ST;
					
		endcase
	end
end

always @ ( negedge Baud_Rate or posedge rst_i)    
begin	
	if(rst_i)
		read_fifo_receive_data <= 16'h0;
	else 
	   if (SS_bar == 1'b0)
			read_fifo_receive_data <= {read_fifo_receive_data[14:0], spi_miso_i}; 
	   else
			read_fifo_receive_data <= read_fifo_receive_data; 
end

/*
assign SPIDR = {sensor_wr_dat_i, 8'h0};
always @ (negedge Baud_Rate or posedge rst_i)
begin
	if(rst_i)
		Shift_Reg <= 16'h0;
	else 
	  if (spi_start_i)
	     Shift_Reg <= SPIDR;
	  else if (FSM_spi_state == Transmit_ST)
		Shift_Reg <= {Shift_Reg[14:0], Shift_Reg[15]};
	  else
	    Shift_Reg <=  Shift_Reg;
end	
*/	

assign spi_done = (FSM_spi_state == Done_ST)? 1'b1: 1'b0;

always @( posedge Baud_Rate or posedge rst_i ) 
begin
    if (rst_i)
	    toggle_r   <= 1'b0;
	else
	    if (spi_rden_i == 1'b0)
		    toggle_r   <= 1'b0;
		else if (spi_done == 1'b1)
			toggle_r   <= ~toggle_r;
		else
			toggle_r   <= toggle_r;
end	

always @( posedge Baud_Rate or posedge rst_i ) 
begin
    if (rst_i)
	    read_fifo_receive_data_l  <= 16'h0;
	else
	    if (~toggle_r & spi_done)
		    read_fifo_receive_data_l  <= read_fifo_receive_data;
		else
			read_fifo_receive_data_l  <= read_fifo_receive_data_l;
end	

endmodule