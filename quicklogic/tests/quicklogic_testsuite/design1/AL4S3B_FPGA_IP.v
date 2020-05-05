// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_IP.v
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
// 2016/05/24      1.1        Anand Wadke    Fixed HRM I2C Mapping
// 2016/05/25      1.2        Rakesh M       Fixed the HRM sensor I2C PADs, to have both the I2C LCD and I2C HRM
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module AL4S3B_FPGA_IP ( 

                // AHB-To_FPGA Bridge I/F
                //
				CLK_IP_i,
				RST_IP_i,
				
                WBs_ADR,
                WBs_CYC,
                WBs_BYTE_STB,
                WBs_WE,
                WBs_RD,
                WBs_STB,
                WBs_WR_DAT,
                WB_CLK,
                WB_RST,
                WBs_RD_DAT,
                WBs_ACK,
				
				// DMA signals
				DMA_Active_i,  
				DMA_Done_i,	   
				DMA_Req_o,	   
				INTR_o,	
				
				// GPIO's
				GPIO_PIN,

				// UART signals
				SIN_i,
				SOUT_o,
				
				UART_Intr_o,

                //
				CSn_o,
				SCLK_o,
				SDATA_i, 
				//SDI_o,
				
				//RD_o,
				//CONVST_o,
				
				//BUSY_i,
				spi_ss_i,  
				spi_sck_i, 
				spi_miso_o,
				
				Device_ID_o
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    = 10            ;

parameter       FPGA_REG_BASE_ADDRESS     	= 17'h00000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       UART_BASE_ADDRESS           = 17'h01000     ;
parameter       DMA_REG_BASE_ADDR           = 17'h10000     ;
parameter       DMA0_DPORT_BASE_ADDR        = 17'h11000     ;
//parameter       QL_RESERVED_BASE_ADDRESS    = 17'h01000     ; // Assumes 128K Byte FPGA Memory Aperture

parameter       ADDRWIDTH_FAB_REG           =  10           ;
parameter       DATAWIDTH_FAB_REG           =  32           ;

parameter       FPGA_REG_ID_VALUE_ADR       =  7'h0         ; 
parameter       FPGA_REV_NUM_ADR            =  7'h1         ; 
parameter       FPGA_FIFO_RST_ADR           =  7'h2         ; 
parameter       FPGA_SENSOR_EN_REG_ADR      =  7'h3         ; 
parameter       FPGA_SEN1_SETTING_ADR       =  7'h4         ; 
parameter       FPGA_SEN2_SETTING_ADR       =  7'h5         ;
parameter       FPGA_SEN3_SETTING_ADR       =  7'h6         ;
parameter       FPGA_SEN4_SETTING_ADR       =  7'h7         ;
parameter       FPGA_TIMER_CNT_REG_ADR      =  7'h8         ; 
parameter       FPGA_TIMER_EN_REG_ADR       =  7'h9         ; 

parameter       FPGA_DBG1_REG_ADR           =  7'hC         ; 
parameter       FPGA_DBG2_REG_ADR           =  7'hD         ;
parameter       FPGA_DBG3_REG_ADR           =  7'hE         ;

parameter       FABRIC_GPIO_IN_REG_ADR      =  7'h40        ; 
parameter       FABRIC_GPIO_OUT_REG_ADR     =  7'h41        ; 
parameter       FABRIC_GPIO_OE_REG_ADR      =  7'h42        ; 

parameter       DMA_EN_REG_ADR              =  10'h0         ;
parameter       DMA_STS_REG_ADR             =  10'h1         ;
parameter       DMA_INTR_EN_REG_ADR         =  10'h2         ;

parameter       AL4S3B_DEVICE_ID            = 16'h0         ;
parameter       AL4S3B_REV_LEVEL            = 32'h0         ;
parameter       AL4S3B_GPIO_REG             = 21'h0         ;
parameter       AL4S3B_GPIO_OE_REG          = 21'h0         ;
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access
parameter       DEFAULT_CNTR_WIDTH          =  3            ;
parameter       DEFAULT_CNTR_TIMEOUT        =  7            ;

parameter       ADDRWIDTH_QL_RESERVED       =  10            ;
parameter       DATAWIDTH_QL_RESERVED       = 32            ;

parameter       QL_RESERVED_CUST_PROD_ADR   =  7'h7E        ;
parameter       QL_RESERVED_REVISIONS_ADR   =  7'h7F        ;

parameter       QL_RESERVED_CUSTOMER_ID     =  8'h01        ;
parameter       QL_RESERVED_PRODUCT_ID      =  8'h00        ;
parameter       QL_RESERVED_MAJOR_REV       = 16'h0001      ; 
parameter       QL_RESERVED_MINOR_REV       = 16'h0000      ;

parameter       QL_RESERVED_DEF_REG_VALUE   = 32'hDEF_FAB_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [16:0]  WBs_ADR          ;  // Address Bus                to   FPGA
input           WBs_CYC          ;  // Cycle Chip Select          to   FPGA
input    [3:0]  WBs_BYTE_STB     ;  // Byte Select                to   FPGA
input           WBs_WE           ;  // Write Enable               to   FPGA
input           WBs_RD           ;  // Read  Enable               to   FPGA
input           WBs_STB          ;  // Strobe Signal              to   FPGA
input   [31:0]  WBs_WR_DAT       ;  // Write Data Bus             to   FPGA
input           WB_CLK           ;  // FPGA Clock               from FPGA
input           WB_RST           ;  // FPGA Reset               to   FPGA
output  [31:0]  WBs_RD_DAT       ;  // Read Data Bus              from FPGA
output          WBs_ACK          ;  // Transfer Cycle Acknowledge from FPGA

// GPIO
//
inout 	[3:0]	GPIO_PIN;

// Misc
//
input                	CLK_IP_i;  
input          			RST_IP_i; 
output 					CSn_o;
output 					SCLK_o;
//output 					SDI_o;
input 					SDATA_i;

//output 					RD_o; 
//input 					BUSY_i;
//output 					CONVST_o;

input 					DMA_Active_i;
input 					DMA_Done_i;
output 					DMA_Req_o;
output 					INTR_o;

output    [31:0]  		Device_ID_o;

input					spi_ss_i  ;
input					spi_sck_i ;
inout					spi_miso_o;

input          			SIN_i; 
output 					SOUT_o;

output 					UART_Intr_o;

// FPGA Global Signals
//
wire            WB_CLK           ;  // Wishbone FPGA Clock
wire            WB_RST           ;  // Wishbone FPGA Reset

// Wishbone Bus Signals
//
wire    [16:0]  WBs_ADR          ;  // Wishbone Address Bus
wire            WBs_CYC          ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire     [3:0]  WBs_BYTE_STB     ;  // Wishbone Byte   Enables
wire            WBs_WE           ;  // Wishbone Write  Enable Strobe
wire            WBs_RD           ;  // Wishbone Read   Enable Strobe
wire            WBs_STB          ;  // Wishbone Transfer      Strobe

reg     [31:0]  WBs_RD_DAT       ;  // Wishbone Read   Data Bus
wire    [31:0]  WBs_WR_DAT       ;  // Wishbone Write  Data Bus
wire            WBs_ACK          ;  // Wishbone Client Acknowledge

wire           	CLK_IP_i		 ;  
wire           	RST_IP_i		 ; 

wire 	[3:0]	GPIO_PIN;

wire    [3:0]  GPIO_In;
wire    [3:0]  GPIO_Out;
wire    [3:0]  GPIO_oe;

wire          	SIN_i; 
wire 			SOUT_o;

wire 			UART_Intr_o;

wire			CSn_o;
wire 			SCLK_o;
//wire 			SDI_o;
wire 			SDATA_i;

/* wire 			RD_o; 
wire 			CONVST_o;
wire 			BUSY_i; */

wire			DMA_Active_i; 
wire			DMA_Done_i;
wire 			DMA_Req_o;
wire 			INTR_o;   

wire 			DMA0_Start; 
wire 			DMA0_Clr;  

wire            Sensor_Enable;
//wire    [7:0]   Sensor_1_Config;
//wire    [7:0]   Sensor_2_Config;
//wire    [7:0]   Sensor_3_Config;
//wire    [7:0]   Sensor_4_Config;   

//wire    [15:0]  Timer_Count;
//wire 			Timer_Enable;  

wire    [31:0]  Sensor_RD_Data;
wire 			Sensor_RD_Push;

//wire 			fsm_run; 

//wire    [7:0]   sensor_wr_dat;
wire 		    spi_start; 
wire 		    spi_rden;
wire 		    rx_fifo_full; 

wire 		    spi_clk; 

wire 			DMA_Enable;

wire    [31:0]  Device_ID_o;

wire 	[1:0]	fsm_top_st; 
wire 	[1:0]	spi_fsm_st;

wire			dbg_reset;

wire			spi_ss_i  ;
wire			spi_sck_i ;
wire			spi_miso_o;

//------Define Parameters--------------
//

// Default I/O timeout statemachine
//
parameter       DEFAULT_IDLE   =  0  ;
parameter       DEFAULT_COUNT  =  1  ;


//------Internal Signals---------------
//

// GPIO
//

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ; 
wire            WBs_CYC_DMA_Reg    ;
wire            WBs_CYC_DMA_Data   ;
wire			WBs_CYC_UART	   ;
//wire            WBs_CYC_QL_Reserved  ;

wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_UART       ;
//wire            WBs_ACK_QL_Reserved  ;


wire    [31:0]  WBs_DAT_o_FPGA_Reg ; 
wire    [15:0]  WBs_DAT_o_UART     ;
wire    [31:0]  WBs_DMA_REG_DAT    ; 
wire    [31:0]  WBs_DMA_FIFO_DAT   ;
//wire    [31:0]  WBs_DAT_o_QL_Reserved;


//------Logic Operations---------------
//


// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_DMA_Reg    = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== DMA_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                                & (  WBs_CYC                                                                            );
								
assign WBs_CYC_DMA_Data   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== DMA0_DPORT_BASE_ADDR	[APERWIDTH-1:APERSIZE+2] )	
                                & (  WBs_CYC                                                                            );
								
