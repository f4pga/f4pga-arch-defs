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
`define NO_ACSLIP

module i2s_slave_w_DMA_registers ( 
                         
            WBs_CLK_i,          
            WBs_RST_i,   

			sys_ref_clk_i,		
            
            WBs_ADR_i,          
            WBs_CYC_i,  
            WBs_CYC_I2SRx_Real_RAM_i,
            WBs_CYC_I2SRx_Img_RAM_i,
            WBs_CYC_f_CosSin_RAM_i, 
 			
            WBs_BYTE_STB_i,     
            WBs_WE_i,           
            WBs_STB_i,          
            WBs_DAT_i,          
            WBs_DAT_o, 
            WBs_CosSin_RAM_DAT_o,			
            WBs_f_RealImg_RAM_DAT_o,	//	Real Data = [31:16]. Img Data = [15:0] 	
            WBs_ACK_o,   

			i2s_dis_i,
            I2S_S_EN_o,  
            ACSLIP_EN_o,  

            ACSLIP_Reg_Rst_o,	

            ACLSIP_Reg_i,

            RAM_logic_rst_o, 			

            wb_L_f_RAM_aDDR_o,			
            wb_L_f_RAM_Wen_o,
			wb_L_f_RAM_wr_rd_Mast_sel_o,
			wb_L_f_Real_RAM_Data_i,
			wb_L_f_Img_RAM_Data_i,
			
			wb_CosSin_RAM_aDDR_o,
			wb_CosSin_RAM_Wen_o,
			wb_CosSin_RAM_Data_o,   //Cos Data = [31:16]. Sin Data = [15:0] 
			wb_CosSin_RAM_Data_i,   //Cos Data = [31:16]. Sin Data = [15:0]      
			wb_CosSin_RAM_rd_access_ctrl_o,      
			
            f_calc_done_i,
			f_ena_o, 
		
			f_Done_IRQ_EN_o,  
            f_Done_IRQ_o,		
			
			ACSLIP_timer_IRQ_EN_o,
			ACSLIP_timer_IRQ_o,
				
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

parameter                I2S_EN_REG_ADR          	 =  10'h0         ;
parameter                ACSLIP_REG_RST_ADR          =  10'h1         ;
parameter                INTR_STS_REG_ADR          	 =  10'h2         ;
parameter                INTR_EN_REG_ADR          	 =  10'h3         ;
parameter                RESERVED_f_0              =  10'h4         ;
parameter                RESERVED_f_1		         =  10'h5         ;
parameter                ACSLIP_REG_ADR              =  10'h6         ;
parameter                RESERVED_f_2              =  10'h7         ;
parameter                DMA_EN_REG_ADR              =  10'h8         ;
parameter                DMA_STS_REG_ADR             =  10'h9         ;
parameter                DMA_CNT_REG_ADR             =  10'hA         ;
parameter                ACSLIP_TIMER_REG_ADR        =  10'hB         ;
parameter                f_CNTRL_REG_ADR           =  10'hC         ;
parameter                MIC_DAT_CNT_ADR             =  10'hD         ;
parameter                I2S_DAT_CNT_ADR             =  10'hE         ;
parameter                RESERVED_2                  =  10'hD         ;
parameter                f_RAM_STRT_ADDR1  	     =  10'h200       ;
parameter                f_RAM_STRT_ADDR2          =  10'h000       ;
parameter                f_CosSin_RAM_ADDR1         =  10'h200      ;


parameter                RESERVED_3                  =  10'hB         ;//9'hB         ;

parameter                DMA_DEF_REG_VALUE           = 32'hDAD_DEF_AC; // Distinguish access to undefined area

parameter                ACSLIP_REG_WIDTH            = 32;//Default 9


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric
input                    sys_ref_clk_i       ; // Fabric Reset               to   Fabric

//input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input   [ADDRWIDTH:0]    WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input                    WBs_CYC_I2SRx_Real_RAM_i   ; 
input                    WBs_CYC_I2SRx_Img_RAM_i   ; 
input                    WBs_CYC_f_CosSin_RAM_i      ;

input            [2:0]	 WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [31:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  WBs_CosSin_RAM_DAT_o       ; // Read Data Bus              from Fabric
output  [DATAWIDTH-1:0]  WBs_f_RealImg_RAM_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

input					 i2s_dis_i;
output                   I2S_S_EN_o      ;
output                   ACSLIP_EN_o      ;
output                   ACSLIP_Reg_Rst_o      ;
//input        [9:0]       ACLSIP_Reg_i      ;
input        [ACSLIP_REG_WIDTH-1:0]       ACLSIP_Reg_i      ;
output                   RAM_logic_rst_o;


output 			  [9:0]  wb_L_f_RAM_aDDR_o;		
output 					 wb_L_f_RAM_Wen_o;
output  				 wb_L_f_RAM_wr_rd_Mast_sel_o;
input            [15:0]   wb_L_f_Real_RAM_Data_i;
input            [15:0]   wb_L_f_Img_RAM_Data_i;


output 			  [9:0]  wb_CosSin_RAM_aDDR_o;		
output 					 wb_CosSin_RAM_Wen_o;
output            [31:0] wb_CosSin_RAM_Data_o;

input [31:0]  			 wb_CosSin_RAM_Data_i;
output        			 wb_CosSin_RAM_rd_access_ctrl_o;

//FIR decimation
input 					 f_calc_done_i;
output 					 f_ena_o;
	
output                   f_Done_IRQ_EN_o ;	
output                   f_Done_IRQ_o ;	
output                   ACSLIP_timer_IRQ_EN_o;
output                   ACSLIP_timer_IRQ_o;
				
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

wire	 				 DMA_Done_i;
wire	 				 DMA_Active_i; 
wire	 				 DMA_REQ_i;
wire	 				 DMA_Busy_i;
wire	 				 DMA_Clr_i;

reg                      I2S_S_EN_o      ; 
reg                      ACSLIP_EN_o      ; 

wire 					 f_Done_IRQ_o;
reg                      f_Done_IRQ_EN_o ;


reg              		 I2S_Dis_IRQ_o;
reg              		 I2S_Dis_IRQ_EN_o;

reg                      ACSLIP_timer_IRQ_EN_o;
reg                      ACSLIP_timer_IRQ_o;

reg 					 WBs_ACK_sig_r;

wire			[31:0]	 DMA_Status;
reg             [8:0]    DMA_CNT_o;

wire            [8:0]  	dma_cntr_i;
wire            [1:0]  	dma_st_i;

wire     			   	i2s_dis_i;

reg 					 wb_L_f_RAM_wr_rd_Mast_sel;
reg 					 acslip_reg_rst;
reg                      f_done_irq;
reg 					 f_en;     
reg 					 f_int_en ;
reg                      wb_CosSin_ram_rd_access_ctrl_sig;

//reg        [9:0]       ACLSIP_Reg_r1      ;
reg        [ACSLIP_REG_WIDTH-1:0]       ACLSIP_Reg_r1      ;
//reg        [31:0]      cnt_mic_dat_r ;      

reg        ram_logic_rst;

wire		acslip_rst;


//------Internal Signals---------------
//
wire                     I2S_EN_REG_Wr_Dcd ;
wire                     ACSLIP_RST_REG_Wr_Dcd ;
wire                     INTR_EN_REG_Wr_Dcd ; 
wire                     INTR_STS_REG_Wr_Dcd ; 
wire                     DMA_EN_REG_Wr_Dcd ; 
wire                     ACSLIP_TIMER_REG_Wr_Dcd ; 
wire                     f_CTRL_REG_Wr_Dcd ;
wire                     f_Real_Img_RAM_ADDR_Wr_Dcd ;
wire                     f_CosSin_RAM_ADDR_Wr_Dcd ; 
wire                     DMA_CNT_REG_Wr_Dcd ;

reg [15:0]              acslip_timer_reg;
reg [15:0]              acslip_timer_cntr;
reg 					acslip_timer_int;

reg 					acslip_timer_int_wb_r1;
reg 					acslip_timer_int_wb_r2;
reg 					acslip_timer_int_wb_r3;

reg                     DMA_start_r;

wire 					acslip_timer_int_wbsync_pulse;

wire					WBs_ACK_o_nxt;

//------Logic Operations---------------
//
assign RAM_logic_rst_o 					= ram_logic_rst;

assign WBs_ACK_o 						= ( WBs_ADR_i == RESERVED_f_1 && WBs_CYC_i == 1'b1) ? WBs_ACK_sig_r : WBs_ACK_sig;
assign wb_L_f_RAM_aDDR_o[9:0] 		= WBs_ADR_i[ADDRWIDTH:0];
assign wb_L_f_RAM_Wen_o       		= f_Real_Img_RAM_ADDR_Wr_Dcd;

assign wb_CosSin_RAM_aDDR_o[9]          = 0;
assign wb_CosSin_RAM_aDDR_o[8:0]        = WBs_ADR_i[ADDRWIDTH-1 : 0];
assign wb_CosSin_RAM_Wen_o       		= f_CosSin_RAM_ADDR_Wr_Dcd;
assign wb_CosSin_RAM_Data_o             = WBs_DAT_i[31:0];

assign WBs_CosSin_RAM_DAT_o             = wb_CosSin_RAM_Data_i;
assign WBs_f_RealImg_RAM_DAT_o        = {wb_L_f_Real_RAM_Data_i,wb_L_f_Img_RAM_Data_i};

assign f_Done_IRQ_o 					= f_done_irq;

assign ACSLIP_Reg_Rst_o 				= acslip_reg_rst;

//assign DMA_Start 						= (DeciData_Rx_FIFO_Level_i >= DMA_CNT_o )? 1'b1 : 1'b0; 
assign DMA_Start 						= DMA_start_r; 
assign DMA_Start_o 						= DMA_Start & DMA_EN;

assign wb_CosSin_RAM_rd_access_ctrl_o 	= wb_CosSin_ram_rd_access_ctrl_sig;

// Determine each register decode
//
assign I2S_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == I2S_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign ACSLIP_RST_REG_Wr_Dcd    = ( WBs_ADR_i == ACSLIP_REG_RST_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign INTR_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == INTR_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign INTR_STS_REG_Wr_Dcd 		= ( WBs_ADR_i == INTR_STS_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_EN_REG_Wr_Dcd 		= ( WBs_ADR_i == DMA_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign ACSLIP_TIMER_REG_Wr_Dcd  = ( WBs_ADR_i == ACSLIP_TIMER_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign DMA_CNT_REG_Wr_Dcd 		= ( WBs_ADR_i == DMA_CNT_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;
assign f_CTRL_REG_Wr_Dcd 		= ( WBs_ADR_i == f_CNTRL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ;

//RAM Write decodes
assign f_Real_Img_RAM_ADDR_Wr_Dcd 	= (WBs_CYC_I2SRx_Real_RAM_i | WBs_CYC_I2SRx_Img_RAM_i) & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
assign f_CosSin_RAM_ADDR_Wr_Dcd 		= WBs_CYC_f_CosSin_RAM_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_sig) ; 
   
   
// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt                    =   (WBs_CYC_i | WBs_CYC_f_CosSin_RAM_i | WBs_CYC_I2SRx_Real_RAM_i)  & WBs_STB_i & (~WBs_ACK_sig & ~WBs_ACK_sig_r);

assign wb_L_f_RAM_wr_rd_Mast_sel_o    = wb_L_f_RAM_wr_rd_Mast_sel;

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		DMA_start_r <= 0;
	end
	else
	begin
	     if (f_calc_done_i)
		 begin
		     DMA_start_r <= 1;
		 end
		 else if (DMA_Active_i)
		 begin
			DMA_start_r <= 0;
         end
    end
end



// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        I2S_S_EN_o          				<= 1'b1;
        ACSLIP_EN_o          				<= 1'b0;
		wb_L_f_RAM_wr_rd_Mast_sel 	    <= 1'b0; 
		wb_CosSin_ram_rd_access_ctrl_sig 	<= 1'b0; 
		acslip_reg_rst                  	<= 1'b1;
		acslip_timer_reg                  	<= 16'h1DF;
		DMA_EN	 		    				<= 1'b0;
		ACSLIP_timer_IRQ_o       	        <= 1'b0;
		ACSLIP_timer_IRQ_EN_o       	    <= 1'b0;
		I2S_Dis_IRQ_o       				<= 1'b0;
		I2S_Dis_IRQ_EN_o    				<= 1'b0;
		DMA_Done_IRQ_o	 					<= 1'b0;
		DMA_Done_IRQ_EN_o					<= 1'b0;
		f_done_irq	 					<= 1'b0;
		f_Done_IRQ_EN_o                  <= 1'b0;		

        WBs_ACK_sig           				<= 1'b0; 
		WBs_ACK_sig_r           		    <= 1'b0;
		DMA_CNT_o           				<= 9'h4;
		ram_logic_rst           			<= 0;
		
		f_en                         <= 1'b1;
		f_int_en                     <= 1'b0;
		

    end  
    else
    begin
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin
            I2S_S_EN_o  <=  WBs_DAT_i[0];
`ifdef 	NO_ACSLIP
			ACSLIP_EN_o <=  0;
