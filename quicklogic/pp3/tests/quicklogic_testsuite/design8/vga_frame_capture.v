// -----------------------------------------------------------------------------
// title          : AL4S3B Fabric In VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : vga_frame_capture.v
// author         : Anand Wadke
// company        : QuickLogic Corp
// created        : 2017/11/9	
// last update    : 2017/11/9
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/11/09      1.0        Anand Wadke    Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

//`define SIM
module vga_frame_capture ( 
            input  			wb_clk_i	,
            input  			rst_i	,
			
			input 			PCLK_i,
			input 			VSYNC_i,
			input 			HREF_HSYNC_i,
			input 	[7:0]	RGB_DAT_i,				
			
			input  [15:0]   vga_ctrl_reg_i,
			output [7:0]    vga_fsm_sts_o,
			output          clear_ena_frame_samp_o,
            input  			rx_fifo_overflow_detected_i	,
			
			output [9:0]    rcvd_line_cnt_o,

			output [31:0] 	RGB_data_32_o,
            output 			RGB_Rx_Push_o
			
						
			);
parameter ST_IDLE            = 3'b000;
parameter ST_WAIT_FOR_HREF_1 = 3'b001;
parameter ST_WAIT_FOR_HSYNC  = 3'b010;
parameter ST_SAMPLE_LINE_DAT = 3'b011;
parameter ST_WAIT_FOR_HREF_0 = 3'b100;

reg   [2:0]  st_frame_trns;

reg   [10:0] horizontal_cnt ;
reg   [9:0] line_cnt ;		 

wire	fsm_rst_sig;
wire    ena_frame_samp;
wire    sample_all_byte;
wire    even_byte_sel;
wire    odd_byte_sel;

reg [7:0]   RGB_byte0, RGB_byte1,RGB_byte2, RGB_byte3; 
reg [31:0]  RGB_data_32;
reg 		RGB_Rx_Push;
reg 		RGB_Rx_Push1;
reg [2:0]   word_index_sample_cnt;
reg 		frame_receive_done;

reg    ena_frame_samp_sync_p1;
reg    ena_frame_samp_sync_p2;

wire 		vsync_edge_detect;
reg 		vsync_reg1,vsync_reg2;
reg 		clear_ena_frame_samp;

wire        frame_type_320;
wire        frame_type_640;

wire        HREF_HSYN_n;


assign      clear_ena_frame_samp_o = clear_ena_frame_samp; 

assign vsync_edge_detect = vsync_reg1 ^ vsync_reg2;

assign rcvd_line_cnt_o = line_cnt;

assign ena_frame_samp  =  vga_ctrl_reg_i[0]; 
assign sample_all_byte = ~vga_ctrl_reg_i[11]; 
assign even_byte_sel   = ~vga_ctrl_reg_i[12]; 
assign odd_byte_sel    =  vga_ctrl_reg_i[12]; 
assign frame_type_320  =  ~vga_ctrl_reg_i[9]; 
assign frame_type_640  =   vga_ctrl_reg_i[9]; 
assign HREF_HSYN_n     =   ~vga_ctrl_reg_i[15]; 

assign vga_fsm_sts_o = {st_frame_trns,frame_receive_done};
//assign fsm_rst_sig   = rst_i | rx_fifo_overflow_detected_i;//Commented for testing-Dec7
assign fsm_rst_sig   = rst_i;