assign WBs_CYC_UART         = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 

//assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
//                            & (  WBs_CYC  																				);


// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg | WBs_ACK_UART ;
                            //|    WBs_ACK_QL_Reserved;


// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg    or
		 WBs_DAT_o_UART        or
		 WBs_DMA_REG_DAT       or
		 WBs_DMA_FIFO_DAT      or
         //WBs_DAT_o_QL_Reserved or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    WBs_DAT_o_FPGA_Reg   	;
	UART_BASE_ADDRESS        [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    {16'h0, WBs_DAT_o_UART};
	DMA_REG_BASE_ADDR        [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    WBs_DMA_REG_DAT   		;
	DMA0_DPORT_BASE_ADDR     [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=    WBs_DMA_FIFO_DAT  		;
    //QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_QL_Reserved  ;
	default:                                           WBs_RD_DAT  <=    DEFAULT_READ_VALUE     ;
	endcase
end


//------Instantiate Modules------------
//

// Define the FPGA I/O Pad Signals
//
// Note: Use the Constraint manager in SpDE to assign these buffers to FBIO pads.
//


// General FPGA Resources 
//
AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FPGA_REG_ID_VALUE_ADR   	( FPGA_REG_ID_VALUE_ADR     	),
    .FPGA_REV_NUM_ADR   		( FPGA_REV_NUM_ADR    			),
	.FPGA_FIFO_RST_ADR   		( FPGA_FIFO_RST_ADR     		),
	.FPGA_SENSOR_EN_REG_ADR   	( FPGA_SENSOR_EN_REG_ADR    	),
	.FPGA_SEN1_SETTING_ADR   	( FPGA_SEN1_SETTING_ADR     	),
	.FPGA_SEN2_SETTING_ADR   	( FPGA_SEN2_SETTING_ADR			),
	.FPGA_SEN3_SETTING_ADR   	( FPGA_SEN3_SETTING_ADR     	),
	.FPGA_SEN4_SETTING_ADR   	( FPGA_SEN4_SETTING_ADR     	),
	.FPGA_TIMER_CNT_REG_ADR   	( FPGA_TIMER_CNT_REG_ADR    	),
	.FPGA_TIMER_EN_REG_ADR   	( FPGA_TIMER_EN_REG_ADR     	),
	
	.FPGA_DBG1_REG_ADR   		( FPGA_DBG1_REG_ADR   			),
	.FPGA_DBG2_REG_ADR   		( FPGA_DBG2_REG_ADR   			),
	.FPGA_DBG3_REG_ADR   		( FPGA_DBG3_REG_ADR   			),
	
	.FABRIC_GPIO_IN_REG_ADR     ( FABRIC_GPIO_IN_REG_ADR      	),
    .FABRIC_GPIO_OUT_REG_ADR    ( FABRIC_GPIO_OUT_REG_ADR     	),
    .FABRIC_GPIO_OE_REG_ADR     ( FABRIC_GPIO_OE_REG_ADR      	),
		
	.DMA_EN_REG_ADR   			( DMA_EN_REG_ADR     			),
	.DMA_STS_REG_ADR   			( DMA_STS_REG_ADR     			),
	.DMA_INTR_EN_REG_ADR     	( DMA_INTR_EN_REG_ADR	    	),

    .AL4S3B_DEVICE_ID           ( AL4S3B_DEVICE_ID              ),
    .AL4S3B_REV_LEVEL           ( AL4S3B_REV_LEVEL              ),
    .AL4S3B_GPIO_REG            ( AL4S3B_GPIO_REG               ),
    .AL4S3B_GPIO_OE_REG         ( AL4S3B_GPIO_OE_REG            ),
    .AL4S3B_SCRATCH_REG         ( AL4S3B_SCRATCH_REG            ),

    .AL4S3B_DEF_REG_VALUE       ( AL4S3B_DEF_REG_VALUE          )
                                                                )

     u_AL4S3B_FPGA_Registers 
	                           ( 
    // AHB-To_FPGA Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_FAB_REG+1:2] ),
    .WBs_CYC_i                 ( WBs_CYC_FPGA_Reg               ),
	.WBs_CYC_DMA_REG_i         ( WBs_CYC_DMA_Reg                ), 
	.WBs_CYC_DMA_DAT_i         ( WBs_CYC_DMA_Data               ),
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_DAT_o_FPGA_Reg           	),
    .WBs_ACK_o                 ( WBs_ACK_FPGA_Reg             	), 
	
	.WBs_DMA_REG_o             ( WBs_DMA_REG_DAT 				),
	.WBs_DMA_DAT_o             ( WBs_DMA_FIFO_DAT 				),

    //
    // Sensor settings
	.Sensor_Enable_o           ( Sensor_Enable	             	),  
	//.Sensor_1_Config_o         ( Sensor_1_Config             	), 
	//.Sensor_2_Config_o         ( Sensor_2_Config             	),  
	//.Sensor_3_Config_o         ( Sensor_3_Config             	), 
	//.Sensor_4_Config_o         ( Sensor_4_Config             	), 
	
	.SPI_clk_i                 ( spi_clk                        ),
	.Sensor_RD_Data_i          ( Sensor_RD_Data             	), 
	.Sensor_RD_Push_i          ( Sensor_RD_Push             	), 
	.rx_fifo_full_o            ( rx_fifo_full                   ),
	
    // Timer settings
	//.Timer_Count_o             ( Timer_Count	             	),  
	//.Timer_Enable_o            ( Timer_Enable	             	),
	
    //DMA
	.DMA0_Clr_i                ( DMA0_Clr 	 					),
	.DMA0_Done_i               ( DMA_Done_i     				),
	.DMA0_Start_o              ( DMA0_Start  					),
	.DMA_Active_i			   ( DMA_Active_i       		    ), 
	.DMA_REQ_i				   ( DMA_Req_o           		    ),
	.DMA_Enable_o			   ( DMA_Enable						),
	
							
	.DMA0_Done_IRQ_o           ( INTR_o             			),  
	
	.dbg_reset_o           	   ( dbg_reset             			), 
	
	.fsm_top_st_i              ( fsm_top_st			            ), 
	.spi_fsm_st_i              ( spi_fsm_st			            ),
	
	.GPIO_IN_i                 ( GPIO_In                        ),
	.GPIO_OUT_o                ( GPIO_Out                       ),
	.GPIO_OE_o                 ( GPIO_oe                        ),
	
    .Device_ID_o               ( Device_ID_o                    )

    );
	
	 
Dma_Ctrl u_Dma_Ctrl
	( 
	.clk_i					   ( WB_CLK     					),
	.rst_i					   ( WB_RST     					),
	
	.trig_i	            	   ( DMA0_Start						),    
	
	.DMA_Active_i			   ( DMA_Active_i       			),	
	.ASSP_DMA_Done_i		   ( DMA_Done_i    	    			),					
	.DMA_Done_o				   (  								),		
	.DMA_Clr_o				   ( DMA0_Clr						),	
	.DMA_Enable_i			   ( DMA_Enable 					),
	.DMA_REQ_o				   ( DMA_Req_o         			   )	  	 				
     );

/*	 
Timer     u_Timer
	(
     //
    .clk_i                     ( CLK_IP_i                       ),  
    .rst_i                     ( RST_IP_i                       ),

    .timer_count_i             ( Timer_Count					),
    .timer_enable_i     	   ( Timer_Enable          		 	),
    .fsm_run_o                 ( fsm_run             			)
    );
*/	
	
Fsm_Top     u_Fsm_Top
					(
     //
    //.clk_i                     ( CLK_IP_i                        ),  
    //.rst_i                     ( RST_IP_i                        ),
	.clk_i                     ( WB_CLK	                         ),  
    .rst_i                     ( WB_RST                          ),

    //.fsm_run_i                 ( fsm_run						),
	//.timer_enable_i            ( Timer_Enable					),
	
    .sensor_enable_i   		   ( Sensor_Enable         		 	),
    //.sensor_1_config_i         ( Sensor_1_Config                ),
    //.sensor_2_config_i         ( Sensor_2_Config                ),
	//.sensor_3_config_i         ( Sensor_3_Config                ),
	//.sensor_4_config_i         ( Sensor_4_Config                ),
	
	//.convst_o                  ( CONVST_o                       ),
	//.busy_i                    ( BUSY_i			                ),	
	
	.fsm_top_st_o              ( fsm_top_st			            ),
	
	//.sensor_wr_dat_o           ( sensor_wr_dat                  ),
    .spi_start_o               ( spi_start          			),
	.spi_rden_o                ( spi_rden          				),
	.spi_tfer_done_i           ( spi_tfer_done         			)
    );	
	
Serializer_Deserializer     u_Serializer_Deserializer
					(
     //
    //.clk_i                     ( CLK_IP_i                       ),  
    //.rst_i                     ( RST_IP_i                       ),
	.clk_i                     ( WB_CLK                         ),  
    .rst_i                     ( WB_RST                         ),

	//.sensor_wr_dat_i           ( sensor_wr_dat					),
    .spi_start_i               ( spi_start						),
	.spi_rden_i                ( spi_rden          				),
	.spi_tfer_done_o           ( spi_tfer_done					),
	
    .spi_ss_o        		   ( CSn_o               		 	),
    .spi_sck_o                 ( SCLK_o			                ), 
    .spi_mosi_o                (    			                ),
	.spi_miso_i         	   ( SDATA_i		                ), 
	
	.spi_fsm_st_o         	   ( spi_fsm_st		                ),
	
	.spi_clk_o         	       ( spi_clk    	                ),
	
	.rx_fifo_full_i            ( rx_fifo_full                   ),
    .Sensor_RD_Data_o          ( Sensor_RD_Data             	), 
	.Sensor_RD_Push_o          ( Sensor_RD_Push             	)
    );	
	
Serializer_Deserializer_Test     u_Serializer_Deserializer_Test
					(
	.clk_i                     ( WB_CLK                         ),  
    .rst_i                     ( dbg_reset                      ),


    .count_up_i                ( spi_tfer_done					),
	
    .spi_ss_i        		   ( spi_ss_i              		 	),
    .spi_sck_i                 ( spi_sck_i		                ), 
    .spi_miso_o                ( spi_miso_o		                )

    );	
	
// Serial Port
//
UART_16550 u_UART_16550        
                               ( 
    // AHB-To_Fabric Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[5:2]                   ),
    .WBs_CYC_i                 ( WBs_CYC_UART                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT[7:0]                ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_DAT_o_UART                 ),
    .WBs_ACK_o                 ( WBs_ACK_UART                   ),

	.SIN_i                     ( SIN_i                          ),
	.SOUT_o                    ( SOUT_o                         ),

	.INTR_o                    ( UART_Intr_o                    )
                                                                );
																
// GPIO
//
bipad u_bipad_I0    ( .A( GPIO_Out[0]   ), .EN( GPIO_oe[0]       ), .Q( GPIO_In[0]    ), .P( GPIO_PIN[0]  ) );
bipad u_bipad_I1    ( .A( GPIO_Out[1]   ), .EN( GPIO_oe[1]       ), .Q( GPIO_In[1]    ), .P( GPIO_PIN[1]  ) );
bipad u_bipad_I2    ( .A( GPIO_Out[2]   ), .EN( GPIO_oe[2]       ), .Q( GPIO_In[2]    ), .P( GPIO_PIN[2]  ) );
bipad u_bipad_I3    ( .A( GPIO_Out[3]   ), .EN( GPIO_oe[3]       ), .Q( GPIO_In[3]    ), .P( GPIO_PIN[3]  ) );

//pragma attribute u_bipad_I0                  preserve_cell true
//pragma attribute u_bipad_I1                  preserve_cell true 
//pragma attribute u_bipad_I2                  preserve_cell true
//pragma attribute u_bipad_I3                  preserve_cell true
	
// Reserved Resources Block
//
// Note: This block should be used in each QL FPGA design
//
/*
AL4S3B_FPGA_QL_Reserved     #(

    .ADDRWIDTH                 ( ADDRWIDTH_QL_RESERVED          ),
    .DATAWIDTH                 ( DATAWIDTH_QL_RESERVED          ),

    .QL_RESERVED_CUST_PROD_ADR ( QL_RESERVED_CUST_PROD_ADR      ),
    .QL_RESERVED_REVISIONS_ADR ( QL_RESERVED_REVISIONS_ADR      ),

    .QL_RESERVED_CUSTOMER_ID   ( QL_RESERVED_CUSTOMER_ID        ),
    .QL_RESERVED_PRODUCT_ID    ( QL_RESERVED_PRODUCT_ID         ),
    .QL_RESERVED_MAJOR_REV     ( QL_RESERVED_MAJOR_REV          ),
    .QL_RESERVED_MINOR_REV     ( QL_RESERVED_MINOR_REV          ),
    .QL_RESERVED_DEF_REG_VALUE ( QL_RESERVED_DEF_REG_VALUE      ),

    .DEFAULT_CNTR_WIDTH        ( DEFAULT_CNTR_WIDTH             ),
    .DEFAULT_CNTR_TIMEOUT      ( DEFAULT_CNTR_TIMEOUT           )
                                                                )	
                                 u_AL4S3B_FPGA_QL_Reserved
							   (
     // AHB-To_FPGA Bridge I/F
     //
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),

    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_FAB_REG+1:2] ),
    .WBs_CYC_QL_Reserved_i     ( WBs_CYC_QL_Reserved            ),
    .WBs_CYC_i                 ( WBs_CYC                        ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_o                 ( WBs_DAT_o_QL_Reserved          ),
    .WBs_ACK_i                 ( WBs_ACK                        ),
    .WBs_ACK_o                 ( WBs_ACK_QL_Reserved            )

                                                                );

*/


endmodule