`else			
			ACSLIP_EN_o <=  WBs_DAT_i[2];
`endif			
			
		end	
		else if (i2s_dis_i)
		    I2S_S_EN_o  <=  1'b0;
			
	    if ( I2S_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
		     wb_L_f_RAM_wr_rd_Mast_sel 		<= WBs_DAT_i[1];
		     wb_CosSin_ram_rd_access_ctrl_sig   <= WBs_DAT_i[3];
             ram_logic_rst 						<= WBs_DAT_i[4];
	    end
		else
			ram_logic_rst 						<= 0;
		
	    if ( ACSLIP_RST_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
`ifdef 	NO_ACSLIP
			 acslip_reg_rst <= 1;
`else		
		     acslip_reg_rst <= WBs_DAT_i[0];
`endif			 
	    end
/*         else
        begin
			 acslip_reg_rst <= 1'b0;
        end */		
		
        if ( DMA_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_EN  <=  WBs_DAT_i[0];
		else if (DMA_Clr_i)
			DMA_EN  <=  1'b0;
			
        if ( f_CTRL_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            f_int_en  <=  WBs_DAT_i[1];
            f_en      <=  1'b1;//WBs_DAT_i[0];
		end	
		
        if ( ACSLIP_TIMER_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
            //acslip_timer_reg  <=  WBs_DAT_i[7:0];
`ifdef 	NO_ACSLIP
			 acslip_timer_reg <= 0;
`else			
            acslip_timer_reg  <=  WBs_DAT_i[15:0];
`endif			
		end	
        
		
			
		if ( INTR_EN_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
		begin
`ifdef 	NO_ACSLIP		
			ACSLIP_timer_IRQ_EN_o           <=  0;
`else
		    ACSLIP_timer_IRQ_EN_o           <=  WBs_DAT_i[4];
`endif			
		    I2S_Dis_IRQ_EN_o     		    <=  WBs_DAT_i[3];
		    // WBs_DAT_i[2] Unused
		    f_Done_IRQ_EN_o               <=  WBs_DAT_i[1];
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
		
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || f_calc_done_i )
        begin
            f_done_irq   <=  f_calc_done_i ? 1'b1 : WBs_DAT_i[2];
        end		
		
		if ( (INTR_STS_REG_Wr_Dcd && WBs_BYTE_STB_i[0]) || acslip_timer_int_wbsync_pulse)
        begin
`ifdef 	NO_ACSLIP	
			 ACSLIP_timer_IRQ_o   <= 0;
`else		
            ACSLIP_timer_IRQ_o   <=  acslip_timer_int_wbsync_pulse ? 1'b1 : WBs_DAT_i[4];
`endif			
        end			
		
		
	    if ( DMA_CNT_REG_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_CNT_o  <=  WBs_DAT_i[8:0];
			
        WBs_ACK_sig               <=  WBs_ACK_o_nxt;
		WBs_ACK_sig_r				<=  WBs_ACK_sig;		
    end  
end

assign DMA_Status = {dma_st_i,5'h0,dma_cntr_i,DMA_Start_o,11'h0,DMA_REQ_i,DMA_Active_i,DMA_Done_IRQ_o,DMA_Busy_i};


assign f_ena_o = f_en;

 
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              		or
		 I2S_S_EN_o             		or
		 ACSLIP_EN_o             		or
		 wb_L_f_RAM_wr_rd_Mast_sel       		or
		 wb_CosSin_ram_rd_access_ctrl_sig       		or
		 ACLSIP_Reg_r1       		     or

		 acslip_reg_rst          		or
		 I2S_Dis_IRQ_o          		or
		 ACSLIP_timer_IRQ_o          	or
		 DMA_Done_IRQ_o         		or
		 f_Done_IRQ_EN_o      		or
		 DMA_Done_IRQ_EN_o      		or
		 I2S_Dis_IRQ_EN_o       		or
		 ACSLIP_timer_IRQ_EN_o       	or

		 DMA_Status             		or
		 DMA_EN                 		or
		 DMA_CNT_o   					or 
		 acslip_timer_reg   		    or 
		 f_en   	        		or 
		 f_int_en   	     

 )
 begin
    //case(WBs_ADR_i[ADDRWIDTH-1:0])
    case(WBs_ADR_i[ADDRWIDTH:0])
    I2S_EN_REG_ADR        : WBs_DAT_o <= { 28'h0,wb_CosSin_ram_rd_access_ctrl_sig,ACSLIP_EN_o, wb_L_f_RAM_wr_rd_Mast_sel,I2S_S_EN_o}; 
	ACSLIP_REG_RST_ADR    : WBs_DAT_o <= { 31'h0, acslip_reg_rst};
	INTR_STS_REG_ADR      : WBs_DAT_o <= { 27'h0, ACSLIP_timer_IRQ_o, I2S_Dis_IRQ_o, 1'b0,1'b0,DMA_Done_IRQ_o};//INTR_STS_REG_ADR      : WBs_DAT_o <= { 28'h0, I2S_Dis_IRQ_o, R_RX_DAT_IRQ_o,DeciData_Rx_FIFO_DAT_IRQ_o,DMA_Done_IRQ_o};
	INTR_EN_REG_ADR       : WBs_DAT_o <= { 27'h0, ACSLIP_timer_IRQ_EN_o,I2S_Dis_IRQ_EN_o,1'b0, f_Done_IRQ_EN_o, DMA_Done_IRQ_EN_o};//{ 28'h0, I2S_Dis_IRQ_EN_o,R_RX_DAT_IRQ_EN_o, DeciData_Rx_DAT_AVL_IRQ_EN_o, DMA_Done_IRQ_EN_o};
	RESERVED_f_0 		  : WBs_DAT_o <= 0;//{ 16'h0, Deci_Rx_FIFO_Full,Deci_Rx_FIFO_Empty,7'h0, DeciData_Rx_FIFO_Level_i};  
	RESERVED_f_1        : WBs_DAT_o <= 0;//{ Fifo_dat_r_up,Fifo_dat_r_lo};  
`ifdef 	NO_ACSLIP
	ACSLIP_REG_ADR        : WBs_DAT_o <=  0;
`else	
	ACSLIP_REG_ADR        : WBs_DAT_o <=  ACLSIP_Reg_r1;
`endif	
	RESERVED_f_2        : WBs_DAT_o <= 0;//{ 31'h0, Deci_Rx_FIFO_Flush};
    DMA_EN_REG_ADR   	  : WBs_DAT_o <= { 31'h0, DMA_EN };
	DMA_STS_REG_ADR  	  : WBs_DAT_o <= { DMA_Status};
	DMA_CNT_REG_ADR  	  : WBs_DAT_o <= { 23'h0, DMA_CNT_o};
`ifdef 	NO_ACSLIP
    ACSLIP_TIMER_REG_ADR  : WBs_DAT_o <= 0;
`else	
	ACSLIP_TIMER_REG_ADR  : WBs_DAT_o <= { 16'h0, acslip_timer_reg};
`endif	
	f_CNTRL_REG_ADR : WBs_DAT_o <= { 30'h0, f_int_en, f_en};
	
	
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
