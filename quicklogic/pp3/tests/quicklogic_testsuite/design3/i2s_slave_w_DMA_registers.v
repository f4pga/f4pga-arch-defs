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
// 2018/01/29      1.1        Anand Wadke            Updated for I2S Decimator.
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

//`define AEC_1_0
`define ACSLIP_USE_I2S_BITCLK
module i2s_slave_w_DMA_registers ( 
                         
            WBs_CLK_i,          
            WBs_RST_i,   

			sys_ref_clk_i,		
            
            WBs_ADR_i,          
            WBs_CYC_i,  
            WBs_CYC_I2S_PREDECI_RAM_i,
            WBs_CYC_FIR_COEFF_RAM_i, 
 			
            WBs_BYTE_STB_i,     
            WBs_WE_i,           
            WBs_STB_i,          
            WBs_DAT_i,          
            WBs_DAT_o, 
            WBs_COEF_RAM_DAT_o,			
            WBs_ACK_o,   

			i2s_dis_i,
            I2S_S_EN_o,  
            ACSLIP_EN_o,  

            ACSLIP_Reg_Rst_o,	

            ACLSIP_Reg_i,	

`ifdef AEC_1_0
		    cnt_mic_dat_i ,
            cnt_i2s_dat_i ,
`endif			

            wb_FIR_L_PreDeci_RAM_aDDR_o,			
            wb_FIR_L_PreDeci_RAM_Wen_o,
			wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_o,
			
			wb_Coeff_RAM_aDDR_o,
			wb_Coeff_RAM_Wen_o,
			wb_Coeff_RAM_Data_o,
			wb_Coeff_RAM_Data_i,          //
			wb_Coeff_RAM_rd_access_ctrl_o,       //
			
            FIR_DECI_Done_i,
			FIR_ena_o, 
		
            DeciData_Rx_FIFO_Flush_o,  //DeciData_Rx_FIFO_Flush_o_ 			

            DeciData_Rx_FIFO_Pop_o,  			
			DeciData_Rx_FIFO_DAT_i,   
			DeciData_Rx_FIFO_Full_i, 
			DeciData_Rx_FIFO_Empty_i,		
			DeciData_Rx_FIFO_Level_i,
			DeciData_Rx_FIFO_Empty_flag_i,
			
 	
				
			Deci_Done_IRQ_EN_o,  
            Deci_Done_IRQ_o,			
			DeciData_Rx_DAT_AVL_IRQ_EN_o,   
			DeciData_Rx_FIFO_DAT_IRQ_o,//L_RX_DAT_IRQ_o_
			ACSLIP_timer_IRQ_EN_o,
			ACSLIP_timer_IRQ_o,
			

			//R_RX_DAT_IRQ_o,       	
			//R_RX_DAT_IRQ_EN_o,
				
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

parameter                I2S_EN_REG_ADR          	 =  10'h0         ;//9'h0         ;
parameter                ACSLIP_REG_RST_ADR          =  10'h1         ;//9'h1         ; //parameter                RXFIFO_RST_REG_ADR          =  9'h1         ;
parameter                INTR_STS_REG_ADR          	 =  10'h2         ;//9'h2         ;
parameter                INTR_EN_REG_ADR          	 =  10'h3         ;//9'h3         ;
parameter                DECI_FIFO_STS_REG_ADR       =  10'h4         ;//9'h4         ;//parameter                LFIFO_STS_REG_ADR           =  9'h4         ;
parameter                DECI_FIFO_DATA_REG_ADR		 =  10'h5         ;//9'h5         ;//parameter                RFIFO_STS_REG_ADR           =  9'h5         ;
parameter                ACSLIP_REG_ADR              =  10'h6         ;//9'h6         ;//parameter                LFIFO_DAT_REG_ADR           =  9'h6         ;
parameter                DECI_FIFO_RST_ADR           =  10'h7         ;//9'h7         ;//parameter                RFIFO_DAT_REG_ADR           =  9'h7         ;
parameter                DMA_EN_REG_ADR              =  10'h8         ;//9'h8         ;
parameter                DMA_STS_REG_ADR             =  10'h9         ;//9'h9         ;
parameter                DMA_CNT_REG_ADR             =  10'hA         ;//9'hA         ;
parameter                ACSLIP_TIMER_REG_ADR        =  10'hB         ;//9'hB         ;//parameter                DMA_DAT_REG_ADR             =  9'hB         ;
parameter                FIR_DECI_CNTRL_REG_ADR      =  10'hC         ;//9'hC         ;
parameter                MIC_DAT_CNT_ADR             =  10'hD         ;//9'hD         ;
parameter                I2S_DAT_CNT_ADR             =  10'hE         ;//9'hE         ;
parameter                RESERVED_2                  =  10'hD         ;//9'hD         ;
//parameter                FIR_PREDECI_RAM_STRT_ADDR1  =  10'h100       ;//9'h100       ;
//parameter                FIR_PREDECI_RAM_STRT_ADDR2  =  10'h200       ;//9'h200       ;
//parameter                FIR_COEFF_RAM_ADDR1         =  10'h300       ;//9'h300       ;
parameter                FIR_PREDECI_RAM_STRT_ADDR1  =  10'h200       ;//9'h100       ;
parameter                FIR_PREDECI_RAM_STRT_ADDR2  =  10'h000       ;//9'h200       ;//unused
parameter                FIR_COEFF_RAM_ADDR1         =  10'h200       ;//9'h300       ;


parameter                RESERVED_3                  =  10'hB         ;//9'hB         ;

parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area

parameter                ACSLIP_REG_WIDTH            = 32;//Default 9


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric
input                    sys_ref_clk_i       ; 

//input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input   [ADDRWIDTH:0]    WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input                    WBs_CYC_I2S_PREDECI_RAM_i   ; 
input                    WBs_CYC_FIR_COEFF_RAM_i      ;

input            [2:0]	 WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [31:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  WBs_COEF_RAM_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

input					 i2s_dis_i;
output                   I2S_S_EN_o      ;
output                   ACSLIP_EN_o      ;
output                   ACSLIP_Reg_Rst_o      ;
//input        [9:0]       ACLSIP_Reg_i      ;
input        [ACSLIP_REG_WIDTH-1:0]       ACLSIP_Reg_i      ;

`ifdef AEC_1_0
input              [31:0]  cnt_mic_dat_i ;
input              [31:0]  cnt_i2s_dat_i ;
`endif

output                   DeciData_Rx_FIFO_Flush_o ;


input            [15:0]  DeciData_Rx_FIFO_DAT_i ;
input                    DeciData_Rx_FIFO_Full_i;  
input                    DeciData_Rx_FIFO_Empty_i;  
input            [8:0]   DeciData_Rx_FIFO_Level_i;
input            [3:0]   DeciData_Rx_FIFO_Empty_flag_i;


output                   DeciData_Rx_FIFO_Pop_o ;

output 			  [8:0]  wb_FIR_L_PreDeci_RAM_aDDR_o;		
output 					 wb_FIR_L_PreDeci_RAM_Wen_o;
output  				 wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_o;

output 			  [8:0]  wb_Coeff_RAM_aDDR_o;		
output 					 wb_Coeff_RAM_Wen_o;
output            [15:0] wb_Coeff_RAM_Data_o;

input [15:0]  			 wb_Coeff_RAM_Data_i;
output        			 wb_Coeff_RAM_rd_access_ctrl_o;



//FIR decimation
input 					 FIR_DECI_Done_i;
output 					 FIR_ena_o;

            
//input            [8:0]   L_Rx_FIFO_Level_i;
//input                    L_Rx_FIFO_Empty_i;
//input                    L_Rx_FIFO_Full_i;            

//input            [8:0]   R_Rx_FIFO_Level_i;
//input                    R_Rx_FIFO_Empty_i;
//input                    R_Rx_FIFO_Full_i; 	
				
output                   DeciData_Rx_FIFO_DAT_IRQ_o    ;
output                   DeciData_Rx_DAT_AVL_IRQ_EN_o ;	
output                   Deci_Done_IRQ_EN_o ;	
output                   Deci_Done_IRQ_o ;	
output                   ACSLIP_timer_IRQ_EN_o;
output                   ACSLIP_timer_IRQ_o;

//output                   R_RX_DAT_IRQ_o    ;
//output                   R_RX_DAT_IRQ_EN_o ;
				
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


						 
// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
//wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire    [ADDRWIDTH:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [2:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire             [31:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_sig       ; // Wishbone Client Acknowledge

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
reg                      ACSLIP_EN_o      ; 
wire                     DeciData_Rx_FIFO_Flush_o ;
reg                      Deci_Rx_FIFO_Flush   ;



wire                     DeciData_Rx_FIFO_Pop_o ;

reg                      LR_CHNL_SEL_o   ; 
reg                      stereo_en       ; 
wire                     STEREO_EN_o     ;

wire             [15:0]  DeciData_Rx_FIFO_DAT_i ;
wire                     DeciData_Rx_FIFO_Full_i;  
wire                     DeciData_Rx_FIFO_Empty_i; 
wire             [8:0]   DeciData_Rx_FIFO_Level_i;  


				
wire                     DeciData_Rx_FIFO_DAT_IRQ_o    ;
reg                      DeciData_Rx_DAT_AVL_IRQ_EN_o ;	

wire 					 Deci_Done_IRQ_o;
reg                      Deci_Done_IRQ_EN_o ;



reg              		 I2S_Dis_IRQ_o;
reg              		 I2S_Dis_IRQ_EN_o;

reg                      ACSLIP_timer_IRQ_EN_o;
reg                      ACSLIP_timer_IRQ_o;

reg 					 WBs_ACK_sig_r;
//wire                     pop_int;

wire			[31:0]	 DMA_Status;
reg             [8:0]    DMA_CNT_o;

wire            [8:0]  dma_cntr_i;
wire            [1:0]  dma_st_i;

wire     			   i2s_dis_i;

wire                     Deci_Rx_FIFO_Full;
wire                     Deci_Rx_FIFO_Empty;

//wire                     Deci_Rx_FIFO_Full;

reg 					 wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL;

reg 					acslip_reg_rst;

reg                     deci_done_irq;

reg 					FIR_deci_en;     
reg 					FIR_deci_int_en ;

reg                      wb_coeff_ram_rd_access_ctrl_sig;

//reg        [9:0]       ACLSIP_Reg_r1      ;
reg        [ACSLIP_REG_WIDTH-1:0]       ACLSIP_Reg_r1      ;
reg        [31:0]      cnt_mic_dat_r ;      




//wire             [15:0]  L_RXFIFO_DAT_i  ;
//wire                     L_RXFIFO_Pop_o  ;
//wire             [15:0]  R_RXFIFO_DAT_i  ;
//wire                     R_RXFIFO_Pop_o  ; 
//wire             [8:0]   LR_Rx_FIFO_Level;
//wire             [8:0]   L_Rx_FIFO_Level;
//wire             [8:0]   R_Rx_FIFO_Level;
//wire             [8:0]   L_Rx_FIFO_Level_i; 
//wire                     L_Rx_FIFO_Empty_i;
//wire                     L_Rx_FIFO_Full_i;            
//wire   	         [8:0]   R_Rx_FIFO_Level_i;
//wire  	                 R_Rx_FIFO_Empty_i;
//wire  	                 R_Rx_FIFO_Full_i; 	
//wire                     R_RX_DAT_IRQ_o    ;
//reg                      R_RX_DAT_IRQ_EN_o ;
//wire                     R_Rx_FIFO_Full;
//wire                     L_Rx_FIFO_Empty;
//wire                     R_Rx_FIFO_Empty;

//------Internal Signals---------------
//
wire                     I2S_EN_REG_Wr_Dcd ;
wire                     ACSLIP_RST_REG_Wr_Dcd ;
//wire                     RXFIFO_RST_REG_Wr_Dcd ;
wire                     INTR_EN_REG_Wr_Dcd ; 
wire                     DECI_FIFO_DATA_Wr_Dcd ; 
wire                     DECI_FIFO_RST_Wr_Dcd ; 
wire                     INTR_STS_REG_Wr_Dcd ; 
wire                     DMA_EN_REG_Wr_Dcd ; 
wire                     ACSLIP_TIMER_REG_Wr_Dcd ; 
wire                     FIR_DECI_CONTROL_REG_Wr_Dcd ;
wire                     FIR_PREDECI_RAM_ADDR_REG_Wr_Dcd ;
wire                     FIR_COEFF_RAM_ADDR_REG_Wr_Dcd ;
wire 					 deci_fifo_pop;

reg [15:0]  			Fifo_dat_r_up; 
reg [15:0]  			Fifo_dat_r_lo; 

//reg [7:0]               acslip_timer_reg;
reg [15:0]              acslip_timer_reg;
//reg [7:0]               acslip_timer_cntr;
reg [15:0]               acslip_timer_cntr;
reg 					acslip_timer_int;

reg acslip_timer_int_wb_r1;
reg acslip_timer_int_wb_r2;
reg acslip_timer_int_wb_r3;

wire acslip_timer_int_wbsync_pulse;

//------Logic Operations---------------
//
assign WBs_ACK_o = ( WBs_ADR_i == DECI_FIFO_DATA_REG_ADR && WBs_CYC_i == 1'b1) ? WBs_ACK_sig_r : WBs_ACK_sig;
//assign WBs_ACK_o = ( WBs_ADR_i == DECI_FIFO_DATA_REG_ADR && WBs_CYC_i == 1'b1 || (( WBs_ADR_i[9] == FIR_COEFF_RAM_ADDR1[9] ) & WBs_CYC_FIR_COEFF_RAM_i)) ? WBs_ACK_sig_r : WBs_ACK_sig;


//assign wb_FIR_L_PreDeci_RAM_aDDR_o[8]   = (WBs_ADR_i[ADDRWIDTH:ADDRWIDTH-1] == 2'b01) ? 1'b0 : 1'b1;	
assign wb_FIR_L_PreDeci_RAM_aDDR_o[8:0] = WBs_ADR_i[ADDRWIDTH-1 : 0];
assign wb_FIR_L_PreDeci_RAM_Wen_o       = FIR_PREDECI_RAM_ADDR_REG_Wr_Dcd;

//assign wb_Coeff_RAM_aDDR_o[8]           = 1'b0;	
//assign wb_Coeff_RAM_aDDR_o[7:0]         = WBs_ADR_i[ADDRWIDTH-2 : 0];
assign wb_Coeff_RAM_aDDR_o[8:0]         = WBs_ADR_i[ADDRWIDTH-1 : 0];
assign wb_Coeff_RAM_Wen_o       		= FIR_COEFF_RAM_ADDR_REG_Wr_Dcd;
assign wb_Coeff_RAM_Data_o              = WBs_DAT_i[15:0];

assign WBs_COEF_RAM_DAT_o               = wb_Coeff_RAM_Data_i;


//assign DeciData_Rx_FIFO_Flush_o = Deci_Rx_FIFO_Flush | ~I2S_S_EN_o;
assign DeciData_Rx_FIFO_Flush_o = Deci_Rx_FIFO_Flush;

assign Deci_Done_IRQ_o = deci_done_irq;

assign ACSLIP_Reg_Rst_o = acslip_reg_rst;

assign DMA_Start 			= (DeciData_Rx_FIFO_Level_i >= DMA_CNT_o )? 1'b1 : 1'b0; 
assign DMA_Start_o 			= DMA_Start & DMA_EN;

//assign DeciData_Rx_FIFO_DAT_IRQ_o = (DeciData_Rx_FIFO_Empty_i)? 1'b0: 1'b1;
assign DeciData_Rx_FIFO_DAT_IRQ_o = (DMA_Start)? 1'b1: 1'b0;
//assign DeciData_Rx_FIFO_DAT_IRQ_o = (|(DeciData_Rx_FIFO_Empty_flag_i[3:1]))? 1'b0: 1'b1;


//assign pop_int = WBs_ACK_sig & ~WBs_ACK_sig_r;
//assign DeciData_Rx_FIFO_Pop_o = ( WBs_ADR_i == DECI_FIFO_DATA_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;  
assign DeciData_Rx_FIFO_Pop_o 	= deci_fifo_pop;  
//assign deci_fifo_pop 			= ( WBs_ADR_i == DECI_FIFO_DATA_REG_ADR && WBs_CYC_i == 1'b1 && WBs_ACK_sig == 1'b0 && WBs_ACK_sig_r == 1'b0 && DeciData_Rx_FIFO_Empty_i == 1'b0) ? 1'b1 : 1'b0;
assign deci_fifo_pop 			= ( WBs_ADR_i == DECI_FIFO_DATA_REG_ADR && WBs_CYC_i == 1'b1  && WBs_ACK_sig_r == 1'b0 && DeciData_Rx_FIFO_Empty_i == 1'b0) ? 1'b1 : 1'b0;

assign wb_Coeff_RAM_rd_access_ctrl_o = wb_coeff_ram_rd_access_ctrl_sig;

always @( negedge WBs_CLK_i or posedge WBs_RST_i)
begin
   if (WBs_RST_i)
    begin
		Fifo_dat_r_up <= 16'h0;	
		Fifo_dat_r_lo <= 16'h0;	
	end
	else
	begin
	    if (deci_fifo_pop)
		begin
			Fifo_dat_r_up <= DeciData_Rx_FIFO_DAT_i;	
			Fifo_dat_r_lo <= Fifo_dat_r_up;	
		end	
	end
end	
	

 

// Determine each register decode
//
assign I2S_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == I2S_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign ACSLIP_RST_REG_Wr_Dcd    = ( WBs_ADR_i == ACSLIP_REG_RST_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
//assign RXFIFO_RST_REG_Wr_Dcd 	= ( WBs_ADR_i == RXFIFO_RST_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign INTR_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == INTR_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign INTR_STS_REG_Wr_Dcd 		= ( WBs_ADR_i == INTR_STS_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DECI_FIFO_RST_Wr_Dcd     = ( WBs_ADR_i == DECI_FIFO_RST_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == DMA_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign ACSLIP_TIMER_REG_Wr_Dcd  = ( WBs_ADR_i == ACSLIP_TIMER_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_CNT_REG_Wr_Dcd 		= ( WBs_ADR_i == DMA_CNT_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign FIR_DECI_CONTROL_REG_Wr_Dcd 		    = ( WBs_ADR_i == FIR_DECI_CNTRL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;

//RAM Write decodes
//assign FIR_PREDECI_RAM_ADDR_REG_Wr_Dcd 		= ( (WBs_ADR_i[ADDRWIDTH:ADDRWIDTH-1] == FIR_PREDECI_RAM_STRT_ADDR1[9:8]) || (WBs_ADR_i[ADDRWIDTH:ADDRWIDTH-1] == FIR_PREDECI_RAM_STRT_ADDR2[9:8])) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
//assign FIR_COEFF_RAM_ADDR_REG_Wr_Dcd 		= ( (WBs_ADR_i[ADDRWIDTH:ADDRWIDTH-1] == FIR_COEFF_RAM_ADDR1[9:8]) ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
 

assign FIR_PREDECI_RAM_ADDR_REG_Wr_Dcd 		= ( WBs_ADR_i[9] == FIR_PREDECI_RAM_STRT_ADDR1[9] ) & WBs_CYC_I2S_PREDECI_RAM_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign FIR_COEFF_RAM_ADDR_REG_Wr_Dcd 		= ( WBs_ADR_i[9] == FIR_COEFF_RAM_ADDR1[9] ) & WBs_CYC_FIR_COEFF_RAM_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
   
   
// Define the Acknowledge back to the host for registers
//
//assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_sig);
//assign WBs_ACK_o_nxt          =   (WBs_CYC_i | WBs_CYC_FIR_COEFF_RAM_i | WBs_CYC_I2S_PREDECI_RAM_i)  & WBs_STB_i & (~WBs_ACK_sig);
assign WBs_ACK_o_nxt          =   (WBs_CYC_i | WBs_CYC_FIR_COEFF_RAM_i | WBs_CYC_I2S_PREDECI_RAM_i)  & WBs_STB_i & (~WBs_ACK_sig & ~WBs_ACK_sig_r);

assign wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_o = wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL;

// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        I2S_S_EN_o          				<= 1'b0;
        ACSLIP_EN_o          				<= 1'b0;
		wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL 	<= 1'b0; 
		wb_coeff_ram_rd_access_ctrl_sig 	<= 1'b0; 
		acslip_reg_rst                  	<= 1'b1;
		//acslip_timer_reg                  	<= 8'h0F;
		acslip_timer_reg                  	<= 16'h1DF;
		Deci_Rx_FIFO_Flush  				<= 1'b0;
		DMA_EN	 		    				<= 1'b0;
		ACSLIP_timer_IRQ_o       	        <= 1'b0;
		ACSLIP_timer_IRQ_EN_o       	    <= 1'b0;
		I2S_Dis_IRQ_o       				<= 1'b0;
		I2S_Dis_IRQ_EN_o    				<= 1'b0;
		DMA_Done_IRQ_o	 					<= 1'b0;
		DMA_Done_IRQ_EN_o					<= 1'b0;
		deci_done_irq	 					<= 1'b0;
		Deci_Done_IRQ_EN_o                  <= 1'b0;		
		DeciData_Rx_DAT_AVL_IRQ_EN_o  		<= 1'b0;

        WBs_ACK_sig           				<= 1'b0; 
		WBs_ACK_sig_r           		    <= 1'b0;
		DMA_CNT_o           				<= 9'h4;
		
		FIR_deci_en                         <= 1'b0;
		FIR_deci_int_en                     <= 1'b0;
		
		cnt_mic_dat_r                      <= 0;

		//R_RX_DAT_IRQ_EN_o  	<= 1'b0;		
		//LR_CHNL_SEL_o       <= 1'b0;
		//stereo_en           <= 1'b0;
    end  
    else
    begin
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin
            I2S_S_EN_o  <=  WBs_DAT_i[0];
			ACSLIP_EN_o <=  WBs_DAT_i[2];
		end	
		else if (i2s_dis_i)
		    I2S_S_EN_o  <=  1'b0;
			
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		     wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL <= WBs_DAT_i[1];
		     wb_coeff_ram_rd_access_ctrl_sig    <= WBs_DAT_i[3];
            //stereo_en      <=  WBs_DAT_i[2]; 
			//LR_CHNL_SEL_o  <=  WBs_DAT_i[3];
	    end
		
	    if ( ACSLIP_RST_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		     acslip_reg_rst <= WBs_DAT_i[0];
	    end
/*         else
        begin
			 acslip_reg_rst <= 1'b0;
        end */		
		
			
	    if ( DECI_FIFO_RST_Wr_Dcd && WBs_BYTE_STB_i[0])
            Deci_Rx_FIFO_Flush  <=  WBs_DAT_i[0];
		else
			Deci_Rx_FIFO_Flush  <= 1'b0;	
			

        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_EN  <=  WBs_DAT_i[0];
		else if (DMA_Clr_i)
			DMA_EN  <=  1'b0;
			
        if ( FIR_DECI_CONTROL_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            FIR_deci_int_en  <=  WBs_DAT_i[1];
            FIR_deci_en      <=  WBs_DAT_i[0];
		end	
		
        if ( ACSLIP_TIMER_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            //acslip_timer_reg  <=  WBs_DAT_i[7:0];
            acslip_timer_reg  <=  WBs_DAT_i[15:0];
		end	
        
		
			
		if ( INTR_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		    ACSLIP_timer_IRQ_EN_o           <=  WBs_DAT_i[4];
		    I2S_Dis_IRQ_EN_o     		    <=  WBs_DAT_i[3];
		    DeciData_Rx_DAT_AVL_IRQ_EN_o    <=  WBs_DAT_i[2];
		    Deci_Done_IRQ_EN_o              <=  WBs_DAT_i[1];
            DMA_Done_IRQ_EN_o    		    <=  WBs_DAT_i[0];
		end
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA_Done_i)
        begin
            DMA_Done_IRQ_o   <=  DMA_Done_i ? 1'b1 : WBs_DAT_i[0];
        end
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || i2s_dis_i)
        begin
            I2S_Dis_IRQ_o   <=  i2s_dis_i ? 1'b1 : WBs_DAT_i[3];
        end
		
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || FIR_DECI_Done_i )
        begin
            deci_done_irq   <=  FIR_DECI_Done_i ? 1'b1 : WBs_DAT_i[2];
        end		
		
		//if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || acslip_timer_int)
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || acslip_timer_int_wbsync_pulse)
        begin
            ACSLIP_timer_IRQ_o   <=  acslip_timer_int_wbsync_pulse ? 1'b1 : WBs_DAT_i[4];
        end			
		
		
	    if ( DMA_CNT_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_CNT_o  <=  WBs_DAT_i[8:0];
			
        //if ( WBs_ADR_i == MIC_DAT_CNT_ADR && WBs_ACK_o == 1'b1)
`ifdef AEC_1_0		
        if ( WBs_ADR_i == I2S_DAT_CNT_ADR && WBs_ACK_o == 1'b1)
            cnt_mic_dat_r  <=  cnt_mic_dat_i;				
`endif			
			

        WBs_ACK_sig               <=  WBs_ACK_o_nxt;
		WBs_ACK_sig_r				<=  WBs_ACK_sig;		
    end  
end

assign DMA_Status = {dma_st_i,5'h0,dma_cntr_i,DMA_Start_o,11'h0,DMA_REQ_i,DMA_Active_i,DMA_Done_IRQ_o,DMA_Busy_i};

assign Deci_Rx_FIFO_Full  =  DeciData_Rx_FIFO_Full_i;
assign Deci_Rx_FIFO_Empty =  DeciData_Rx_FIFO_Empty_i;

assign FIR_ena_o = FIR_deci_en;

//assign LR_RXFIFO_DAT = (stereo_en) ? ({ R_RXFIFO_DAT_i,L_RXFIFO_DAT_i}) : DeciData_Rx_FIFO_DAT_i;

 
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              		or
		 I2S_S_EN_o             		or
		 ACSLIP_EN_o             		or
		 wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL       		or
		 wb_coeff_ram_rd_access_ctrl_sig       		or
		 ACLSIP_Reg_r1       		     or

		 acslip_reg_rst          		or
		 DeciData_Rx_FIFO_DAT_IRQ_o     or
		 I2S_Dis_IRQ_o          		or

		 DMA_Done_IRQ_o         		or

		 DeciData_Rx_DAT_AVL_IRQ_EN_o   or
		 Deci_Done_IRQ_EN_o      		or
		 DMA_Done_IRQ_EN_o      		or
		 I2S_Dis_IRQ_EN_o       		or
		 ACSLIP_timer_IRQ_EN_o       	or
		 
		 
		 Deci_Rx_FIFO_Full         		or 
		 Deci_Rx_FIFO_Empty        		or 
		 Fifo_dat_r_up    				or 
		 Fifo_dat_r_lo    				or 
		 Deci_Rx_FIFO_Flush        		or	

		 DMA_Status             		or
		 DMA_EN                 		or
		 DMA_CNT_o   					or 
		 acslip_timer_reg   		    or 
		 FIR_deci_en   	        		or 
		 FIR_deci_int_en   	     
		 //stereo_en              or
		 //R_RX_DAT_IRQ_o         or		 
		 //R_RX_DAT_IRQ_EN_o      or		 
		 //LR_CHNL_SEL_o          or		 
		 //L_Rx_FIFO_Empty        or
		 //L_Rx_FIFO_Level        or
		 //R_Rx_FIFO_Full         or
		 //R_Rx_FIFO_Empty        or
		 //R_Rx_FIFO_Level        or		 
		 //LR_RXFIFO_DAT
 )
 begin
    //case(WBs_ADR_i[ADDRWIDTH-1:0])
    case(WBs_ADR_i[ADDRWIDTH:0])
    I2S_EN_REG_ADR        : WBs_DAT_o <= { 28'h0,wb_coeff_ram_rd_access_ctrl_sig,ACSLIP_EN_o, wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL,I2S_S_EN_o}; 
	ACSLIP_REG_RST_ADR    : WBs_DAT_o <= { 31'h0, acslip_reg_rst};
	INTR_STS_REG_ADR      : WBs_DAT_o <= { 27'h0, ACSLIP_timer_IRQ_o, I2S_Dis_IRQ_o, 1'b0,DeciData_Rx_FIFO_DAT_IRQ_o,DMA_Done_IRQ_o};//INTR_STS_REG_ADR      : WBs_DAT_o <= { 28'h0, I2S_Dis_IRQ_o, R_RX_DAT_IRQ_o,DeciData_Rx_FIFO_DAT_IRQ_o,DMA_Done_IRQ_o};
	INTR_EN_REG_ADR       : WBs_DAT_o <= { 27'h0, ACSLIP_timer_IRQ_EN_o,I2S_Dis_IRQ_EN_o,DeciData_Rx_DAT_AVL_IRQ_EN_o, Deci_Done_IRQ_EN_o, DMA_Done_IRQ_EN_o};//{ 28'h0, I2S_Dis_IRQ_EN_o,R_RX_DAT_IRQ_EN_o, DeciData_Rx_DAT_AVL_IRQ_EN_o, DMA_Done_IRQ_EN_o};
	DECI_FIFO_STS_REG_ADR : WBs_DAT_o <= { 16'h0, Deci_Rx_FIFO_Full,Deci_Rx_FIFO_Empty,7'h0, DeciData_Rx_FIFO_Level_i};  
	DECI_FIFO_DATA_REG_ADR : WBs_DAT_o <= { Fifo_dat_r_up,Fifo_dat_r_lo};  
	//ACSLIP_REG_ADR        : WBs_DAT_o <= { 16'h0,6'h0, ACLSIP_Reg_i};
	ACSLIP_REG_ADR        : WBs_DAT_o <=  ACLSIP_Reg_r1;
	DECI_FIFO_RST_ADR     : WBs_DAT_o <= { 31'h0, Deci_Rx_FIFO_Flush};
    DMA_EN_REG_ADR   	  : WBs_DAT_o <= { 31'h0, DMA_EN };
	DMA_STS_REG_ADR  	  : WBs_DAT_o <= { DMA_Status};
	DMA_CNT_REG_ADR  	  : WBs_DAT_o <= { 23'h0, DMA_CNT_o};
	ACSLIP_TIMER_REG_ADR  : WBs_DAT_o <= { 16'h0, acslip_timer_reg};
	FIR_DECI_CNTRL_REG_ADR : WBs_DAT_o <= { 30'h0, FIR_deci_int_en, FIR_deci_en};
	MIC_DAT_CNT_ADR 	  : WBs_DAT_o <= cnt_mic_dat_r;
`ifdef AEC_1_0	
	I2S_DAT_CNT_ADR 	  : WBs_DAT_o <= cnt_i2s_dat_i;
`endif	
	
	
	default               : WBs_DAT_o <=          32'h0 ;
	endcase
end

assign acslip_rst = WBs_RST_i | acslip_reg_rst ;

//ACSLIP interrupt generation
always @( posedge sys_ref_clk_i or posedge acslip_rst)
begin
    if (acslip_rst)
    begin
		acslip_timer_cntr <= 0;
		acslip_timer_int  <= 1'b0;		
	end
	else
	begin
	    if (acslip_timer_cntr == acslip_timer_reg)
		begin
		   acslip_timer_int  <= 1'b1;
		   acslip_timer_cntr <= 0;
		end
		else
		begin
		   acslip_timer_int  <= 1'b0;
		   acslip_timer_cntr <= acslip_timer_cntr+1;
		end
	end
end	

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
	if (WBs_RST_i)
    begin
		ACLSIP_Reg_r1 <= 0;
	end
	else
	begin
	   if (acslip_timer_int_wbsync_pulse)
	   begin
	      ACLSIP_Reg_r1 <= ACLSIP_Reg_i;
	
       end
    end
end

assign acslip_timer_int_wbsync_pulse = acslip_timer_int_wb_r2 & ~acslip_timer_int_wb_r3;
	 
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
         acslip_timer_int_wb_r1 <= 0; 
         acslip_timer_int_wb_r2 <= 0; 
         acslip_timer_int_wb_r3 <= 0; 
    end
	else
	begin
         acslip_timer_int_wb_r1 <= acslip_timer_int; 
         acslip_timer_int_wb_r2 <= acslip_timer_int_wb_r1;
         acslip_timer_int_wb_r3 <= acslip_timer_int_wb_r2;

    end
end	
	 
 
endmodule
//wire             [31:0]  LR_RXFIFO_DAT   ; 
//assign R_RX_DAT_IRQ_o            = (R_Rx_FIFO_Empty_i)? 1'b0: 1'b1;
//assign L_RXFIFO_Pop_o = ( WBs_ADR_i == LFIFO_DAT_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;
//assign R_RXFIFO_Pop_o = ( WBs_ADR_i == RFIFO_DAT_REG_ADR && WBs_CYC_i == 1'b1)? pop_int: 1'b0;
//assign L_RXFIFO_Pop_o =  1'b0;
//assign R_RXFIFO_Pop_o =  1'b0;     
			
            //L_RXFIFO_DAT_i,     
            //L_RXFIFO_Pop_o,   
            //R_RXFIFO_DAT_i,     
            //R_RXFIFO_Pop_o,     
			//FIR Decimation Signals
			//STEREO_EN_o,
			//LR_CHNL_SEL_o,			
            
			//L_Rx_FIFO_Empty_i,  	
			//L_Rx_FIFO_Full_i,   	
			//L_Rx_FIFO_Level_i,  	
			//R_Rx_FIFO_Empty_i,  	
			//R_Rx_FIFO_Full_i,   	
			//R_Rx_FIFO_Level_i, 

//input            [15:0]  L_RXFIFO_DAT_i  ;
//output                   L_RXFIFO_Pop_o  ;
//input            [15:0]  R_RXFIFO_DAT_i  ;
//output                   R_RXFIFO_Pop_o  ;
//output                   STEREO_EN_o     ;
//output                   LR_CHNL_SEL_o   ;

//assign STEREO_EN_o = stereo_en;

//assign dma_start_str 		= (L_Rx_FIFO_Level_i >= DMA_CNT_o && R_Rx_FIFO_Level_i >= DMA_CNT_o )? 1'b1 : 1'b0;
//assign dma_start_mono 		= (DeciData_Rx_FIFO_Level_i >= DMA_CNT_o)? 1'b1 : 1'b0;
//assign DMA_Start 			= (stereo_en)? dma_start_str: dma_start_mono; 
