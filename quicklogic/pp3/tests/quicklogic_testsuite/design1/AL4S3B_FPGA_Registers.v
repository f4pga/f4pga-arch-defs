// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_Registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/03	
// last update    : 2016/02/03
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to registers and memory 
//              located in the programmable FPGA.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/02/03      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module AL4S3B_FPGA_Registers ( 

                        // AHB-To_FPGA Bridge I/F
                        //
                        WBs_ADR_i,
                        WBs_CYC_i,
						WBs_CYC_DMA_REG_i, 
						WBs_CYC_DMA_DAT_i,
                        WBs_BYTE_STB_i,
                        WBs_WE_i,
                        WBs_STB_i,
                        WBs_DAT_i,
                        WBs_CLK_i,
                        WBs_RST_i,
                        WBs_DAT_o,
                        WBs_ACK_o,
						
						WBs_DMA_REG_o, 
						WBs_DMA_DAT_o,

                        //
                        // Misc
                        //
						Sensor_Enable_o,      
						//Sensor_1_Config_o,    
						//Sensor_2_Config_o,    
						//Sensor_3_Config_o,    
						//Sensor_4_Config_o,    
						 
						SPI_clk_i,
						Sensor_RD_Data_i,     
						Sensor_RD_Push_i,     
						rx_fifo_full_o,       
						 
						//Timer settings 
						//
						//Timer_Count_o,        
						//Timer_Enable_o,       
						 
						///DMA 
						//
						DMA0_Clr_i,           
						DMA0_Done_i,          
						DMA0_Start_o, 

						DMA_Enable_o,

						DMA_Active_i,
						DMA_REQ_i,	
						fsm_top_st_i, 
						spi_fsm_st_i,
											 
						DMA0_Done_IRQ_o,  
						
						dbg_reset_o,
						
						GPIO_IN_i,
				        GPIO_OUT_o,
				        GPIO_OE_o,
						 
						Device_ID_o
                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =  10;   // Allow for up to 128 registers in the FPGA
parameter                DATAWIDTH                   =  32;   // Allow for up to 128 registers in the FPGA

parameter                FPGA_REG_ID_VALUE_ADR       =  7'h0; 
parameter                FPGA_REV_NUM_ADR            =  7'h1; 
parameter                FPGA_FIFO_RST_ADR           =  7'h2; 
parameter                FPGA_SENSOR_EN_REG_ADR      =  7'h3;  
parameter                FPGA_SEN1_SETTING_ADR       =  7'h4; 
parameter                FPGA_SEN2_SETTING_ADR       =  7'h5;
parameter                FPGA_SEN3_SETTING_ADR       =  7'h6;
parameter                FPGA_SEN4_SETTING_ADR       =  7'h7;
parameter                FPGA_TIMER_CNT_REG_ADR      =  7'h8; 
parameter                FPGA_TIMER_EN_REG_ADR       =  7'h9; 

parameter       		 FPGA_DBG1_REG_ADR           =  7'hC; 
parameter       		 FPGA_DBG2_REG_ADR           =  7'hD;
parameter       		 FPGA_DBG3_REG_ADR           =  7'hE;

parameter       		 FABRIC_GPIO_IN_REG_ADR      =  7'h40; 
parameter       		 FABRIC_GPIO_OUT_REG_ADR     =  7'h41; 
parameter       		 FABRIC_GPIO_OE_REG_ADR      =  7'h42; 
                         
parameter                DMA_EN_REG_ADR              =  10'h0; 
parameter                DMA_STS_REG_ADR             =  10'h1;
parameter                DMA_INTR_EN_REG_ADR         =  10'h2;

