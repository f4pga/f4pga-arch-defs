// -----------------------------------------------------------------------------
// title          : I2S Slave + DMA Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_w_DMA_Registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2S Slave register and DMA registers
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author                   description
// 2017/03/23      1.0        Rakesh Moolacheri      Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module i2s_slave_w_DMA_registers ( 
                         
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

			i2s_dis_i,
            
            I2S_S_EN_o,        
            Rx_FIFO_Flush_o,    
            
            L_RXFIFO_DAT_i,     
            L_RXFIFO_Pop_o,   
            
            R_RXFIFO_DAT_i,     
            R_RXFIFO_Pop_o,     
            
            LR_RXFIFO_Pop_o,    
			
			STEREO_EN_o,
			LR_CHNL_SEL_o,     
			LR_RXFIFO_DAT_i,   
			LR_Rx_FIFO_Full_i, 
			LR_Rx_FIFO_Empty_i,		
			LR_Rx_FIFO_Level_i,
            
			L_Rx_FIFO_Empty_i,  	
			L_Rx_FIFO_Full_i,   	
			L_Rx_FIFO_Level_i,  	
				
			R_Rx_FIFO_Empty_i,  	
			R_Rx_FIFO_Full_i,   	
			R_Rx_FIFO_Level_i,  	
				
			L_RX_DAT_IRQ_o,       	
			L_RX_DAT_IRQ_EN_o,  

			R_RX_DAT_IRQ_o,       	
			R_RX_DAT_IRQ_EN_o,
				
			DMA_Busy_i,         	
			DMA_Clr_i,          	
			DMA_Done_i,         	
			DMA_Active_i,       	
			DMA_REQ_i,    
			dma_cntr_i,
			dma_st_i,
				
			I2S_Dis_IRQ_o,
			I2S_Dis_IRQ_EN_o,
			
			DMA_CNT_o,
            DMA_Start_o,           
            DMA_Done_IRQ_o,                  // AHB-To_Fabric Bridge I/F
            DMA_Done_IRQ_EN_o               
            );


//------Port Parameters----------------
//
parameter                ADDRWIDTH                   =   9           ;
parameter                DATAWIDTH                   =  32           ;

parameter                I2S_EN_REG_ADR          	 =  9'h0         ;
parameter                RXFIFO_RST_REG_ADR          =  9'h1         ;
parameter                INTR_STS_REG_ADR          	 =  9'h2         ;
parameter                INTR_EN_REG_ADR          	 =  9'h3         ;
parameter                LFIFO_STS_REG_ADR           =  9'h4         ;
parameter                RFIFO_STS_REG_ADR           =  9'h5         ;
parameter                LFIFO_DAT_REG_ADR           =  9'h6         ;
parameter                RFIFO_DAT_REG_ADR           =  9'h7         ;
parameter                DMA_EN_REG_ADR              =  9'h8         ;
parameter                DMA_STS_REG_ADR             =  9'h9         ;
parameter                DMA_CNT_REG_ADR             =  9'hA         ;
parameter                DMA_DAT_REG_ADR             =  9'hB         ;

parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric

