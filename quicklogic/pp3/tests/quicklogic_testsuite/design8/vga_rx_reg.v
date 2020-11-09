// -----------------------------------------------------------------------------
// title          : In VGA sample IP Module vga RX Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : vga_rx_reg.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/11/09	
// last update    : 2016/11/09
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description:  
// -----------------------------------------------------------------------------
// copyright (c) 2017
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2017/11/09      1.0        Anand Wadke     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
//`define SIM
`define NEW_LINE_THRESH_UPDATE
`define NOT_EMPTY_ASSP_CTRL_TRIG
module vga_rx_reg ( 

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
						 
						 Rx_fifo_data_i,

						 fsm_sts_i,
						 rcvd_line_cnt_i,
						 vga_interrut_o,
                         // Vga control status
						 vga_ctrl_reg_o,
                         clear_ena_frame_samp_i,	//from FSM					 

                         // Rx
						 thresh_line_cnt_reached_i,
						 rxfifo_overflow_detected_i,

						 Rx_FIFO_DAT_cnt_i,
						 
                         thresh_line_count_dw_o,						 

                         Rx_FIFO_Empty_i,
                         Rx_FIFO_Full_i,
						 Rx_FIFO_Pop_flag_i,
						 Rx_FIFO_push_flag_i,

                         Rx_FIFO_Flush_o,
						 
						 //DMA
						 DMA_done_i,	
						 DMA_active_i,
						 DMA_Done_IRQ_o,
						 DMA_Clr_i,
						 DMA_REQ_i,						 
						 DMA_ena_o

                         );


//------Port Parameters----------------
//

parameter       ADDRWIDTH                   	=   10           ;
parameter       DATAWIDTH                   	=  32           ;

//Parameters
parameter       IN_VGA_STATUS_REG_ADDR 		   = 5'h0 ;	
parameter       IN_VGA_CONTROL_REG_ADR		   = 5'h1 ;
parameter       IN_VGA_RX_FIFO_DATCNT_REG_ADR	   = 5'h2 ;
parameter       IN_VGA_RX_FIFO_LINECNT_REG_ADR   = 5'h3 ;
parameter       IN_VGA_DMA_CONTROL_REG_ADR	   = 5'h4 ;
parameter       IN_VGA_DMA_STATUS_REG_ADR	       = 5'h5 ;
parameter       IN_VGA_RGB_RXDATA_REG_ADR	       = 5'h6 ;
parameter       IN_VGA_DEBUG_REG_ADR	       	   = 5'h7 ;
parameter       IN_VGA_DEF_REG_VALUE			   = 32'hC0C_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

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

input 	[DATAWIDTH-1:0]  Rx_fifo_data_i;

// Command Queue
//
input            [7:0]   fsm_sts_i       ;
input            [9:0]   rcvd_line_cnt_i       ;

output            	     vga_interrut_o  ;
output          [15:0]   vga_ctrl_reg_o  ;
input 					 clear_ena_frame_samp_i;

input          			thresh_line_cnt_reached_i;
input          			rxfifo_overflow_detected_i;	
input             [10:0]  Rx_FIFO_DAT_cnt_i ;

output          [9:0]	thresh_line_count_dw_o;	

input                    Rx_FIFO_Empty_i ;
input                    Rx_FIFO_Full_i  ;
input             [3:0]  Rx_FIFO_Pop_flag_i ;
input             [3:0]  Rx_FIFO_push_flag_i ;

output                   Rx_FIFO_Flush_o ;

input                    DMA_done_i	 ;
input                    DMA_active_i ;
output                   DMA_Done_IRQ_o ;
input	 				 DMA_Clr_i;
input	 				 DMA_REQ_i; 
output                   DMA_ena_o ;


// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset
// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [1:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_vga_cntr       ; // Wishbone Client Acknowledge
reg                      WBs_ACK_dma_cntr       ; // Wishbone Client Acknowledge

wire                     Rx_FIFO_Empty_i ;
wire                     Rx_FIFO_Full_i  ;

//wire              [3:0]  Rx_FIFO_Pop_flag_i ;
//wire              [3:0]  Rx_FIFO_push_flag_i ;


wire                     VGA_CTRL_Wr_Dcd;    
wire                     VGA_DMA_CTRL_Wr_Dcd;    