always @(posedge PCLK_i or posedge fsm_rst_sig) //clk_i = 10 Mhz
begin
     if (fsm_rst_sig==1'b1)
	 begin
		ena_frame_samp_sync_p1	<= 1'b0;
	    ena_frame_samp_sync_p2	<= 1'b0;
	 end
	 else
	 begin
		ena_frame_samp_sync_p1	<= ena_frame_samp;
	    ena_frame_samp_sync_p2	<= ena_frame_samp_sync_p1;	 
	 
	 end
end	


always @(posedge PCLK_i or posedge fsm_rst_sig) //clk_i = 10 Mhz
begin
     if (fsm_rst_sig==1'b1)
	 begin
		vsync_reg1	<= 1'b0;
	    vsync_reg2	<= 1'b0;
	 end
	 else
	 begin
		vsync_reg1	<= VSYNC_i;
	    vsync_reg2	<= vsync_reg1;	 
	 
	 end
end	


always @(posedge PCLK_i or posedge fsm_rst_sig)
begin
	if (fsm_rst_sig)
	begin
	  
	 // hori_delay_datsample_cntr <= 0;
      RGB_byte0 				<= 8'h0;	  
      RGB_byte1 				<= 8'h0;	  
      RGB_byte2 				<= 8'h0;	  
      RGB_byte3 				<= 8'h0;	 

	  horizontal_cnt 		    <= 10'd0;	  
	  line_cnt 		 		    <= 10'd0;	

      word_index_sample_cnt     <= 	3'd1;  
	  
	  st_frame_trns 	 		<= ST_IDLE;
	  frame_receive_done 		<= 1'b0;
	  
	  clear_ena_frame_samp      <= 1'b0;
	
	end
	else
	begin
	
	   case (st_frame_trns)
	   
	   ST_IDLE : //Wait for Vsync edge
				//if (vsync_edge_detect==1'b1 && vsync == 1'b1 && ena_frame_samp==1'b1)
				begin
					if (vsync_edge_detect==1'b1 && VSYNC_i == 1'b1 && ena_frame_samp_sync_p2==1'b1)
					begin
						if (HREF_HSYN_n == 1)
						//if (HREF_HSYNC_i == 1)
						begin
							st_frame_trns <= ST_WAIT_FOR_HREF_1;
							clear_ena_frame_samp <= 1'b1;
					        horizontal_cnt 		 <= 10'd0;	  
	                        line_cnt 		     <= 10'd0;								
						end	
						else
						begin
							st_frame_trns <= ST_WAIT_FOR_HSYNC;
							clear_ena_frame_samp <= 1'b1;
					        horizontal_cnt 		 <= 10'd0;	  
	                        line_cnt 		     <= 10'd0;							
						end	
							
						frame_receive_done <= 1'b0;	
					end
					else
					begin
						clear_ena_frame_samp <= 1'b0;
					    st_frame_trns        <= ST_IDLE;
						//frame_receive_done   <= 1'b0;	//Commented Dec 7
						frame_receive_done   <= frame_receive_done;
						
					    //horizontal_cnt 		 <= 10'd0;	  
	                    //line_cnt 		     <= 10'd0;	
					    horizontal_cnt 		 <= horizontal_cnt;	  
	                    line_cnt 		     <= line_cnt;							
						word_index_sample_cnt     <= 	3'd1;  
						
						
					end
				end	
                
           				
	            
	   ST_WAIT_FOR_HREF_1 : 
	                 begin
						//wait for href =1
						//if href=1 then Sample the First byte if First byte sample is enable.
						//else ignore first sample and move forwards for sampling second byte.
						//if all byte sample is enabled sample first bytes followed by second and subsequent bytes.
						if (HREF_HSYNC_i==1'b1)
						begin
							if(sample_all_byte | even_byte_sel)
							begin
								RGB_byte0 <= RGB_DAT_i; 
								word_index_sample_cnt <= 1;
							end
							else
							begin
								RGB_byte0 <= 8'h0;
								word_index_sample_cnt <= 0;
							end
							clear_ena_frame_samp      <= 1'b0;
							st_frame_trns 			  <= ST_SAMPLE_LINE_DAT;
							horizontal_cnt            <= horizontal_cnt+1;
						end	
						else
						begin
						
						
						    st_frame_trns <= st_frame_trns;
                        end
                     end

	   ST_WAIT_FOR_HSYNC  : //will be added later
					       begin		
							////Delay the data sampling by 45*Tp 
	                        ////After delay Sample First Byte.
							//if (hori_delay_datsample_cntr=45)
							//
							//
							//
							//RGB_byte0 <= RGB_DAT_i;
							//st_frame_trns <= ST_SAMPLE_LINE_DAT;
							st_frame_trns        <= ST_IDLE;
						   end	
	   
	   
	   ST_SAMPLE_LINE_DAT  : 
							begin
							//Delay the data sampling by 45*Tp 
	                        //After delay Sample First Byte.
								//if ((horizontal_cnt == 10'd320 & frame_type_320 == 1) || (horizontal_cnt == 10'd640 & frame_type_640 == 1))
								if ((horizontal_cnt == 11'd640 & frame_type_320 == 1) || (horizontal_cnt == 11'd1280 & frame_type_640 == 1))
								begin
									//All data sampled. Decrement Line count.	
									horizontal_cnt <= 0;
									/*if ((line_cnt== 10'd240 & frame_type_320 == 1) || (line_cnt == 10'd480 & frame_type_640 == 1))
									begin
										st_frame_trns <= ST_IDLE;
										frame_receive_done <= 1'b1;
									end
									else
									begin */
									    line_cnt      <= line_cnt + 1;
										st_frame_trns <= ST_WAIT_FOR_HREF_0;
										frame_receive_done <= 1'b0;	
									//end
									
								end
								else
								begin
									horizontal_cnt <= horizontal_cnt+1;
								
									if(sample_all_byte==1'b1)
									begin
										case (horizontal_cnt[1:0])
											2'b00 : begin
														RGB_byte0 				<= RGB_DAT_i;
														word_index_sample_cnt   <= 1; 
													end 
											2'b01 : begin
														RGB_byte1 				<= RGB_DAT_i;
														word_index_sample_cnt   <= 2; 
													end											
											2'b10 : begin
														RGB_byte2 				<= RGB_DAT_i;
														word_index_sample_cnt   <= 3; 
													end 
											2'b11 : begin
														RGB_byte3 				<= RGB_DAT_i;
														word_index_sample_cnt   <= 4; 
													end									
									
										endcase
									end
									else if (even_byte_sel==1'b1)
									begin
										if (horizontal_cnt[0]==1'b0)
										begin
												case (horizontal_cnt[2:1])
													2'b00 : begin
																RGB_byte0 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 1; 
															end 
													2'b01 : begin
																RGB_byte1 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 2; 
															end											
													2'b10 : begin
																RGB_byte2 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 3; 
															end 
													2'b11 : begin
																RGB_byte3 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 4; 
															end									
											
												endcase								
										end
									end  
									else if (odd_byte_sel==1'b1)
									begin
										if (horizontal_cnt[0]==1'b1)
										begin
												case (horizontal_cnt[2:1])
													2'b00 : begin
																RGB_byte0 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 1; 
															end 
													2'b01 : begin
																RGB_byte1 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 2; 
															end											
													2'b10 : begin
																RGB_byte2 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 3; 
															end 
													2'b11 : begin
																RGB_byte3 				<= RGB_DAT_i;
																word_index_sample_cnt   <= 4; 
															end									
											
												endcase								
										end								
							        end
								   
								   st_frame_trns <= ST_SAMPLE_LINE_DAT;	   
	                          end
	                       end
	   
		 ST_WAIT_FOR_HREF_0 : begin
		                          if (HREF_HSYNC_i==1'b0)
		                          begin
								    if ((line_cnt== 10'd240 & frame_type_320 == 1) || (line_cnt == 10'd480 & frame_type_640 == 1))
									begin
										st_frame_trns <= ST_IDLE;
										frame_receive_done <= 1'b1;
										//line_cnt <= 0;//Commented Dec 7
										line_cnt      <= line_cnt;
									end
								    else
									begin
									    st_frame_trns <= ST_WAIT_FOR_HREF_1;//ST_IDLE;
									    //line_cnt      <= line_cnt + 1;
									end   
								  end
								  else
								  begin
									 st_frame_trns <= st_frame_trns;
									 line_cnt      <= line_cnt;
		                          end
							  end

				

	  
       endcase 
	end
end

//Push Create 32 bit data and push to Rx FIFO.
always @(posedge PCLK_i or posedge rst_i)
begin
    if (rst_i)
	begin
	   RGB_data_32 <= 32'h0;
	   RGB_Rx_Push <= 1'b0;
	   RGB_Rx_Push1 <= 1'b0;
	end
	else
	begin
		if (word_index_sample_cnt==3'd4)
		begin 
			RGB_Rx_Push <= 1'b1;	
			RGB_Rx_Push1 <= RGB_Rx_Push;
			RGB_data_32 <= {RGB_byte3,RGB_byte2,RGB_byte1,RGB_byte0}; 
`ifdef SIM
			#1;
			if (RGB_data_32==32'haaaaaa55)
			   $stop();


`endif			
		end
		else
		begin
			RGB_Rx_Push <= 1'b0;	
			RGB_Rx_Push1 <= RGB_Rx_Push;
	    end
	end
end



assign RGB_data_32_o = RGB_data_32;
assign RGB_Rx_Push_o = RGB_Rx_Push & ~RGB_Rx_Push1;

endmodule
