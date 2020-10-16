// -----------------------------------------------------------------------------
// title          : AL4S3B Fabric Intel VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : Fsm_Top.v
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

module Fsm_Top ( 

			clk_i,          
			rst_i,   
			
			sensor_enable_i,   		

			fsm_top_st_o,
    
            spi_start_o,    
			spi_rden_o,
            spi_tfer_done_i      
			);
			
			
input			clk_i;
input			rst_i;

input	    	sensor_enable_i;

output			spi_start_o;
output			spi_rden_o;
input			spi_tfer_done_i;

output 	[1:0]	fsm_top_st_o;


wire			clk_i;
wire			rst_i;

wire	    	sensor_enable_i;

reg 			spi_start_o;
reg 			spi_rden_o;
wire			spi_tfer_done_i;

reg				sensor_enable_r;
reg				sensor_enable_r1;

wire 	[1:0]	fsm_top_st_o;
 
reg  FSM_Top_state;
parameter IDLE_ST = 0;
parameter Transmit_ST = 1;


assign fsm_top_st_o = FSM_Top_state;

always @( posedge clk_i or posedge rst_i ) 
begin
    if (rst_i)
    begin
	    sensor_enable_r   <= 1'b0;
		sensor_enable_r1  <= 1'b0;
	end
	else
	begin
		sensor_enable_r   <= sensor_enable_i;
		sensor_enable_r1  <= sensor_enable_r;
	end
end

always @ (posedge clk_i or posedge rst_i)
begin
	if(rst_i)
	 begin
		FSM_Top_state 	<= IDLE_ST;
		spi_start_o   	<= 1'b0; 
		spi_rden_o   	<= 1'b0;
	 end
	else begin
		case (FSM_Top_state)
		IDLE_ST :     begin  
						if(sensor_enable_r1)
						  begin
							FSM_Top_state 	<= Transmit_ST;  
							spi_start_o   	<= 1'b1;
							spi_rden_o   	<= 1'b1;
						  end
						else
						  begin
							FSM_Top_state 	<= IDLE_ST;
							spi_start_o   	<= 1'b0;
							spi_rden_o   	<= 1'b0;
						  end
					  end
					
		Transmit_ST: begin
							spi_start_o   	<= 1'b0;
							spi_rden_o   	<= 1'b1;
							if (spi_tfer_done_i)
							begin
								FSM_Top_state <= IDLE_ST; 
							end
							else
							begin
								FSM_Top_state <= Transmit_ST;
							end
					  end
	
				default:FSM_Top_state <= IDLE_ST;
			
		endcase
	end
end	

endmodule