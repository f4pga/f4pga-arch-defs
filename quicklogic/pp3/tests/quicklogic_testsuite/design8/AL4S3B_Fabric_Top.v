// -----------------------------------------------------------------------------
// title          : AL4S3B Example Fabric IP Top Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_Fabric_top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/Oct/10	
// last update    : 2017/Oct/10
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The Fabric example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to IP located in the 
//              programmable fabric.
// -----------------------------------------------------------------------------
// copyright (c) 2017
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author          description
// 2017/Oct/10      1.0       Anand Wadke     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
//`define ENAB_I2C_Master_w_CmdQueue_inst
//`define ENAB_GPIO_INT

module top ( 
`ifdef ENAB_GPIO_INT
                GPIO_PIN,
`endif				

			//OV7670 VGA Signal
            PCLK_i,
            VSYNC_i,
            HREF_HSYNC_i,
            RGB_DAT_i,	

            OV7670_RST_n_o,
            OV7670_XCLK_o,
			OV7670_PWDN_o,
             			






`ifdef ENAB_I2C_Master_w_CmdQueue_inst
                I2C_SCL,
                I2C_SDA,
                I2C_SCL_SEN,
                I2C_SDA_SEN,
`endif				
                SIN,
                SOUT


				
		
				
				
				//CLK_4MHZ_OUT,
				//CLK_1MHZ_OUT

                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

parameter       FABRIC_REG_BASE_ADDRESS     	= 17'h00000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       IN_FRM_SAMP_VGA_BASE_ADDRESS        	= 17'h00800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       UART_BASE_ADDRESS           	= 17'h01000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       QL_RESERVED_BASE_ADDRESS        = 17'h01800     ; // Assumes 128K Byte Fabric Memory Aperture

`ifdef ENAB_I2C_Master_w_CmdQueue_inst
parameter       I2C_BUS_BASE_ADDRESS        	= 17'h00800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       CQ_REG_BUS_BASE_ADDRESS     = 17'h01800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       CQ_TXFIFO_BUS_BASE_ADDRESS  = 17'h02000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       LCD_REG_BUS_BASE_ADDRESS    = 17'h02800     ; // Assumes 128K Byte Fabric Memory Aperture  
parameter       LCD_SRAM_BUS_BASE_ADDRESS   = 17'h03000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       I2C_BUS_SEN_BASE_ADDRESS    = 17'h04000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       QL_RESERVED_BASE_ADDRESS    = 17'h04800     ; // Assumes 128K Byte Fabric Memory Aperture
`endif

//parameter       IN_FRM_SAMP_VGA_BASE_ADDRESS    	= 17'h05000     ; // Assumes 128K Byte Fabric Memory Aperture

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;
parameter       FABRIC_REG_ID_VALUE_ADR     =  7'h0         ; 
parameter       FABRIC_CLOCK_CONTROL_ADR    =  7'h1         ; 
parameter       FABRIC_GPIO_IN_REG_ADR      =  7'h2         ; 
parameter       FABRIC_GPIO_OUT_REG_ADR     =  7'h3         ; 
parameter       FABRIC_GPIO_OE_REG_ADR      =  7'h4         ; 
parameter       FABRIC_REG_SCRATCH_REG_ADR  =  7'h5         ; 

parameter       AL4S3B_DEVICE_ID            = 16'h0         ;
parameter       AL4S3B_REV_LEVEL            = 32'h0         ;
parameter       AL4S3B_GPIO_REG             = 22'h0         ;
parameter       AL4S3B_GPIO_OE_REG          = 22'h0         ;
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       ADDRWIDTH_CQ_REG            =  10            ;
parameter       DATAWIDTH_CQ_REG            = 32            ;

parameter       I2C_DEFAULT_READ_VALUE      = 32'hBAD_12C_AC;

parameter       CQ_STATUS_REG_ADR           =  7'h0         ;
parameter       CQ_CONTROL_REG_ADR          =  7'h1         ;
parameter       CQ_FIFO_LEVEL_REG_ADR       =  7'h2         ;

parameter       CQ_CNTL_DEF_REG_VALUE       = 32'hC0C_DEF_AC; // Distinguish access to undefined area
parameter       CQ_FIFO_DEF_REG_VALUE       = 32'hF1F_DEF_AC; // Distinguish access to undefined area

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC;
parameter       DEFAULT_CNTR_WIDTH          =  3            ;
parameter       DEFAULT_CNTR_TIMEOUT        =  7            ;

parameter       ADDRWIDTH_QL_RESERVED       =  7            ;
parameter       DATAWIDTH_QL_RESERVED       = 32            ;

parameter       QL_RESERVED_CUST_PROD_ADR   =  7'h7E        ;  // <<-- Very Top of the Fabric's Memory Aperture
parameter       QL_RESERVED_REVISIONS_ADR   =  7'h7F        ;  // <<-- Very Top of the Fabric's Memory Aperture

parameter       QL_RESERVED_CUSTOMER_ID     =  8'h01        ;  // <<-- Update for each Customer
parameter       QL_RESERVED_PRODUCT_ID      =  8'h00        ;  // <<-- Update for each Customer Product
parameter       QL_RESERVED_MAJOR_REV       = 16'h0000      ;  // <<-- Update for each Major Revision (i.e. Rev 1,    Rev 2,    etc.)
parameter       QL_RESERVED_MINOR_REV       = 16'h0001      ;  // <<-- Update for each Minor Revision (i.e. Rev 1.01, Rev 1.02, etc.)

parameter       QL_RESERVED_DEF_REG_VALUE   = 32'hDEF_FAB_AC; // Distinguish access to undefined area

parameter       ADDRWIDTH_JDILCD_REG           =  10            ;
parameter       DATAWIDTH_JDILCD_REG           = 32            ;

//Parameters
parameter       IN_VGA_STATUS_REG_ADDR 		   = 5'h0 ;	
parameter       IN_VGA_CONTROL_REG_ADR		   = 5'h1 ;
parameter       IN_VGA_RX_FIFO_DATCNT_REG_ADR	   = 5'h2 ;
parameter       IN_VGA_RX_FIFO_LINECNT_REG_ADR   = 5'h3 ;
parameter       IN_VGA_DMA_CONTROL_REG_ADR	   = 5'h4 ;
parameter       IN_VGA_DMA_STATUS_REG_ADR	       = 5'h5 ;
parameter       IN_VGA_RGB_RXDATA_REG_ADR	       = 5'h6 ;
parameter       IN_VGA_DEBUG_REG_ADR	       	   = 5'h7 ;

                                            
parameter       IN_VGA_DEF_REG_VALUE	= 32'hC0C_DEF_AC; // Distinguish access to undefined area






//------Port Signals-------------------
//

// GPIO
//
`ifdef ENAB_GPIO_INT
inout  [21:0]   GPIO_PIN       ;
`endif

// I2C Master - Command Queue with DMA
//
`ifdef ENAB_I2C_Master_w_CmdQueue_inst
inout           I2C_SCL        ;
inout           I2C_SDA        ;
// I2C Master - Sensor with DMA
//
inout           I2C_SCL_SEN    ;
inout           I2C_SDA_SEN    ;
`endif
// UART
//
input           SIN            ;
output          SOUT           ;


input 			PCLK_i;
input 			VSYNC_i;
input 			HREF_HSYNC_i;
input 	[7:0]	RGB_DAT_i;	


output			OV7670_RST_n_o;
output			OV7670_XCLK_o;
output			OV7670_PWDN_o;
	


//SPI M

// clock pins added /4
//output 			CLK_4MHZ_OUT;
//output			CLK_1MHZ_OUT;

//
//GPIO
//
wire   [21:0]   GPIO_PIN       ;

//
// I2C Master - Command Queue with DMA
//
wire            I2C_SCL        ;
wire            I2C_SDA        ;

// UART
//
wire            SIN            ;
wire            SOUT           ;

//
// I2C Master - Sensor with DMA
//
wire            I2C_SCL_SEN    ;
wire            I2C_SDA_SEN    ;



//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

// Fabric Global Signals
//
wire            WB_CLK         ; // Selected Fabric Clock

wire            Sys_Clk0       ; // Selected Fabric Clock
wire            Sys_Clk0_Rst   ; // Selected Fabric Reset

wire            Sys_Clk1       ; // Selected Fabric Clock
wire            Sys_Clk1_Rst   ; // Selected Fabric Reset

// Wishbone Bus Signals
//
wire    [16:0]  WBs_ADR        ; // Wishbone Address Bus
wire            WBs_CYC        ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire     [3:0]  WBs_BYTE_STB   ; // Wishbone Byte   Enables
wire            WBs_WE         ; // Wishbone Write  Enable Strobe
wire            WBs_RD         ; // Wishbone Read   Enable Strobe
wire            WBs_STB        ; // Wishbone Transfer      Strobe
wire    [31:0]  WBs_RD_DAT     ; // Wishbone Read   Data Bus
wire    [31:0]  WBs_WR_DAT     ; // Wishbone Write  Data Bus
wire            WBs_ACK        ; // Wishbone Client Acknowledge
wire            WB_RST         ; // Wishbone Fabric Reset
wire            WB_RST_fabric  ; // Wishbone Fabric Reset

// Misc
//
wire    [23:0]  Device_ID      ;

//old
wire            i2c_Sen_Intr   ;
wire            UART_Intr      ;
wire            i2c_Intr       ;
wire            CQ_Intr        ;
wire			LCD_DMA_Intr   ;
wire            CQ_I2C_Intr    ;


wire     		SDMA_Req_Sen   ;
wire    		SDMA_Sreq_Sen  ;
wire     	    SDMA_Done_Sen  ;
wire            SDMA_Active_Sen;


wire            SDMA_Req_CQ    ;
wire            SDMA_Sreq_CQ   ;
wire            SDMA_Done_CQ   ;
wire            SDMA_Active_CQ ;
//

wire    [1:0]   SDMA_Done_Extra  ;
wire    [1:0]   SDMA_Active_Extra;

wire    		VGA_Intr		;		
wire    		VGA_DMA_Intr	;
                
wire    		SDMA_Req_VGA	;
wire    		SDMA_Sreq_VGA	;
wire    		SDMA_Done_VGA	;
wire    		SDMA_Active_VGA	;



//reg		[1:0]   clk_div;

wire			CLK_32K; 
wire			RST_fb1; 

wire      		ov7670_pwdn_sig;       

//In VGA.
assign OV7670_RST_n_o   = ~Sys_Clk0_Rst;
assign OV7670_XCLK_o  = Sys_Clk0;
assign OV7670_PWDN_o  = 1'b0;


//------Logic Operations---------------
//

// Determine the fabric reset
//
// Note: Reset the fabric IP on either the AHB or clock domain reset signals.
//
gclkbuff u_gclkbuff_reset ( .A(Sys_Clk0_Rst | WB_RST) , .Z(WB_RST_fabric) );
gclkbuff u_gclkbuff_clock ( .A(Sys_Clk0             ) , .Z(WB_CLK       ) );

gclkbuff u_gclkbuff_reset1 ( .A(Sys_Clk1_Rst) , .Z(RST_fb1) );
gclkbuff u_gclkbuff_clock1  ( .A(Sys_Clk1   ) , .Z(CLK_32K ) );

//------Instantiate Modules------------

// Example Fabric Design
//
AL4S3B_Fabric_IP              #(
	
    .APERWIDTH                 ( APERWIDTH                   ),
    .APERSIZE                  ( APERSIZE                    ),

    .FABRIC_REG_BASE_ADDRESS   ( FABRIC_REG_BASE_ADDRESS     ),
    .IN_FRM_SAMP_VGA_BASE_ADDRESS    ( IN_FRM_SAMP_VGA_BASE_ADDRESS    ),	
	.UART_BASE_ADDRESS         ( UART_BASE_ADDRESS           ),
    .QL_RESERVED_BASE_ADDRESS  ( QL_RESERVED_BASE_ADDRESS    ),
	
`ifdef ENAB_I2C_Master_w_CmdQueue_inst	
    .I2C_BUS_BASE_ADDRESS      ( I2C_BUS_BASE_ADDRESS        ),
    .CQ_REG_BUS_BASE_ADDRESS   ( CQ_REG_BUS_BASE_ADDRESS     ),
    .CQ_TXFIFO_BUS_BASE_ADDRESS( CQ_TXFIFO_BUS_BASE_ADDRESS  ),
	.LCD_REG_BUS_BASE_ADDRESS  ( LCD_REG_BUS_BASE_ADDRESS  	 ),
	.LCD_SRAM_BUS_BASE_ADDRESS ( LCD_SRAM_BUS_BASE_ADDRESS    ),
    .I2C_BUS_SEN_BASE_ADDRESS  ( I2C_BUS_SEN_BASE_ADDRESS    ),
`endif	



	.ADDRWIDTH_FAB_REG         ( ADDRWIDTH_FAB_REG           ),
    .DATAWIDTH_FAB_REG         ( DATAWIDTH_FAB_REG           ),
    .FABRIC_REG_ID_VALUE_ADR   ( FABRIC_REG_ID_VALUE_ADR     ),
    .FABRIC_CLOCK_CONTROL_ADR  ( FABRIC_CLOCK_CONTROL_ADR    ),
    .FABRIC_GPIO_IN_REG_ADR    ( FABRIC_GPIO_IN_REG_ADR      ),
    .FABRIC_GPIO_OUT_REG_ADR   ( FABRIC_GPIO_OUT_REG_ADR     ),
    .FABRIC_GPIO_OE_REG_ADR    ( FABRIC_GPIO_OE_REG_ADR      ),
    .FABRIC_REG_SCRATCH_REG_ADR( FABRIC_REG_SCRATCH_REG_ADR  ),

    .AL4S3B_DEVICE_ID          ( AL4S3B_DEVICE_ID            ),
    .AL4S3B_REV_LEVEL          ( AL4S3B_REV_LEVEL            ),
    .AL4S3B_GPIO_REG           ( AL4S3B_GPIO_REG             ),
    .AL4S3B_GPIO_OE_REG        ( AL4S3B_GPIO_OE_REG          ),
    .AL4S3B_SCRATCH_REG        ( AL4S3B_SCRATCH_REG          ),

    .AL4S3B_DEF_REG_VALUE      ( AL4S3B_DEF_REG_VALUE        ),

    .ADDRWIDTH_CQ_REG          ( ADDRWIDTH_CQ_REG            ),
    .DATAWIDTH_CQ_REG          ( DATAWIDTH_CQ_REG            ),

    .I2C_DEFAULT_READ_VALUE    ( I2C_DEFAULT_READ_VALUE      ),

    .CQ_STATUS_REG_ADR         ( CQ_STATUS_REG_ADR           ),
    .CQ_CONTROL_REG_ADR        ( CQ_CONTROL_REG_ADR          ),
    .CQ_FIFO_LEVEL_REG_ADR     ( CQ_FIFO_LEVEL_REG_ADR       ),

    .CQ_CNTL_DEF_REG_VALUE     ( CQ_CNTL_DEF_REG_VALUE       ),
    .CQ_FIFO_DEF_REG_VALUE     ( CQ_FIFO_DEF_REG_VALUE       ),

    .DEFAULT_READ_VALUE        ( DEFAULT_READ_VALUE          ),
    .DEFAULT_CNTR_WIDTH        ( DEFAULT_CNTR_WIDTH          ),
    .DEFAULT_CNTR_TIMEOUT      ( DEFAULT_CNTR_TIMEOUT        ),

    .ADDRWIDTH_QL_RESERVED     ( ADDRWIDTH_QL_RESERVED       ),
    .DATAWIDTH_QL_RESERVED     ( DATAWIDTH_QL_RESERVED       ),

    .QL_RESERVED_CUST_PROD_ADR ( QL_RESERVED_CUST_PROD_ADR   ),
    .QL_RESERVED_REVISIONS_ADR ( QL_RESERVED_REVISIONS_ADR   ),

    .QL_RESERVED_CUSTOMER_ID   ( QL_RESERVED_CUSTOMER_ID     ),
    .QL_RESERVED_PRODUCT_ID    ( QL_RESERVED_PRODUCT_ID      ),
    .QL_RESERVED_MAJOR_REV     ( QL_RESERVED_MAJOR_REV       ),
    .QL_RESERVED_MINOR_REV     ( QL_RESERVED_MINOR_REV       ),

    .QL_RESERVED_DEF_REG_VALUE ( QL_RESERVED_DEF_REG_VALUE   ),
	
	.IN_VGA_STATUS_REG_ADDR 			( IN_VGA_STATUS_REG_ADDR 			),			 	 
	.IN_VGA_CONTROL_REG_ADR		    ( IN_VGA_CONTROL_REG_ADR		    ),
	.IN_VGA_RX_FIFO_DATCNT_REG_ADR	( IN_VGA_RX_FIFO_DATCNT_REG_ADR	),  
	.IN_VGA_RX_FIFO_LINECNT_REG_ADR   ( IN_VGA_RX_FIFO_LINECNT_REG_ADR  ),
	.IN_VGA_DMA_CONTROL_REG_ADR	    ( IN_VGA_DMA_CONTROL_REG_ADR	    ),
	.IN_VGA_DMA_STATUS_REG_ADR	    ( IN_VGA_DMA_STATUS_REG_ADR	    ),  
	.IN_VGA_RGB_RXDATA_REG_ADR	    ( IN_VGA_RGB_RXDATA_REG_ADR	    ),  
	.IN_VGA_DEBUG_REG_ADR	       	    ( IN_VGA_DEBUG_REG_ADR	       	), 
        
    .IN_VGA_DEF_REG_VALUE  	( IN_VGA_DEF_REG_VALUE	)
	

                                                             )

     u_AL4S3B_Fabric_IP        (

	// AHB-To_Fabric Bridge I/F
	//
	.CLK_32K_i				   ( CLK_32K					 ),  
	.RST_fb_i				   ( RST_fb1   					 ),
	
    .WBs_ADR                   ( WBs_ADR                     ), // input  [16:0] | Address Bus                to   Fabric
    .WBs_CYC                   ( WBs_CYC                     ), // input         | Cycle Chip Select          to   Fabric
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // input   [3:0] | Byte Select                to   Fabric
    .WBs_WE                    ( WBs_WE                      ), // input         | Write Enable               to   Fabric
    .WBs_RD                    ( WBs_RD                      ), // input         | Read  Enable               to   Fabric
    .WBs_STB                   ( WBs_STB                     ), // input         | Strobe Signal              to   Fabric
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // input  [31:0] | Write Data Bus             to   Fabric
    .WB_CLK                    ( WB_CLK                      ), // output        | Fabric Clock               from Fabric
    .WB_RST                    ( WB_RST_fabric               ), // input         | Fabric Reset               to   Fabric
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // output [31:0] | Read Data Bus              from Fabric
    .WBs_ACK                   ( WBs_ACK                     ), // output        | Transfer Cycle Acknowledge from Fabric

    //
    // GPIO
    //
`ifdef ENAB_GPIO_INT	
    .GPIO_PIN                  ( GPIO_PIN                    ),
`endif

    //
    // Misc
    //
	.CLK_4M_CNTL_o             ( CLK_4M_CNTL                  ),
	.CLK_1M_CNTL_o             ( CLK_1M_CNTL                  ),
		
    .Device_ID                 ( Device_ID                   ), // output [15:0]

    // UART
    //
    .SIN                       ( SIN                         ),
    .SOUT                      ( SOUT                        ),

    //
    // I2C Master - Sensor with DMA
    //
    .I2C_SCL_SEN               ( I2C_SCL_SEN                 ),
    .I2C_SDA_SEN               ( I2C_SDA_SEN                 ),
	
	.UART_Intr_o               ( UART_Intr                   ),
	
`ifdef ENAB_I2C_Master_w_CmdQueue_inst	

    .i2c_Sen_Intr_o            ( i2c_Sen_Intr                ),
    .i2c_Intr_o                ( i2c_Intr                    ),
    .CQ_Intr_o                 ( CQ_Intr                     ),
	.LCD_DMA_Intr_o            ( LCD_DMA_Intr                ),
    .SDMA_Req_Sen_o            ( SDMA_Req_Sen                ),
    .SDMA_Sreq_Sen_o           ( SDMA_Sreq_Sen               ),
    .SDMA_Done_Sen_i           ( SDMA_Done_Sen               ),
    .SDMA_Active_Sen_i         ( SDMA_Active_Sen             ),
    .SDMA_Req_CQ_o             ( SDMA_Req_CQ                 ),
    .SDMA_Sreq_CQ_o            ( SDMA_Sreq_CQ                ),
    .SDMA_Done_CQ_i            ( SDMA_Done_CQ                ),
    .SDMA_Active_CQ_i          ( SDMA_Active_CQ              ),
`endif	
	
	.VGA_Intr_o		      	   (	VGA_Intr			),
	.VGA_DMA_Intr_o	           (	VGA_DMA_Intr	        ),
                                                   
	
	.SDMA_Req_VGA_o		        ( SDMA_Req_VGA	            ),	
	.SDMA_Sreq_VGA_o		    ( SDMA_Sreq_VGA	            ),	
	.SDMA_Done_VGA_i		    ( SDMA_Done_VGA	            ),	
	.SDMA_Active_VGA_i	        ( SDMA_Active_VGA           ),							
	                                        			
    
	.PCLK_i    					(PCLK_i    		),
	.VSYNC_i    				(VSYNC_i    	),
	.HREF_HSYNC_i    			(HREF_HSYNC_i   ),
	.RGB_DAT_i    				(RGB_DAT_i   	)


	);
															 