parameter                AL4S3B_DEVICE_ID            =  16'h0;
parameter                AL4S3B_REV_LEVEL            =  32'h0;
parameter                AL4S3B_GPIO_REG             =  22'h0;
parameter                AL4S3B_GPIO_OE_REG          =  22'h0;
parameter                AL4S3B_SCRATCH_REG          =  32'h12345678  ;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   FPGA
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   FPGA 
input                    WBs_CYC_DMA_REG_i     ;
input                    WBs_CYC_DMA_DAT_i     ; 
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   FPGA
input                    WBs_WE_i      ;  // Write Enable               to   FPGA
input                    WBs_STB_i     ;  // Strobe Signal              to   FPGA
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   FPGA
input                    WBs_CLK_i     ;  // FPGA Clock               from FPGA
input                    WBs_RST_i     ;  // FPGA Reset               to   FPGA
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from FPGA
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from FPGA

output  [DATAWIDTH-1:0]  WBs_DMA_REG_o ;  // Read Data Bus              from FPGA
output  [DATAWIDTH-1:0]  WBs_DMA_DAT_o ;  // Read Data Bus              from FPGA
 

//
// Misc
//
output           [31:0]  Device_ID_o   ;

output           	     Sensor_Enable_o;
//output           [3:0]   Sensor_Enable_o;
//output           [7:0]   Sensor_1_Config_o;
//output           [7:0]   Sensor_2_Config_o;
//output           [7:0]   Sensor_3_Config_o;
//output           [7:0]   Sensor_4_Config_o;

input   		[31:0]   Sensor_RD_Data_i;
input   		 		 Sensor_RD_Push_i;
output   		 		 rx_fifo_full_o; 
input   		 		 SPI_clk_i;

//output           [15:0]  Timer_Count_o; 
//output                   Timer_Enable_o;
     
input   		 		 DMA0_Clr_i;
input   		 		 DMA0_Done_i;   
output                   DMA0_Start_o;  

output					 DMA_Enable_o;

input   		 		 DMA_Active_i;
input   		 		 DMA_REQ_i;   
input   		 [1:0]	 fsm_top_st_i; 
input   		 [1:0]	 spi_fsm_st_i;   

output                   DMA0_Done_IRQ_o;

output 					 dbg_reset_o;

// GPIO
//
input            [3:0]  GPIO_IN_i     ;
output           [3:0]  GPIO_OUT_o    ;
output           [3:0]  GPIO_OE_o     ;


// FPGA Global Signals
//
wire                     WBs_CLK_i     ;  // Wishbone FPGA Clock
wire                     WBs_RST_i     ;  // Wishbone FPGA Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Wishbone Address Bus
wire                     WBs_CYC_i     ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select) 
wire                     WBs_CYC_DMA_REG_i;
wire                     WBs_CYC_DMA_DAT_i; 
wire              [3:0]  WBs_BYTE_STB_i;  // Wishbone Byte   Enables
wire                     WBs_WE_i      ;  // Wishbone Write  Enable Strobe
wire                     WBs_STB_i     ;  // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Wishbone Read   Data Bus

reg     [DATAWIDTH-1:0]  WBs_DMA_REG_o ;  // Wishbone Read   Data Bus
wire    [DATAWIDTH-1:0]  WBs_DMA_DAT_o ;  // Wishbone Read   Data Bus

reg                      WBs_ACK_o     ;  // Wishbone Client Acknowledge

wire                     WBs_DMA_DAT     ;
reg                      WBs_DMA_DAT_r1  ;
reg                      WBs_DMA_DAT_r2  ;

wire					 DMA_Enable_o;

// Misc
//
wire             [31:0]  Device_ID_o;
wire    		 [31:0]  Rev_Num;

reg           	         Sensor_Enable_o;
//reg           	 [3:0]   Sensor_Enable_o;
//reg           	 [7:0]   Sensor_1_Config_o;
//reg           	 [7:0]   Sensor_2_Config_o;
//reg           	 [7:0]   Sensor_3_Config_o;
//reg           	 [7:0]   Sensor_4_Config_o; 

wire    		 [31:0]  Sensor_RD_Data_i;
wire    		 		 Sensor_RD_Push_i;
wire    		 		 rx_fifo_full_o;
wire    		 		 SPI_clk_i;

