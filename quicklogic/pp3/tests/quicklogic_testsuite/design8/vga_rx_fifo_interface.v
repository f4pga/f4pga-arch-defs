// -----------------------------------------------------------------------------
// title          : In VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : vga_rx_fifo_interface.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/11/10	
// last update    : 2016/11/12
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description:  
// -----------------------------------------------------------------------------
// copyright (c) 2017
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2017/11/10      1.0        Anand Wadke     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

//`define SIM
module vga_rx_fifo_interface ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                        					 
						 WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,
                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_DAT_o,
                         WBs_ACK_o,
						 
						 PCLK_i,
						 
						 Rx_FIFO_Flush_i,			
						 
						 thresh_line_cnt_reached_o,	
						 
						
						 Rx_FIFO_data_cnt_o,         
						 
						 thresh_line_count_dw_i,		
						 							
						 Rx_FIFO_Push_i,         	
						 Rx_FIFO_DAT_i,          	
						 					
						 Rx_overflow_detected_o,     
						 
						 Rx_FIFO_Empty_o,        	
						 Rx_FIFO_Full_o,         	
						 Rx_FIFO_Pop_flag_o,     	
						 Rx_FIFO_push_flag_o  	
 
						 );
						 
parameter                ADDRWIDTH             =  7            ; // 
parameter                DATAWIDTH             = 32            ; // 	
					 
parameter                VGA_RGB_RXDATA_REG_ADR    	   =  7'h0         ; // Command Queue Status     Register					 
						 
// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric

input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input             [1:0]  WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric						 

input 					 PCLK_i;

input					Rx_FIFO_Flush_i;			

output					thresh_line_cnt_reached_o;	

output	[10:0]			Rx_FIFO_data_cnt_o ;        

input	[9:0]			thresh_line_count_dw_i	;	
							
input					Rx_FIFO_Push_i;         	
input	[31:0]			Rx_FIFO_DAT_i;          	
					
output					Rx_overflow_detected_o;     

output					Rx_FIFO_Empty_o ;       	
output					Rx_FIFO_Full_o  ;      	
output	[3:0]			Rx_FIFO_Pop_flag_o ;    	
output	[3:0]			Rx_FIFO_push_flag_o ;   	


//----------------------------------------------------
wire 			[31:0]   Rx_FIFO_DAT_dout;					 
			 

wire                     Rx_fifo_Rd_Dcd; 						 
wire                     Rx_fifo_push_sig; 	
wire                     Rx_fifo_pop_sig; 	

wire 			[3:0] 	push_flag_sig;					 
wire 			[3:0] 	pop_flag_sig;	

reg 			[10:0] 	rx_fifo_cntr;	

reg 					WBs_ACK_rx_fifo;

reg 					Rx_fifo_Rd_Dcd_r1;		
reg 					Rx_fifo_Rd_Dcd_r2;		
reg 					Rx_fifo_Rd_Dcd_r3;		

reg 					thresh_line_cnt_reached;
reg 					Rx_overflow_detected_pclk;
reg 					Rx_overflow_detected_r1;
reg 					Rx_overflow_detected_r2;

wire 					Rx_FIFO_Full;

reg 					rx_push_toggle;
reg 					rx_push_sync_wb0;
reg 					rx_push_sync_wb1;
reg 					rx_push_sync_wb2;

wire				    rx_fifo_cntr_rst;
wire				    Rx_FIFO_Empty_w;
reg				    Rx_FIFO_Empty_r1;
reg				    Rx_FIFO_Empty_r2;


assign WBs_ACK_o_nxt        =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);
assign WBs_ACK_o			=   WBs_ACK_rx_fifo;		 
						 
assign Rx_fifo_Rd_Dcd 		= ( WBs_ADR_i == VGA_RGB_RXDATA_REG_ADR) & WBs_CYC_i & WBs_STB_i &   ~WBs_WE_i   & (~WBs_ACK_o) ;