input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input            [2:0]	 WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [31:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric


output                   I2S_S_EN_o      ;
output                   Rx_FIFO_Flush_o ;

input            [15:0]  L_RXFIFO_DAT_i  ;
output                   L_RXFIFO_Pop_o  ;

input            [15:0]  R_RXFIFO_DAT_i  ;
output                   R_RXFIFO_Pop_o  ;

output                   STEREO_EN_o     ;
output                   LR_CHNL_SEL_o   ;
input            [31:0]  LR_RXFIFO_DAT_i ;
input                    LR_Rx_FIFO_Full_i;  
input                    LR_Rx_FIFO_Empty_i;  
input            [8:0]   LR_Rx_FIFO_Level_i;


output                   LR_RXFIFO_Pop_o ;
            
input            [8:0]   L_Rx_FIFO_Level_i;
input                    L_Rx_FIFO_Empty_i;
input                    L_Rx_FIFO_Full_i;            

input            [8:0]   R_Rx_FIFO_Level_i;
input                    R_Rx_FIFO_Empty_i;
input                    R_Rx_FIFO_Full_i; 	
				
output                   L_RX_DAT_IRQ_o    ;
output                   L_RX_DAT_IRQ_EN_o ;	

output                   R_RX_DAT_IRQ_o    ;
output                   R_RX_DAT_IRQ_EN_o ;
				
output					 DMA_Start_o;
output					 DMA_Done_IRQ_o;
output					 DMA_Done_IRQ_EN_o;

output             		 I2S_Dis_IRQ_o; 
output             		 I2S_Dis_IRQ_EN_o;

input	 				 DMA_Done_i;
input	 				 DMA_Active_i; 
input	 				 DMA_REQ_i;
input	 				 DMA_Busy_i;
input	 				 DMA_Clr_i; 

output            [8:0]  DMA_CNT_o; 

input             [8:0]  dma_cntr_i; 
input             [1:0]  dma_st_i;

input					 i2s_dis_i;
						 
// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [2:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire             [31:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_o       ; // Wishbone Client Acknowledge

reg						 DMA_EN;
reg						 DMA_Done_IRQ_o;
reg						 DMA_Done_IRQ_EN_o;

wire    				 DMA_Start_o;
wire					 DMA_Start; 
wire					 dma_start_mono; 
wire					 dma_start_str; 

wire	 				 DMA_Done_i;
wire	 				 DMA_Active_i; 
wire	 				 DMA_REQ_i;
wire	 				 DMA_Busy_i;
wire	 				 DMA_Clr_i;

reg                      I2S_S_EN_o      ; 
wire                     Rx_FIFO_Flush_o ;
reg                      Rx_FIFO_Flush   ;

wire             [15:0]  L_RXFIFO_DAT_i  ;
wire                     L_RXFIFO_Pop_o  ;

wire             [15:0]  R_RXFIFO_DAT_i  ;
wire                     R_RXFIFO_Pop_o  ;

wire                     LR_RXFIFO_Pop_o ;

reg                      LR_CHNL_SEL_o   ; 
reg                      stereo_en       ; 
wire                     STEREO_EN_o     ;

wire             [31:0]  LR_RXFIFO_DAT_i ;
wire             [31:0]  LR_RXFIFO_DAT   ;
wire                     LR_Rx_FIFO_Full_i;  
wire                     LR_Rx_FIFO_Empty_i; 
wire             [8:0]   LR_Rx_FIFO_Level_i;   

wire             [8:0]   LR_Rx_FIFO_Level;
wire             [8:0]   L_Rx_FIFO_Level;
wire             [8:0]   R_Rx_FIFO_Level;

           
wire             [8:0]   L_Rx_FIFO_Level_i; 
wire                     L_Rx_FIFO_Empty_i;
wire                     L_Rx_FIFO_Full_i;            

wire   	         [8:0]   R_Rx_FIFO_Level_i;
wire  	                 R_Rx_FIFO_Empty_i;
wire  	                 R_Rx_FIFO_Full_i; 	
				
wire                     L_RX_DAT_IRQ_o    ;
reg                      L_RX_DAT_IRQ_EN_o ;	

wire                     R_RX_DAT_IRQ_o    ;
reg                      R_RX_DAT_IRQ_EN_o ;

reg              		 I2S_Dis_IRQ_o;
reg              		 I2S_Dis_IRQ_EN_o;

reg 					 WBs_ACK_r;
wire                     pop_int;

wire			[31:0]	 DMA_Status;
reg             [8:0]    DMA_CNT_o;

wire            [8:0]  dma_cntr_i;
wire            [1:0]  dma_st_i;

wire     			   i2s_dis_i;

wire                     LR_Rx_FIFO_Full;
wire                     LR_Rx_FIFO_Empty;

wire                     L_Rx_FIFO_Full;
wire                     R_Rx_FIFO_Full;

wire                     L_Rx_FIFO_Empty;
wire                     R_Rx_FIFO_Empty;

    

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     I2S_EN_REG_Wr_Dcd ;
wire                     RXFIFO_RST_REG_Wr_Dcd ;
wire                     INTR_EN_REG_Wr_Dcd ; 
wire                     INTR_STS_REG_Wr_Dcd ; 
wire                     DMA_EN_REG_Wr_Dcd ; 
wire                     DMA_CNT_REG_Wr_Dcd ;

//------Logic Operations---------------
//
assign Rx_FIFO_Flush_o = Rx_FIFO_Flush | ~I2S_S_EN_o;

assign STEREO_EN_o = stereo_en;

assign dma_start_str = (L_Rx_FIFO_Level_i >= DMA_CNT_o && R_Rx_FIFO_Level_i >= DMA_CNT_o )? 1'b1 : 1'b0;
assign dma_start_mono = (LR_Rx_FIFO_Level_i >= DMA_CNT_o)? 1'b1 : 1'b0;
assign DMA_Start = (stereo_en)? dma_start_str: dma_start_mono; 
assign DMA_Start_o = DMA_Start & DMA_EN;

assign L_RX_DAT_IRQ_o = (L_Rx_FIFO_Empty_i)? 1'b0: 1'b1;
assign R_RX_DAT_IRQ_o = (R_Rx_FIFO_Empty_i)? 1'b0: 1'b1;

assign pop_int = WBs_ACK_o & ~WBs_ACK_r;

//assign L_RXFIFO_Pop_o = ( WBs_ADR_i == LFIFO_DAT_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;
//assign R_RXFIFO_Pop_o = ( WBs_ADR_i == RFIFO_DAT_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;
assign L_RXFIFO_Pop_o =  1'b0;
assign R_RXFIFO_Pop_o =  1'b0;
assign LR_RXFIFO_Pop_o = ( WBs_ADR_i == DMA_DAT_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;   

// Determine each register decode
//
assign I2S_EN_REG_Wr_Dcd = ( WBs_ADR_i == I2S_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign RXFIFO_RST_REG_Wr_Dcd = ( WBs_ADR_i == RXFIFO_RST_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign INTR_EN_REG_Wr_Dcd = ( WBs_ADR_i == INTR_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ; 
assign INTR_STS_REG_Wr_Dcd = ( WBs_ADR_i == INTR_STS_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign DMA_EN_REG_Wr_Dcd = ( WBs_ADR_i == DMA_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign DMA_CNT_REG_Wr_Dcd = ( WBs_ADR_i == DMA_CNT_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
   
// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);

// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        I2S_S_EN_o          <= 1'b0;
		Rx_FIFO_Flush       <= 1'b0;
		DMA_EN	 		    <= 1'b0;
		I2S_Dis_IRQ_o       <= 1'b0;
		I2S_Dis_IRQ_EN_o    <= 1'b0;
		DMA_Done_IRQ_o	 	<= 1'b0;
		DMA_Done_IRQ_EN_o	<= 1'b0;
		L_RX_DAT_IRQ_EN_o  	<= 1'b0;
		R_RX_DAT_IRQ_EN_o  	<= 1'b0;
        WBs_ACK_o           <= 1'b0; 
		WBs_ACK_r           <= 1'b0;
		DMA_CNT_o           <= 9'h4;
		LR_CHNL_SEL_o       <= 1'b0;
		stereo_en           <= 1'b0;
    end  
    else
    begin
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            I2S_S_EN_o  <=  WBs_DAT_i[0];
		else if (i2s_dis_i)
		    I2S_S_EN_o  <=  1'b0;
			
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            stereo_en      <=  WBs_DAT_i[2]; 
			LR_CHNL_SEL_o  <=  WBs_DAT_i[3];
	    end
		
			
	    if ( RXFIFO_RST_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            Rx_FIFO_Flush  <=  WBs_DAT_i[0];

        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_EN  <=  WBs_DAT_i[0];
		else if (DMA_Clr_i)
			DMA_EN  <=  1'b0;
			
		if ( INTR_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		    I2S_Dis_IRQ_EN_o     <=  WBs_DAT_i[3];
		    R_RX_DAT_IRQ_EN_o    <=  WBs_DAT_i[2];
		    L_RX_DAT_IRQ_EN_o    <=  WBs_DAT_i[1];
            DMA_Done_IRQ_EN_o    <=  WBs_DAT_i[0];
		end
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA_Done_i)
        begin
            DMA_Done_IRQ_o   <=  DMA_Done_i ? 1'b1 : WBs_DAT_i[0];
        end
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || i2s_dis_i)
        begin
            I2S_Dis_IRQ_o   <=  i2s_dis_i ? 1'b1 : WBs_DAT_i[3];
        end
		
	    if ( DMA_CNT_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_CNT_o  <=  WBs_DAT_i[8:0];

        WBs_ACK_o               <=  WBs_ACK_o_nxt;
		WBs_ACK_r				<=  WBs_ACK_o;		
    end  
end

assign DMA_Status = {dma_st_i,5'h0,dma_cntr_i,DMA_Start_o,11'h0,DMA_REQ_i,DMA_Active_i,DMA_Done_IRQ_o,DMA_Busy_i};

assign LR_Rx_FIFO_Full = (stereo_en)? (L_Rx_FIFO_Full_i | R_Rx_FIFO_Full_i): LR_Rx_FIFO_Full_i;
assign LR_Rx_FIFO_Empty = (stereo_en)? (L_Rx_FIFO_Empty_i & R_Rx_FIFO_Empty_i): LR_Rx_FIFO_Empty_i;

assign L_Rx_FIFO_Full = (LR_CHNL_SEL_o & ~stereo_en)? 1'b0: LR_Rx_FIFO_Full;
assign L_Rx_FIFO_Empty = (LR_CHNL_SEL_o & ~stereo_en)? 1'b0: LR_Rx_FIFO_Empty;

assign R_Rx_FIFO_Full = (~LR_CHNL_SEL_o & ~stereo_en)? 1'b0: LR_Rx_FIFO_Full;
assign R_Rx_FIFO_Empty = (~LR_CHNL_SEL_o & ~stereo_en)? 1'b0: LR_Rx_FIFO_Empty; 

assign LR_Rx_FIFO_Level = (stereo_en)? L_Rx_FIFO_Level_i: LR_Rx_FIFO_Level_i; 

assign L_Rx_FIFO_Level = (LR_CHNL_SEL_o & ~stereo_en)? 9'h0: LR_Rx_FIFO_Level;
assign R_Rx_FIFO_Level = (~LR_CHNL_SEL_o & ~stereo_en)? 9'h0: LR_Rx_FIFO_Level; 

assign LR_RXFIFO_DAT = (stereo_en) ? ({ R_RXFIFO_DAT_i,L_RXFIFO_DAT_i}) : LR_RXFIFO_DAT_i;

 
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              or
		 I2S_S_EN_o             or
		 stereo_en              or
		 LR_CHNL_SEL_o          or
		 Rx_FIFO_Flush          or
		 L_RX_DAT_IRQ_o         or
		 R_RX_DAT_IRQ_o         or
		 DMA_Done_IRQ_o         or
		 R_RX_DAT_IRQ_EN_o      or
		 L_RX_DAT_IRQ_EN_o      or
		 DMA_Done_IRQ_EN_o      or
		 I2S_Dis_IRQ_o          or
		 I2S_Dis_IRQ_EN_o       or
		 L_Rx_FIFO_Full         or 
		 L_Rx_FIFO_Empty        or
		 L_Rx_FIFO_Level        or
		 R_Rx_FIFO_Full         or
		 R_Rx_FIFO_Empty        or
		 R_Rx_FIFO_Level        or
		 DMA_Status             or
		 DMA_EN                 or
		 DMA_CNT_o   			or 
		 LR_RXFIFO_DAT
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    I2S_EN_REG_ADR        : WBs_DAT_o <= { 28'h0,LR_CHNL_SEL_o,stereo_en, 1'b0,I2S_S_EN_o}; 
	RXFIFO_RST_REG_ADR    : WBs_DAT_o <= { 31'h0, Rx_FIFO_Flush};
	INTR_STS_REG_ADR      : WBs_DAT_o <= { 28'h0, I2S_Dis_IRQ_o, R_RX_DAT_IRQ_o,L_RX_DAT_IRQ_o,DMA_Done_IRQ_o};
	INTR_EN_REG_ADR       : WBs_DAT_o <= { 28'h0, I2S_Dis_IRQ_EN_o,R_RX_DAT_IRQ_EN_o, L_RX_DAT_IRQ_EN_o, DMA_Done_IRQ_EN_o};
	LFIFO_STS_REG_ADR     : WBs_DAT_o <= { 16'h0, L_Rx_FIFO_Full,L_Rx_FIFO_Empty,5'h0, L_Rx_FIFO_Level};
	RFIFO_STS_REG_ADR     : WBs_DAT_o <= { 16'h0, R_Rx_FIFO_Full,R_Rx_FIFO_Empty,5'h0, R_Rx_FIFO_Level};
	LFIFO_DAT_REG_ADR     : WBs_DAT_o <=  32'h0;
	RFIFO_DAT_REG_ADR     : WBs_DAT_o <=  32'h0;
    DMA_EN_REG_ADR   	  : WBs_DAT_o <= { 31'h0, DMA_EN };
	DMA_STS_REG_ADR  	  : WBs_DAT_o <= { DMA_Status};
	DMA_CNT_REG_ADR  	  : WBs_DAT_o <= { 23'h0, DMA_CNT_o};
	DMA_DAT_REG_ADR    	  : WBs_DAT_o <= { LR_RXFIFO_DAT}; 
	default               : WBs_DAT_o <=          32'h0 ;
	endcase
end
 
endmodule