//reg              [15:0]  Timer_Count_o;
//reg                      Timer_Enable_o;
     
wire     		 		 DMA0_Clr_i;
wire    		 		 DMA0_Done_i;   
wire                     DMA0_Start_o;

wire                     DMA0_Done_IRQ_o; 

wire                     FIFO_Flush;
reg                      FIFO_rst;
reg                      DMA0_EN;
reg                      DMA0_Done_IRQ_EN;
reg                      DMA0_Done_IRQ;

wire					 rx_fifo_empty;
wire					 Pop_Sig_int;
wire					 Pop_Sig;
wire					 Push_Sig;
wire			[3:0]    pop_flag; 

wire			[31:0]   debug_sig1;
wire			[31:0]   debug_sig2;

reg				[9:0]	 rx_fifo_cnt;  
reg 					 dma_done;

wire    		 		 DMA_Active_i; 
wire    		 		 DMA_REQ_i; 
wire    		[1:0]	 fsm_top_st_i;
wire    		[1:0]	 spi_fsm_st_i;

// GPIO
//
wire             [3:0]  GPIO_IN_i     ;
reg              [3:0]  GPIO_OUT_o    ;
reg              [3:0]  GPIO_OE_o     ;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
//wire					 FB_Dev_ID_Wr_Dcd      ;
wire                     FPGA_FIFO_RST_Dcd    ;
wire                     FPGA_SENSOR_EN_REG_Dcd    ;  
//wire                     FPGA_SEN1_SETTING_Dcd    ;
//wire                     FPGA_SEN2_SETTING_Dcd    ;
//wire                     FPGA_SEN3_SETTING_Dcd    ;
//wire                     FPGA_SEN4_SETTING_Dcd    ;
//wire                     FPGA_TIMER_CNT_REG_Dcd    ;  
//wire                     FPGA_TIMER_EN_REG_Dcd    ;

wire                     FB_GPIO_Reg_Wr_Dcd    ;
wire                     FB_GPIO_OE_Reg_Wr_Dcd ;

wire                     DMA_EN_REG_Dcd    ; 
wire                     DMA_STS_REG_Dcd    ;
wire                     DMA_INTR_EN_REG_Dcd    ;

wire					 dbg_reset_o;

wire 		fifo_ovrrun;
reg 		fifo_ovrrun_r;
reg [15:0]	tcounter;