//assign      Rx_fifo_pop_sig = ~Rx_fifo_Rd_Dcd_r3 & Rx_fifo_Rd_Dcd_r2;
assign      Rx_fifo_pop_sig = (Rx_FIFO_Empty_r1==1'b0) ? (~Rx_fifo_Rd_Dcd_r3 & Rx_fifo_Rd_Dcd_r2) : 1'b0;

assign      Rx_FIFO_Full_o  = Rx_FIFO_Full;//(push_flag_sig==4'h0)? 1'b1 : 1'b0;
assign      Rx_FIFO_Empty_o = Rx_FIFO_Empty_w;
assign      Rx_FIFO_Empty_w = (pop_flag_sig==4'h0)? 1'b1 : 1'b0;
assign      Rx_FIFO_Full    = (push_flag_sig==4'h0)? 1'b1 : 1'b0;

assign      Rx_FIFO_pop_flag_o  = pop_flag_sig;
assign      Rx_FIFO_push_flag_o = push_flag_sig;

always @(posedge WBs_CLK_i or posedge WBs_RST_i )
begin
    if (WBs_RST_i)
    begin
		Rx_FIFO_Empty_r1    <=  1'b0;
		Rx_FIFO_Empty_r2    <=  1'b0;
	end
	else
	begin
		Rx_FIFO_Empty_r1    <=  Rx_FIFO_Empty_w;
		Rx_FIFO_Empty_r2    <=  Rx_FIFO_Empty_r1;
    end
end


always @(posedge WBs_CLK_i or posedge WBs_RST_i )
begin
    if (WBs_RST_i)
    begin
		Rx_fifo_Rd_Dcd_r1    <=  1'b0;
		Rx_fifo_Rd_Dcd_r2    <=  1'b0;
		Rx_fifo_Rd_Dcd_r3    <=  1'b0;
	end
	else
	begin
		Rx_fifo_Rd_Dcd_r1    <=  Rx_fifo_Rd_Dcd;
		Rx_fifo_Rd_Dcd_r2    <=  Rx_fifo_Rd_Dcd_r1;
		Rx_fifo_Rd_Dcd_r3    <=  Rx_fifo_Rd_Dcd_r2;
    end
end

assign      Rx_fifo_push_sig = (Rx_FIFO_Full == 1'b1 ) ? 1'b0 : Rx_FIFO_Push_i;
						 
af1024x16_1024x16         u_vga_rx_af1024x16_1024x16_0
                            (
        .DIN                ( Rx_FIFO_DAT_i[15:0]			),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush_i       ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush_i       ),
        .PUSH               ( Rx_fifo_push_sig          ),
        .POP                ( Rx_fifo_pop_sig         ),
        .Push_Clk           ( PCLK_i             ),
        .Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1             ),
        .Pop_Clk_En         ( 1'b1             ),
        .Fifo_Dir           ( 1'b1                  ),
        .Async_Flush        ( Rx_FIFO_Flush_i       ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (  push_flag_sig        ),
        .POP_FLAG           (  pop_flag_sig         ),
        .DOUT               ( Rx_FIFO_DAT_dout[15:0]	)
                                                    );	
													
af1024x16_1024x16         u_vga_rx_af1024x16_1024x16_1
                            (
        .DIN                ( Rx_FIFO_DAT_i[31:16]			),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush_i       ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush_i       ),
        .PUSH               ( Rx_fifo_push_sig          ),
        .POP                ( Rx_fifo_pop_sig         ),
        .Push_Clk           ( PCLK_i             ),
        .Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1             ),
        .Pop_Clk_En         ( 1'b1             ),
        .Fifo_Dir           ( 1'b1                  ),
        .Async_Flush        ( Rx_FIFO_Flush_i       ),
        .Almost_Full        (          ),
        .Almost_Empty       (          ),
        .PUSH_FLAG          (          ),
        .POP_FLAG           (          ),
        .DOUT               ( Rx_FIFO_DAT_dout[31:16]	)
                                                    );													
													
     													
											
assign      WBs_DAT_o       = Rx_FIFO_DAT_dout;						 

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		WBs_ACK_rx_fifo    <=  1'b0;
	end
	else
	begin
		WBs_ACK_rx_fifo    <=  WBs_ACK_o_nxt;					
	end		
end	


//assign rx_fifo_cntr_rst = Rx_FIFO_Flush_i | WBs_RST_i;//Commneted for testing-Dec7
assign rx_fifo_cntr_rst = Rx_FIFO_Flush_i | WBs_RST_i | Rx_overflow_detected_r2;

//Fifo counter 
//always @(posedge PCLK_i or posedge WBs_RST_i)
always @(posedge PCLK_i or posedge rx_fifo_cntr_rst)
begin
     //if (WBs_RST_i)
     if (rx_fifo_cntr_rst)
	 begin
	     rx_push_toggle <= 1'b0;
	 end
	 else
	 begin
	     if (Rx_FIFO_Push_i)
		 begin
			rx_push_toggle <= ~rx_push_toggle;
		 end
	 end
end

//always @( posedge WBs_CLK_i or posedge WBs_RST_i)
always @( posedge WBs_CLK_i or posedge rx_fifo_cntr_rst)
begin
     //if (WBs_RST_i)
     if (rx_fifo_cntr_rst)
	 begin
	     rx_push_sync_wb0 <= 1'b0;
	     rx_push_sync_wb1 <= 1'b0;
	     rx_push_sync_wb2 <= 1'b0;
	 
	 end
	 else
	 begin
		rx_push_sync_wb0  <= rx_push_toggle;	
		rx_push_sync_wb1  <= rx_push_sync_wb0;	
		rx_push_sync_wb2  <= rx_push_sync_wb1;	

     end
end

assign wb_push_clk = (rx_push_sync_wb1 && ~rx_push_sync_wb2) || (~rx_push_sync_wb1 && rx_push_sync_wb2);

//always @( posedge WBs_CLK_i or posedge WBs_RST_i)
always @( posedge WBs_CLK_i or posedge rx_fifo_cntr_rst)
begin
     //if (WBs_RST_i)
     if (rx_fifo_cntr_rst)
	 begin
	    rx_fifo_cntr  <= {11{1'b0}};
	 end
	 else
	 begin
	    if (wb_push_clk==1'b1 && Rx_fifo_pop_sig==1'b1)
		begin
			rx_fifo_cntr  <= rx_fifo_cntr;
		end	
		else if (wb_push_clk==1'b1)
		begin
			rx_fifo_cntr  <= rx_fifo_cntr + 1;
		end
		else if (Rx_fifo_pop_sig==1'b1)
		begin
		    rx_fifo_cntr  <= rx_fifo_cntr - 1;
	    end
		else
		begin
			rx_fifo_cntr  <= rx_fifo_cntr;
	    end
	 end
end

assign Rx_FIFO_data_cnt_o = rx_fifo_cntr;

assign thresh_line_cnt_reached_o = thresh_line_cnt_reached;

//always @( posedge WBs_CLK_i or posedge WBs_RST_i)
always @( posedge WBs_CLK_i or posedge rx_fifo_cntr_rst)
begin
     //if (WBs_RST_i)
     if (rx_fifo_cntr_rst)
	 begin
	    thresh_line_cnt_reached  <= 1'b0;
	 end    
	else
	begin
`ifdef OLD_THRESH_INTR_IMPL	
		if ( rx_fifo_cntr ==  thresh_line_count_dw_i)
		begin
			thresh_line_cnt_reached  <= 1'b1;
		end
		else
		begin
		    thresh_line_cnt_reached  <= 1'b0;
	    end
`else
		if ( rx_fifo_cntr ==  thresh_line_count_dw_i)
		begin
			thresh_line_cnt_reached  <= 1'b1;
		end
		else if ( rx_fifo_cntr ==  (thresh_line_count_dw_i-1))
		begin
		    thresh_line_cnt_reached  <= 1'b0;
	    end
		else
		begin
			thresh_line_cnt_reached  <= thresh_line_cnt_reached;
		end




`endif		
    end
end

//always @( posedge PCLK_i or posedge WBs_RST_i)
always @( posedge PCLK_i or posedge rx_fifo_cntr_rst)
begin
     //if (WBs_RST_i)
     if (rx_fifo_cntr_rst)
	 begin
	    Rx_overflow_detected_pclk  <= 1'b0;
	 end    
	else
	begin
		if ( Rx_FIFO_Full ==  1'b1) 
		begin
		    if (Rx_FIFO_Push_i == 1'b1)
			begin
				Rx_overflow_detected_pclk  <= 1'b1;
			end
			else
            begin
				Rx_overflow_detected_pclk  <= Rx_overflow_detected_pclk;
			end
	    end
		else
		begin
		    Rx_overflow_detected_pclk  <= 1'b0;
	    end
    end
end	

assign Rx_overflow_detected_o = Rx_overflow_detected_r2;

//always @( posedge WBs_CLK_i or posedge WBs_RST_i)
always @( posedge WBs_CLK_i or posedge rx_fifo_cntr_rst)
begin
	 //if (WBs_RST_i)
	 if (rx_fifo_cntr_rst)
	 begin
	    Rx_overflow_detected_r1  <= 1'b0;
	    Rx_overflow_detected_r2  <= 1'b0;
	 end 
     else
     begin
		Rx_overflow_detected_r1 <= Rx_overflow_detected_pclk;
		Rx_overflow_detected_r2 <= Rx_overflow_detected_r1;
     end
end

`ifdef SIM
integer fifo_push_cnt;
integer fifo_pop_cnt;
integer fifo_push_pop_cnt_diff;

initial
begin
fifo_push_cnt=0;
fifo_pop_cnt=0;
fifo_push_pop_cnt_diff=0;

end


always @(posedge Rx_FIFO_Push_i)
begin
	fifo_push_cnt = fifo_push_cnt + 1;
end

always @(posedge Rx_fifo_pop_sig)
begin
	fifo_pop_cnt = fifo_pop_cnt + 1;
end

always @(*)
begin
	if (fifo_push_cnt>fifo_pop_cnt)
		fifo_push_pop_cnt_diff = fifo_push_cnt - fifo_pop_cnt;
	else 
		fifo_push_pop_cnt_diff = fifo_pop_cnt-fifo_push_cnt;		
		

end
`endif
 
	
endmodule					 