wire                     rxfifofullIntr_Sts_Dcd  ;
reg                      Rx_FIFO_FULL_i_1ff ;

reg 					 dma_ena;
wire 					 frame_receive_done;
reg 					 frame_rcvd_Done_IRQ;
reg 					 trigg_line_rcvd_IRQ;
reg 					 fifo_full_IRQ;
reg 					 fifo_overflow_IRQ;
reg 					 DMA_Done_IRQ;
reg 					 DMA_Done_IRQ_EN;

//Control Reg signals
reg 					 frame_receive_ena;
reg 					 master_intr_ena;
reg                      Rx_FIFO_Flush ;
reg                      Rx_FIFO_Full_intr_ena ;
reg                      Rx_FIFO_overflow_intr_ena ;
reg                      Rx_FIFO_threhold_line_intr_ena ;
reg                      Rx_frame_recived_intr_ena ;
reg      [1:0]           Rx_sel_frame_size ;
reg                      Rx_alternate_byte_sel ;
reg                      Rx_alternate_byte_posi ;
reg 	 [1:0]           line_threshold_sel;  


wire 					frame_xfer_intr;        	
wire                    rxfifo_linethreshold_intr;
wire                    rxfifo_full_intr;        	
wire                    rxfifo_overflow_intr; 

wire   [9:0]            line_count_320_dw;    
wire   [9:0]            line_count_640_dw;    

wire					dma_rst;

reg thresh_line_cnt_reached_r1,thresh_line_cnt_reached_r2,thresh_line_cnt_reached_r3;
wire thresh_line_cnt_reached_w;
reg frame_receive_done_r1,frame_receive_done_r2,frame_receive_done_r3;
wire frame_receive_done_w;
reg rxfifo_overflow_detected_r1,rxfifo_overflow_detected_r2,rxfifo_overflow_detected_r3;
wire rxfifo_overflow_detected_w;

//pragma attribute DMA_done_i preserve_signal true
//pragma attribute dma_ena preserve_signal true
//pragma attribute DMA_Done_IRQ preserve_signal true