//------Logic Operations---------------
//
assign DMA0_Done_IRQ_o = DMA0_Done_IRQ & DMA0_Done_IRQ_EN; 
assign DMA0_Start_o    =  (rx_fifo_cnt > 10'hFF) & DMA0_EN; 
assign rx_fifo_full_o  =  (pop_flag == 4'hF)? 1'b1: 1'b0;
assign rx_fifo_empty   =  (pop_flag == 4'h0)? 1'b1: 1'b0;

assign DMA_Enable_o = DMA0_EN;

// debug
assign dbg_reset_o = FIFO_Flush;

// Define the FPGA's local register write enables
//
//assign FB_Dev_ID_Wr_Dcd       = ( WBs_ADR_i == FPGA_REG_ID_VALUE_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FPGA_FIFO_RST_Dcd      = ( WBs_ADR_i == FPGA_FIFO_RST_ADR  ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FPGA_SENSOR_EN_REG_Dcd = ( WBs_ADR_i == FPGA_SENSOR_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_SEN1_SETTING_Dcd  = ( WBs_ADR_i == FPGA_SEN1_SETTING_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_SEN2_SETTING_Dcd  = ( WBs_ADR_i == FPGA_SEN2_SETTING_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_SEN3_SETTING_Dcd  = ( WBs_ADR_i == FPGA_SEN3_SETTING_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_SEN4_SETTING_Dcd  = ( WBs_ADR_i == FPGA_SEN4_SETTING_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_TIMER_CNT_REG_Dcd = ( WBs_ADR_i == FPGA_TIMER_CNT_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FPGA_TIMER_EN_REG_Dcd  = ( WBs_ADR_i == FPGA_TIMER_EN_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_GPIO_Reg_Wr_Dcd     = ( WBs_ADR_i == FABRIC_GPIO_OUT_REG_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_OE_Reg_Wr_Dcd  = ( WBs_ADR_i == FABRIC_GPIO_OE_REG_ADR     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign DMA_EN_REG_Dcd  = ( WBs_ADR_i == DMA_EN_REG_ADR ) & WBs_CYC_DMA_REG_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o); 
assign DMA_STS_REG_Dcd = ( WBs_ADR_i == DMA_STS_REG_ADR ) & WBs_CYC_DMA_REG_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign DMA_INTR_EN_REG_Dcd  = ( WBs_ADR_i == DMA_INTR_EN_REG_ADR ) & WBs_CYC_DMA_REG_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt  =   (WBs_CYC_i | WBs_CYC_DMA_REG_i | WBs_CYC_DMA_DAT_i) & WBs_STB_i & (~WBs_ACK_o);

assign WBs_DMA_DAT    =   WBs_CYC_DMA_DAT_i & WBs_STB_i & (~WBs_DMA_DAT_r1);


// Define the FPGA's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		FIFO_rst    	  <= 1'b0    ;
		Sensor_Enable_o   <= 1'b0    ;
		GPIO_OUT_o        <= 4'h0    ;
		GPIO_OE_o         <= 4'h0    ;
		//Sensor_1_Config_o <= 8'h0    ;
		//Sensor_2_Config_o <= 8'h0    ;
		//Sensor_3_Config_o <= 8'h0    ;
		//Sensor_4_Config_o <= 8'h0    ;
		//Timer_Count_o     <= 16'h100 ;
		//Timer_Enable_o 	<= 1'b0    ;
		WBs_ACK_o    	  <= 1'b0    ;
		WBs_DMA_DAT_r1	  <= 1'b0    ;
		WBs_DMA_DAT_r2	  <= 1'b0    ;
		
    end  
    else
    begin
	
		if(FPGA_FIFO_RST_Dcd && WBs_BYTE_STB_i[0])
			FIFO_rst      <= WBs_DAT_i[0];
		else
		    FIFO_rst      <= 1'b0;
	
		if(FPGA_SENSOR_EN_REG_Dcd && WBs_BYTE_STB_i[0])
			Sensor_Enable_o 		<= WBs_DAT_i[0]  ;
			
        // Define the GPIO Register 
        //
        if(FB_GPIO_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
			GPIO_OUT_o[3:0]   <= WBs_DAT_i[3:0]  ;
			
        // Define the GPIO Control Register 
        //
        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
			GPIO_OE_o[3:0]    <= WBs_DAT_i[3:0]  ;

        //if(FPGA_SEN1_SETTING_Dcd && WBs_BYTE_STB_i[0])
		//	Sensor_1_Config_o[7:0]  <= WBs_DAT_i[7:0] ;
			
        //if(FPGA_SEN2_SETTING_Dcd && WBs_BYTE_STB_i[0])
		//	Sensor_2_Config_o[7:0]  <= WBs_DAT_i[7:0] ;
			
        //if(FPGA_SEN3_SETTING_Dcd && WBs_BYTE_STB_i[0])
		//	Sensor_3_Config_o[7:0]  <= WBs_DAT_i[7:0] ;
			
        //if(FPGA_SEN4_SETTING_Dcd && WBs_BYTE_STB_i[0])
		//	Sensor_4_Config_o[7:0]  <= WBs_DAT_i[7:0] ;

        //if(FPGA_TIMER_CNT_REG_Dcd && WBs_BYTE_STB_i[0])  
		//	Timer_Count_o[15:0]     <= WBs_DAT_i[15:0];

        //if(FPGA_TIMER_EN_REG_Dcd && WBs_BYTE_STB_i[0])
		//	Timer_Enable_o          <= WBs_DAT_i[0];	
		
        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
		WBs_DMA_DAT_r1              <=  WBs_DMA_DAT    ;
		WBs_DMA_DAT_r2              <=  WBs_DMA_DAT_r1 ;
    end  
end

assign Device_ID_o = 32'h00055ADC;
assign Rev_Num     = 32'h00000211; 

always @(posedge WBs_CLK_i or posedge DMA0_Done_i) 
begin
    if (DMA0_Done_i)
            dma_done          <=  1'b1 ;
    else 
    	if (~DMA0_EN)
			dma_done          <=  1'b0;
		else 
			dma_done          <=  dma_done;
end	

assign debug_sig1 = {6'h0,rx_fifo_cnt,pop_flag, 2'b00,rx_fifo_full_o, rx_fifo_empty};
assign debug_sig2 = {14'h0,spi_fsm_st_i,6'h0,fsm_top_st_i,4'h0,DMA_REQ_i,DMA_Active_i,dma_done,DMA0_Start_o};   

// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i        	or
         Device_ID_o      	or
		 Rev_Num          	or
         FIFO_rst         	or
		 Sensor_Enable_o  	or
		 tcounter			or
		 fifo_ovrrun_r		or
		 GPIO_IN_i			or
		 GPIO_OUT_o         or
		 GPIO_OE_o			or
		 //Sensor_1_Config_o	or
		 //Sensor_2_Config_o  or
		 //Sensor_3_Config_o  or
		 //Sensor_4_Config_o  or
		 //Timer_Count_o      or
		 //Timer_Enable_o     or 
		 debug_sig1         or
		 debug_sig2         
		 
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    FPGA_REG_ID_VALUE_ADR     : WBs_DAT_o <= Device_ID_o         			  ;     
	FPGA_REV_NUM_ADR          : WBs_DAT_o <= Rev_Num            			  ;
    FPGA_FIFO_RST_ADR         : WBs_DAT_o <= { 31'h0, FIFO_rst   		    } ;
	FPGA_SENSOR_EN_REG_ADR    : WBs_DAT_o <= { 31'h0, Sensor_Enable_o       } ;
	FPGA_SEN1_SETTING_ADR     : WBs_DAT_o <= { tcounter, 15'h0,fifo_ovrrun_r} ;
	FABRIC_GPIO_IN_REG_ADR    : WBs_DAT_o <= { 28'h0, GPIO_IN_i             } ;
    FABRIC_GPIO_OUT_REG_ADR   : WBs_DAT_o <= { 28'h0, GPIO_OUT_o          	} ;
    FABRIC_GPIO_OE_REG_ADR    : WBs_DAT_o <= { 28'h0, GPIO_OE_o           	} ;
	//FPGA_SEN2_SETTING_ADR     : WBs_DAT_o <= { 24'h0, Sensor_2_Config_o     };
	//FPGA_SEN3_SETTING_ADR     : WBs_DAT_o <= { 24'h0, Sensor_3_Config_o     };
	//FPGA_SEN4_SETTING_ADR     : WBs_DAT_o <= { 24'h0, Sensor_4_Config_o     };
	//FPGA_TIMER_CNT_REG_ADR    : WBs_DAT_o <= { 16'h0, Timer_Count_o         };
	//FPGA_TIMER_EN_REG_ADR     : WBs_DAT_o <= { 31'h0, Timer_Enable_o        };
	FPGA_DBG1_REG_ADR		  : WBs_DAT_o <= debug_sig1;
	FPGA_DBG2_REG_ADR		  : WBs_DAT_o <= debug_sig2;
	default                   : WBs_DAT_o <= AL4S3B_DEF_REG_VALUE          ;
	endcase
end

always @( posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
    if (WBs_RST_i)
    begin
		DMA0_EN      	  <= 1'b0    ; 
		DMA0_Done_IRQ_EN  <= 1'b0    ;
    end  
    else
    begin

		if(DMA_EN_REG_Dcd && WBs_BYTE_STB_i[0])
		begin
			DMA0_EN  <= WBs_DAT_i[0];
		end
		else if (DMA0_Clr_i)
		begin
			DMA0_EN  <=  1'b0;
		end	
			
		if(DMA_INTR_EN_REG_Dcd && WBs_BYTE_STB_i[0])
		begin
			DMA0_Done_IRQ_EN 	<= WBs_DAT_i[0]  ;
		end

    end  
end

always @( posedge WBs_CLK_i or posedge WBs_RST_i or posedge DMA0_Done_i) 
begin
    if (WBs_RST_i)
    begin
	    DMA0_Done_IRQ   <= 1'b0;
	end
	else
    if (DMA0_Done_i)
    begin
	    DMA0_Done_IRQ   <= 1'b1;
	end	
	else
	begin
		if ( (DMA_STS_REG_Dcd && WBs_BYTE_STB_i[0]))
        begin
            DMA0_Done_IRQ   <=  WBs_DAT_i[0];
        end	
	
	end
end	

always @(
         WBs_ADR_i        or
         DMA0_EN          or
		 DMA0_Done_IRQ    or
         DMA0_Done_IRQ_EN		  
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    DMA_EN_REG_ADR            : WBs_DMA_REG_o <= {31'h0, DMA0_EN };       
	DMA_STS_REG_ADR           : WBs_DMA_REG_o <= {31'h0, DMA0_Done_IRQ };
    DMA_INTR_EN_REG_ADR       : WBs_DMA_REG_o <= {31'h0, DMA0_Done_IRQ_EN };
	default                   : WBs_DMA_REG_o <= AL4S3B_DEF_REG_VALUE          ;
	endcase
end

assign rx_cnt_chg = Push_Sig ^ Pop_Sig;

always @( posedge WBs_CLK_i or posedge FIFO_Flush ) 
begin
    if (FIFO_Flush)
    begin
	    rx_fifo_cnt   <= 10'h0;
	end
	else
	begin
		if (rx_cnt_chg & Push_Sig )
        begin
            rx_fifo_cnt   <=  rx_fifo_cnt + 1;
        end	
		else if (rx_cnt_chg & Pop_Sig)
		begin
            rx_fifo_cnt   <=  rx_fifo_cnt - 1;
        end	
        else
        begin
		    rx_fifo_cnt   <=  rx_fifo_cnt;
        end		
	end
end	

assign FIFO_Flush = FIFO_rst | WBs_RST_i;
assign Pop_Sig_int = WBs_DMA_DAT_r1 & (~WBs_DMA_DAT_r2); 
assign Push_Sig = (~rx_fifo_full_o) & Sensor_RD_Push_i;
assign Pop_Sig  = (~rx_fifo_empty) & Pop_Sig_int;

af512x32_512x32                u_af512x32_512x32
                            (
        .DIN                ( Sensor_RD_Data_i		),
        .Fifo_Push_Flush    ( FIFO_Flush            ),
        .Fifo_Pop_Flush     ( FIFO_Flush            ),  
        .PUSH               ( Push_Sig			    ),
        .POP                ( Pop_Sig               ),
        .Push_Clk           ( WBs_CLK_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( FIFO_Flush            ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( pop_flag              ),
        .DOUT               ( WBs_DMA_DAT_o         )
        );
		
// Debug Counter
assign fifo_ovrrun = rx_fifo_full_o & Sensor_RD_Push_i; 

always @( posedge WBs_CLK_i or posedge FIFO_Flush ) 
begin
    if (FIFO_Flush)
	    fifo_ovrrun_r   <= 1'b0;
	else
	    if (fifo_ovrrun)
		    fifo_ovrrun_r   <= 1'b1;
		else
			fifo_ovrrun_r   <= fifo_ovrrun_r;
end	

always @( posedge WBs_CLK_i or posedge FIFO_Flush ) 
begin
    if (FIFO_Flush)
	    tcounter   <= 16'h0;
	else
	    if (fifo_ovrrun)
		    tcounter   <= tcounter + 1;
		else
			tcounter   <= tcounter;
end	


endmodule