assign CQ_I2C_Intr = i2c_Intr | CQ_Intr;


// Empty Verilog model of QLAL4S3B
//
qlal4s3b_cell_macro              u_qlal4s3b_cell_macro
                               (
    // AHB-To-Fabric Bridge
	//
    .WBs_ADR                   ( WBs_ADR                     ), // output [16:0] | Address Bus                to   Fabric
    .WBs_CYC                   ( WBs_CYC                     ), // output        | Cycle Chip Select          to   Fabric
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // output  [3:0] | Byte Select                to   Fabric
    .WBs_WE                    ( WBs_WE                      ), // output        | Write Enable               to   Fabric
    .WBs_RD                    ( WBs_RD                      ), // output        | Read  Enable               to   Fabric
    .WBs_STB                   ( WBs_STB                     ), // output        | Strobe Signal              to   Fabric
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // output [31:0] | Write Data Bus             to   Fabric
    .WB_CLK                    ( WB_CLK                      ), // input         | Fabric Clock               from Fabric
    .WB_RST                    ( WB_RST                      ), // output        | Fabric Reset               to   Fabric
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // input  [31:0] | Read Data Bus              from Fabric
    .WBs_ACK                   ( WBs_ACK                     ), // input         | Transfer Cycle Acknowledge from Fabric


`ifdef ENAB_I2C_Master_w_CmdQueue_inst	
    // SDMA Signals
    .SDMA_Req                  ({ 2'b00, SDMA_Req_CQ           ,
                                        SDMA_Req_Sen        }), // input   [3:0]
    .SDMA_Sreq                 ({ 2'b00, SDMA_Sreq_CQ          ,
                                        SDMA_Sreq_Sen       }), // input   [3:0]
    .SDMA_Done                 ({       SDMA_Done_Extra       ,
	                                    SDMA_Done_CQ          ,
                                        SDMA_Done_Sen       }), // output  [3:0]
    .SDMA_Active               ({       SDMA_Active_Extra     ,
                                        SDMA_Active_CQ        ,
                                        SDMA_Active_Sen     }), // output  [3:0]

    //
    // FB Interrupts
    //
    .FB_msg_out                ( {      i2c_Sen_Intr,
										//LCD_DMA_Intr,
                                        UART_Intr,
                                        //i2c_Intr,
										LCD_DMA_Intr,
                                        CQ_I2C_Intr            }), // input   [3:0]
`else
    // SDMA Signals
    .SDMA_Req                  ({ 3'b000,           
                                        SDMA_Req_VGA        }), // input   [3:0]
    .SDMA_Sreq                 ({ 3'b000, 
                                        SDMA_Sreq_VGA       }), // input   [3:0]
    .SDMA_Done                 ({       SDMA_Done_Extra       ,
	                                    SDMA_Done_CQ          ,
                                        SDMA_Done_VGA       }), // output  [3:0]
    .SDMA_Active               ({       SDMA_Active_Extra     ,
                                        SDMA_Active_CQ        ,
                                        SDMA_Active_VGA     }), // output  [3:0
// FB Interrupts
    .FB_msg_out                ( {      1'b0,
										//LCD_DMA_Intr,
                                        UART_Intr,
                                        //i2c_Intr,
										VGA_DMA_Intr,
                                        VGA_Intr            }), // input   [3:0]										
										
`endif										
										//CQ_Intr            }), // input   [3:0]
    .FB_Int_Clr                (  8'h0                       ), // input   [7:0]
    .FB_Start                  (                             ), // output
    .FB_Busy                   (  1'b0                       ), // input
    //
    // FB Clocks
    //
    .Sys_Clk0                  ( Sys_Clk0                    ), // output
    .Sys_Clk0_Rst              ( Sys_Clk0_Rst                ), // output
    .Sys_Clk1                  ( Sys_Clk1                    ), // output
    .Sys_Clk1_Rst              ( Sys_Clk1_Rst                ), // output
    //
    // Packet FIFO
    //
    .Sys_PKfb_Clk              (  1'b0                       ), // input
    .Sys_PKfb_Rst              (                             ), // output
    .FB_PKfbData               ( 32'h0                       ), // input  [31:0]
    .FB_PKfbPush               (  4'h0                       ), // input   [3:0]
    .FB_PKfbSOF                (  1'b0                       ), // input
    .FB_PKfbEOF                (  1'b0                       ), // input
    .FB_PKfbOverflow           (                             ), // output
	//
	// Sensor Interface
	//
    .Sensor_Int                (                             ), // output  [7:0]
    .TimeStamp                 (                             ), // output [23:0]
    //
    // SPI Master APB Bus
    //
    .Sys_Pclk                  (                             ), // output
    .Sys_Pclk_Rst              (                             ), // output      <-- Fixed to add "_Rst"
    .Sys_PSel                  (  1'b0                       ), // input
    .SPIm_Paddr                ( 16'h0                       ), // input  [15:0]
    .SPIm_PEnable              (  1'b0                       ), // input
    .SPIm_PWrite               (  1'b0                       ), // input
    .SPIm_PWdata               ( 32'h0                       ), // input  [31:0]
    .SPIm_Prdata               (                             ), // output [31:0]
    .SPIm_PReady               (                             ), // output
    .SPIm_PSlvErr              (                             ), // output
    //
    // Misc
    //
    .Device_ID                 ( Device_ID[19:4]             ), // input  [15:0]
    //
    // FBIO Signals
    //
    .FBIO_In                   (                             ), // output [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_In_En                (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_Out                  (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
    .FBIO_Out_En               (                             ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
	//
	// ???
	//
    .SFBIO                     (                             ), // inout  [13:0]
    .Device_ID_6S              ( 1'b0                        ), // input
    .Device_ID_4S              ( 1'b0                        ), // input
    .SPIm_PWdata_26S           ( 1'b0                        ), // input
    .SPIm_PWdata_24S           ( 1'b0                        ), // input
    .SPIm_PWdata_14S           ( 1'b0                        ), // input
    .SPIm_PWdata_11S           ( 1'b0                        ), // input
    .SPIm_PWdata_0S            ( 1'b0                        ), // input
    .SPIm_Paddr_8S             ( 1'b0                        ), // input
    .SPIm_Paddr_6S             ( 1'b0                        ), // input
    .FB_PKfbPush_1S            ( 1'b0                        ), // input
    .FB_PKfbData_31S           ( 1'b0                        ), // input
    .FB_PKfbData_21S           ( 1'b0                        ), // input
    .FB_PKfbData_19S           ( 1'b0                        ), // input
    .FB_PKfbData_9S            ( 1'b0                        ), // input
    .FB_PKfbData_6S            ( 1'b0                        ), // input
    .Sys_PKfb_ClkS             ( 1'b0                        ), // input
    .FB_BusyS                  ( 1'b0                        ), // input
    .WB_CLKS                   ( 1'b0                        )  // input
                                                             );

//pragma attribute u_qlal4s3b_cell_macro         preserve_cell true
//pragma attribute u_AL4S3B_Fabric_IP            preserve_cell true

endmodule