//------Logic Operations---------------
//
// Determine each register decode
//
assign DMA_Done_IRQ_o               = DMA_Done_IRQ;
assign VGA_CTRL_Wr_Dcd  			= ( WBs_ADR_i == IN_VGA_CONTROL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign VGA_DMA_CTRL_Wr_Dcd  		= ( WBs_ADR_i == IN_VGA_DMA_CONTROL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;

// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt                = WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);
assign WBs_ACK_o					= WBs_ACK_vga_cntr | WBs_ACK_dma_cntr;

assign DMA_ena_o                    = dma_ena;

assign Rx_FIFO_Flush_o				= Rx_FIFO_Flush;

assign frame_receive_done 			= fsm_sts_i[0];

`ifdef NEW_LINE_THRESH_UPDATE

assign thresh_line_count_dw_o       = 	(line_threshold_sel == 2'b00) ? 10'd960 : 	
									    (line_threshold_sel == 2'b01) ? 10'd480 : 10'd960;


`else

assign line_count_320_dw            =   (line_threshold_sel == 2'b00) ? 10'd960 : 
									    (line_threshold_sel == 2'b01) ? 10'd480 :
										(line_threshold_sel == 2'b10) ? 10'd240 : 10'd120 ;

/* assign line_count_640_dw            =   (line_threshold_sel == 2'b00) ? 10'd960 : 
									    (line_threshold_sel == 2'b01) ? 10'd960 :
										(line_threshold_sel == 2'b10) ? 10'd480 : 10'd240 ;	 */
//New Update November 19										
assign line_count_640_dw            =   (line_threshold_sel == 2'b00) ? 10'd960 : 
									    (line_threshold_sel == 2'b01) ? 10'd640 :
										(line_threshold_sel == 2'b10) ? 10'd320 : 10'd960 ;										
										

//assign thresh_line_count_dw_o       =   (Rx_sel_frame_size[0]==0) ? line_count_320_dw : line_count_640_dw;
assign thresh_line_count_dw_o       =   (Rx_sel_frame_size[0]==0) ? 
										((Rx_alternate_byte_sel==1) ? line_count_320_dw : {line_count_320_dw,1'b0}): 
										line_count_640_dw;
`endif										



assign vga_ctrl_reg_o               = { 1'b0,line_threshold_sel,
											 Rx_alternate_byte_posi,
											 Rx_alternate_byte_sel,
										     Rx_sel_frame_size,
											 1'b0,
											 1'b0,
											 Rx_frame_recived_intr_ena,
											 Rx_FIFO_threhold_line_intr_ena,
                                             Rx_FIFO_overflow_intr_ena,
                                             Rx_FIFO_Full_intr_ena,
											 Rx_FIFO_Flush, 
											 master_intr_ena,		
											 frame_receive_ena};	







assign thresh_line_cnt_reached_w = thresh_line_cnt_reached_r2 & ~thresh_line_cnt_reached_r3;

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
	   thresh_line_cnt_reached_r1 <= 1'b0;
	   thresh_line_cnt_reached_r2 <= 1'b0;
	   thresh_line_cnt_reached_r3 <= 1'b0;
	   
	end
	else
	begin
	   thresh_line_cnt_reached_r1 <= thresh_line_cnt_reached_i;
	   thresh_line_cnt_reached_r2 <= thresh_line_cnt_reached_r1;	  
	   thresh_line_cnt_reached_r3 <= thresh_line_cnt_reached_r2;	  
	end
end	



assign frame_receive_done_w = frame_receive_done_r2 & ~frame_receive_done_r3;

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
	   frame_receive_done_r1 <= 1'b0;
	   frame_receive_done_r2 <= 1'b0;
	   frame_receive_done_r3 <= 1'b0;
	   
	end
	else
	begin
	   frame_receive_done_r1 <= frame_receive_done;
	   frame_receive_done_r2 <= frame_receive_done_r1;	  
	   frame_receive_done_r3 <= frame_receive_done_r2;	  
	end
end

assign rxfifo_overflow_detected_w = rxfifo_overflow_detected_r2 & ~rxfifo_overflow_detected_r3;

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
	   rxfifo_overflow_detected_r1 <= 1'b0;
	   rxfifo_overflow_detected_r2 <= 1'b0;
	   rxfifo_overflow_detected_r3 <= 1'b0;
	   
	end
	else
	begin
	   rxfifo_overflow_detected_r1 <= rxfifo_overflow_detected_i;
	   rxfifo_overflow_detected_r2 <= rxfifo_overflow_detected_r1;	  
	   rxfifo_overflow_detected_r3 <= rxfifo_overflow_detected_r2;	  
	end
end
											 

// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

        Rx_FIFO_FULL_i_1ff  			<=  1'b0;
		
		frame_rcvd_Done_IRQ         	<=  1'b0;
		trigg_line_rcvd_IRQ         	<=  1'b0;
		fifo_full_IRQ					<=  1'b0;		
		fifo_overflow_IRQ				<=  1'b0;		
		
		frame_receive_ena				<= 1'b0;		
		master_intr_ena					<= 1'b0;
		Rx_FIFO_Flush 					<= 1'b0;
		Rx_FIFO_Full_intr_ena 			<= 1'b0;
		Rx_FIFO_overflow_intr_ena 		<= 1'b0;
		Rx_FIFO_threhold_line_intr_ena 	<= 1'b0;
		Rx_frame_recived_intr_ena 		<= 1'b0;
		Rx_sel_frame_size 				<= 2'b00;
		Rx_alternate_byte_sel 			<= 1'b0;
		Rx_alternate_byte_posi 			<= 1'b0;
		line_threshold_sel				<= 2'b00;

        WBs_ACK_vga_cntr            <=  1'b0;
    end  
    else
    begin
        // FIFO Control Register
        if ( VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin

			frame_receive_ena				<=  WBs_DAT_i[0];	
			master_intr_ena					<=  WBs_DAT_i[1];	
			Rx_FIFO_Flush 					<=  WBs_DAT_i[2];	
			Rx_FIFO_Full_intr_ena 			<=  WBs_DAT_i[3]; 	
			Rx_FIFO_overflow_intr_ena 		<=  WBs_DAT_i[4];	
			Rx_FIFO_threhold_line_intr_ena 	<=  WBs_DAT_i[5];	
			Rx_frame_recived_intr_ena 		<=  WBs_DAT_i[6];	
			Rx_sel_frame_size 				<=  WBs_DAT_i[10:9];	
			Rx_alternate_byte_sel 			<=  WBs_DAT_i[11];	
			Rx_alternate_byte_posi 			<=  WBs_DAT_i[12]; 	
			line_threshold_sel				<=  WBs_DAT_i[14:13]; 	  
			
        end
		else
		begin
			Rx_FIFO_Flush     			<=  1'b0;
		    if (clear_ena_frame_samp_i==1'b1)
			begin
		       frame_receive_ena	    <=  1'b0;
			end
		end
		

		
        // Determine the Interrupt Status
		//if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || thresh_line_cnt_reached_i)
		if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || thresh_line_cnt_reached_w)
        begin
            trigg_line_rcvd_IRQ   <=  thresh_line_cnt_reached_w ? 1'b1 : WBs_DAT_i[7];
        end	
		
		//if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || frame_receive_done)
		if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || frame_receive_done_w)
        begin
            frame_rcvd_Done_IRQ   <=  frame_receive_done_w ? 1'b1 : WBs_DAT_i[8];
        end
		
        if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || rxfifofullIntr_Sts_Dcd)
        begin
            fifo_full_IRQ   <=  rxfifofullIntr_Sts_Dcd;
        end

        //if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || rxfifo_overflow_detected_i)
        if ( (VGA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || rxfifo_overflow_detected_w)
        begin
            fifo_overflow_IRQ   <=  rxfifo_overflow_detected_w;
        end		
		
        Rx_FIFO_FULL_i_1ff   <=  Rx_FIFO_Full_i;
        WBs_ACK_vga_cntr     <=  WBs_ACK_o_nxt;
    end  
end


// Detect when the Rx FIFO has become Full
assign rxfifofullIntr_Sts_Dcd    =  ((~Rx_FIFO_FULL_i_1ff) & Rx_FIFO_Full_i);
// Determine the interrupt output
assign frame_xfer_intr        			= (frame_rcvd_Done_IRQ && Rx_frame_recived_intr_ena);
assign rxfifo_linethreshold_intr        = (trigg_line_rcvd_IRQ && Rx_FIFO_threhold_line_intr_ena);
assign rxfifo_full_intr        			= (fifo_full_IRQ && Rx_FIFO_Full_intr_ena);
assign rxfifo_overflow_intr        		= (fifo_overflow_IRQ && Rx_FIFO_overflow_intr_ena);

assign vga_interrut_o  = (frame_xfer_intr | rxfifo_linethreshold_intr | rxfifo_full_intr | rxfifo_overflow_intr) & master_intr_ena;


//Write control to DMA register
// Define the Fabric's Local Registers
`ifdef NOT_EMPTY_ASSP_CTRL_TRIG
always @( posedge WBs_CLK_i or posedge WBs_RST_i )
begin
    if (WBs_RST_i)
    begin
		DMA_Done_IRQ_EN 		 <= 1'b0; 
		WBs_ACK_dma_cntr         <=  1'b0;
	end
    else
    begin
		if ( VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) 
            DMA_Done_IRQ_EN  <=  WBs_DAT_i[1];	
			
        WBs_ACK_dma_cntr               <=  WBs_ACK_o_nxt;
    end
end

assign dma_rst = WBs_RST_i | DMA_done_i ;
always @( posedge WBs_CLK_i or posedge dma_rst )
begin
    if (dma_rst)
    begin
		dma_ena	 	  			 <= 1'b0;
    end  
    else
    begin
        if ( VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0])
            dma_ena  <=  WBs_DAT_i[0];
    end  
end

always @( posedge WBs_CLK_i or posedge WBs_RST_i or posedge DMA_done_i)
begin
    if (WBs_RST_i)
    begin
		DMA_Done_IRQ    	     <= 1'b0;
    end 
    else if (DMA_done_i)
		DMA_Done_IRQ    	     <= 1'b1;
    else
    begin
		if ( (VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]))
        begin
           DMA_Done_IRQ   <=  WBs_DAT_i[2];
        end
    end  
end

`else
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

		dma_ena	 	  			 <= 1'b0;
		DMA_Done_IRQ_EN 		 <= 1'b0; 
		DMA_Done_IRQ    	     <= 1'b0;
				
		WBs_ACK_dma_cntr         <=  1'b0;
    end  
    else
    begin
	
        if ( VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0])
            dma_ena  <=  WBs_DAT_i[0];
		else if (DMA_Clr_i)
			dma_ena  <=  1'b0;
			
		if ( VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) 
            DMA_Done_IRQ_EN  <=  WBs_DAT_i[1];
			
		if ( (VGA_DMA_CTRL_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA_done_i)
        begin
            DMA_Done_IRQ   <=  DMA_done_i ? 1'b1 : WBs_DAT_i[2];
        end
		
        WBs_ACK_dma_cntr               <=  WBs_ACK_o_nxt;
    end  
end
`endif

// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i                    	or
		 
         rcvd_line_cnt_i               	or
         Rx_FIFO_DAT_cnt_i             	or
         
		 frame_rcvd_Done_IRQ     		or    	
		 trigg_line_rcvd_IRQ         	or 
		 fifo_full_IRQ					or 
		 fifo_overflow_IRQ				or 
		 frame_receive_ena				or 
		 master_intr_ena				or 	
		 Rx_FIFO_Flush 					or 
		 Rx_FIFO_Full_intr_ena 			or 
		 Rx_FIFO_overflow_intr_ena 		or 
		 Rx_FIFO_threhold_line_intr_ena or 	
		 Rx_frame_recived_intr_ena 		or 
		 Rx_sel_frame_size 				or 
		 Rx_alternate_byte_sel 			or 
		 Rx_alternate_byte_posi 		or 	
		 line_threshold_sel				or 
         dma_ena						or	 	  	
         DMA_Done_IRQ_EN                or
         DMA_Done_IRQ                   or
		 fsm_sts_i                      or
		 DMA_active_i                   or
		 Rx_fifo_data_i

 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
		IN_VGA_STATUS_REG_ADDR        : WBs_DAT_o <= { 28'h0, 
														 frame_rcvd_Done_IRQ,
														 trigg_line_rcvd_IRQ,
														 fifo_overflow_IRQ,
                                                         fifo_full_IRQ      };

		IN_VGA_CONTROL_REG_ADR	    : WBs_DAT_o <= { 17'h0, 		
														line_threshold_sel,
                                                        Rx_alternate_byte_posi,
													    Rx_alternate_byte_sel,
													    Rx_sel_frame_size,
													    1'b0,
													    1'b0,
													    Rx_frame_recived_intr_ena,
													    Rx_FIFO_threhold_line_intr_ena,
                                                        Rx_FIFO_overflow_intr_ena,
                                                        Rx_FIFO_Full_intr_ena,
													    Rx_FIFO_Flush, 
														master_intr_ena,		
														frame_receive_ena};		
    
		IN_VGA_RX_FIFO_DATCNT_REG_ADR  : WBs_DAT_o <= 	{21'h0,Rx_FIFO_DAT_cnt_i};
	
		IN_VGA_RX_FIFO_LINECNT_REG_ADR : WBs_DAT_o <= 	{21'h0,rcvd_line_cnt_i};
	
		IN_VGA_DMA_CONTROL_REG_ADR     : WBs_DAT_o <=     { 29'h0, DMA_Done_IRQ, DMA_Done_IRQ_EN,dma_ena};
	
		IN_VGA_DMA_STATUS_REG_ADR		 : WBs_DAT_o <=     { 28'h0, line_threshold_sel, DMA_active_i,DMA_Done_IRQ};
	
		IN_VGA_DEBUG_REG_ADR		 	 : WBs_DAT_o <=     { 24'h0, fsm_sts_i};
		
		IN_VGA_RGB_RXDATA_REG_ADR 	 : WBs_DAT_o <=      Rx_fifo_data_i;
	
		default                          : WBs_DAT_o <=      IN_VGA_DEF_REG_VALUE ;
	endcase
end

`ifdef SIM
reg [10:0] line_interrupt_count;
initial
begin
    line_interrupt_count <= 0;
end

always @(posedge thresh_line_cnt_reached_i or posedge frame_receive_done)
begin
     if (frame_receive_done)
	 begin
		line_interrupt_count <= 0;
	 end
	 else
	 begin
	   line_interrupt_count <= line_interrupt_count+1;
	 
     end
end

`endif

endmodule
