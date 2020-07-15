// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Top Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_top.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/01	
// last update    : 2016/02/01
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to IP located in the 
//              programmable FPGA.
// -----------------------------------------------------------------------------
// copyright (c) 2015
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/02/01      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module top ( 

                GPIO_PIN,

                I2C_SCL,
                I2C_SDA,

                //SIN,
                //SOUT,

                //I2C_SCL_SEN,
                //I2C_SDA_SEN,
				
				CLK_4MHZ_OUT,
				CLK_1MHZ_OUT

                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

parameter       FPGA_REG_BASE_ADDRESS     = 17'h00000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       I2C_BUS_BASE_ADDRESS        = 17'h00800     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       UART_BASE_ADDRESS           = 17'h01000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       CQ_REG_BUS_BASE_ADDRESS     = 17'h01800     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       CQ_TXFIFO_BUS_BASE_ADDRESS  = 17'h02000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       LCD_REG_BUS_BASE_ADDRESS    = 17'h02800     ; // Assumes 128K Byte FPGA Memory Aperture  
parameter       LCD_SRAM_BUS_BASE_ADDRESS   = 17'h03000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       I2C_BUS_SEN_BASE_ADDRESS    = 17'h04000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       QL_RESERVED_BASE_ADDRESS    = 17'h04800     ; // Assumes 128K Byte FPGA Memory Aperture

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;
parameter       FPGA_REG_ID_VALUE_ADR     =  7'h0         ; 
parameter       FPGA_CLOCK_CONTROL_ADR    =  7'h1         ; 
parameter       FPGA_GPIO_IN_REG_ADR      =  7'h2         ; 
parameter       FPGA_GPIO_OUT_REG_ADR     =  7'h3         ; 
parameter       FPGA_GPIO_OE_REG_ADR      =  7'h4         ; 
parameter       FPGA_REG_SCRATCH_REG_ADR  =  7'h5         ; 

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

parameter       QL_RESERVED_CUST_PROD_ADR   =  7'h7E        ;  // <<-- Very Top of the FPGA's Memory Aperture
parameter       QL_RESERVED_REVISIONS_ADR   =  7'h7F        ;  // <<-- Very Top of the FPGA's Memory Aperture

parameter       QL_RESERVED_CUSTOMER_ID     =  8'h01        ;  // <<-- Update for each Customer
parameter       QL_RESERVED_PRODUCT_ID      =  8'h00        ;  // <<-- Update for each Customer Product
parameter       QL_RESERVED_MAJOR_REV       = 16'h0000      ;  // <<-- Update for each Major Revision (i.e. Rev 1,    Rev 2,    etc.)
parameter       QL_RESERVED_MINOR_REV       = 16'h0001      ;  // <<-- Update for each Minor Revision (i.e. Rev 1.01, Rev 1.02, etc.)

parameter       QL_RESERVED_DEF_REG_VALUE   = 32'hDEF_FAB_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// GPIO
//
inout  [7:0]   GPIO_PIN       ;

// I2C Master - Command Queue with DMA
//
inout           I2C_SCL        ;
inout           I2C_SDA        ;

// UART
//
//input           SIN            ;
//output          SOUT           ;

// I2C Master - Sensor with DMA
//
//inout           I2C_SCL_SEN    ;
//inout           I2C_SDA_SEN    ;

// clock pins added /4
output 			CLK_4MHZ_OUT;
output			CLK_1MHZ_OUT;


//
//GPIO
//
wire   [7:0]   GPIO_PIN       ;

//
// I2C Master - Command Queue with DMA
//
wire            I2C_SCL        ;
wire            I2C_SDA        ;

// UART
//
//wire            SIN            ;
//wire            SOUT           ;

//
// I2C Master - Sensor with DMA
//
//wire            I2C_SCL_SEN    ;
//wire            I2C_SDA_SEN    ;



//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

// FPGA Global Signals
//
wire            WB_CLK         ; // Selected FPGA Clock

wire            Sys_Clk0       ; // Selected FPGA Clock
wire            Sys_Clk0_Rst   ; // Selected FPGA Reset

wire            Sys_Clk1       ; // Selected FPGA Clock
wire            Sys_Clk1_Rst   ; // Selected FPGA Reset

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
wire            WB_RST         ; // Wishbone FPGA Reset
wire            WB_RST_FPGA  ; // Wishbone FPGA Reset

// Misc
//
wire    [23:0]  Device_ID      ;

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

wire    [1:0]   SDMA_Done_Extra  ;
wire    [1:0]   SDMA_Active_Extra;

reg		[1:0]   clk_div;

wire			CLK_4M;
wire			RST_fb1;

wire			CLK_4M_CNTL;
wire 			CLK_1M_CNTL;

reg				CLK_4M_CNTL_r1,CLK_4M_CNTL_r2;
reg				CLK_1M_CNTL_r1,CLK_1M_CNTL_r2;

reg			CLK_4M_ON;
reg			CLK_1M_ON;

wire        clk_1m;


//------Logic Operations---------------
//

// Determine the FPGA reset
//
// Note: Reset the FPGA IP on either the AHB or clock domain reset signals.
//
gclkbuff u_gclkbuff_reset ( .A(Sys_Clk0_Rst | WB_RST) , .Z(WB_RST_FPGA) );
gclkbuff u_gclkbuff_clock ( .A(Sys_Clk0             ) , .Z(WB_CLK       ) );

gclkbuff u_gclkbuff_reset1 ( .A(Sys_Clk1_Rst) , .Z(RST_fb1) );
gclkbuff u_gclkbuff_clock1  ( .A(Sys_Clk1   ) , .Z(CLK_4M ) );

//------Instantiate Modules------------
//
// clock div /4
assign CLK_4MHZ_OUT = CLK_4M & CLK_4M_ON;
assign clk_1m = clk_div[1];
assign CLK_1MHZ_OUT = clk_div[1] & CLK_1M_ON;

always @( posedge CLK_4M or posedge RST_fb1)
begin
    if (RST_fb1)
    begin
		clk_div	 	<= 2'b00;
    end  
    else
    begin
		clk_div  <=  clk_div + 1'b1 ;
    end  
end

always @( posedge CLK_4M or posedge RST_fb1)
begin
    if (RST_fb1)
    begin
		CLK_4M_CNTL_r1	 	<= 1'b0;
		CLK_4M_CNTL_r2	 	<= 1'b0;
    end  
    else
    begin
		CLK_4M_CNTL_r1	 	<= CLK_4M_CNTL;
		CLK_4M_CNTL_r2	 	<= CLK_4M_CNTL_r1;
    end  
end

always @( negedge CLK_4M or posedge RST_fb1) 
begin
    if (RST_fb1)
    begin
		CLK_4M_ON	 	<= 1'b0;
    end  
    else
    begin
		CLK_4M_ON		<= CLK_4M_CNTL_r2;
    end  
end

always @( posedge clk_1m or posedge RST_fb1)
begin
    if (RST_fb1)
    begin
		CLK_1M_CNTL_r1	 	<= 1'b0;
		CLK_1M_CNTL_r2	 	<= 1'b0;
    end  
    else
    begin
		CLK_1M_CNTL_r1	 	<= CLK_1M_CNTL;
		CLK_1M_CNTL_r2	 	<= CLK_1M_CNTL_r1;
    end  
end

always @( negedge clk_1m or posedge RST_fb1) 
begin
    if (RST_fb1)
    begin
		CLK_1M_ON	 	<= 1'b0;
    end  
    else
    begin
		CLK_1M_ON  <=  CLK_1M_CNTL_r2;
    end  
end

// Example FPGA Design
//
AL4S3B_FPGA_IP              #(
	
    .APERWIDTH                 ( APERWIDTH                   ),
    .APERSIZE                  ( APERSIZE                    ),

    .FPGA_REG_BASE_ADDRESS   ( FPGA_REG_BASE_ADDRESS     ),
    .I2C_BUS_BASE_ADDRESS      ( I2C_BUS_BASE_ADDRESS        ),
    .UART_BASE_ADDRESS         ( UART_BASE_ADDRESS           ),
    .CQ_REG_BUS_BASE_ADDRESS   ( CQ_REG_BUS_BASE_ADDRESS     ),
    .CQ_TXFIFO_BUS_BASE_ADDRESS( CQ_TXFIFO_BUS_BASE_ADDRESS  ),
	.LCD_REG_BUS_BASE_ADDRESS  ( LCD_REG_BUS_BASE_ADDRESS  	 ),
	.LCD_SRAM_BUS_BASE_ADDRESS ( LCD_SRAM_BUS_BASE_ADDRESS    ),
    .I2C_BUS_SEN_BASE_ADDRESS  ( I2C_BUS_SEN_BASE_ADDRESS    ),
    .QL_RESERVED_BASE_ADDRESS  ( QL_RESERVED_BASE_ADDRESS    ),

	.ADDRWIDTH_FAB_REG         ( ADDRWIDTH_FAB_REG           ),
    .DATAWIDTH_FAB_REG         ( DATAWIDTH_FAB_REG           ),
    .FPGA_REG_ID_VALUE_ADR   ( FPGA_REG_ID_VALUE_ADR     ),
    .FPGA_CLOCK_CONTROL_ADR  ( FPGA_CLOCK_CONTROL_ADR   ),
    .FPGA_GPIO_IN_REG_ADR    ( FPGA_GPIO_IN_REG_ADR      ),
    .FPGA_GPIO_OUT_REG_ADR   ( FPGA_GPIO_OUT_REG_ADR     ),
    .FPGA_GPIO_OE_REG_ADR    ( FPGA_GPIO_OE_REG_ADR      ),
    .FPGA_REG_SCRATCH_REG_ADR( FPGA_REG_SCRATCH_REG_ADR  ),

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

    .QL_RESERVED_DEF_REG_VALUE ( QL_RESERVED_DEF_REG_VALUE   )
                                                             )

     u_AL4S3B_FPGA_IP        (

	// AHB-To_FPGA Bridge I/F
	//
	.CLK_4M_i				   ( CLK_4M						 ),
	.RST_fb_i				   ( RST_fb1					 ),
	
    .WBs_ADR                   ( WBs_ADR                     ), // input  [16:0] | Address Bus                to   FPGA
    .WBs_CYC                   ( WBs_CYC                     ), // input         | Cycle Chip Select          to   FPGA
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // input   [3:0] | Byte Select                to   FPGA
    .WBs_WE                    ( WBs_WE                      ), // input         | Write Enable               to   FPGA
    .WBs_RD                    ( WBs_RD                      ), // input         | Read  Enable               to   FPGA
    .WBs_STB                   ( WBs_STB                     ), // input         | Strobe Signal              to   FPGA
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // input  [31:0] | Write Data Bus             to   FPGA
    .WB_CLK                    ( WB_CLK                      ), // output        | FPGA Clock               from FPGA
    .WB_RST                    ( WB_RST_FPGA               ), // input         | FPGA Reset               to   FPGA
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // output [31:0] | Read Data Bus              from FPGA
    .WBs_ACK                   ( WBs_ACK                     ), // output        | Transfer Cycle Acknowledge from FPGA

    //
    // GPIO
    //
    .GPIO_PIN                  ( GPIO_PIN                    ),

    //
    // I2C Master - Command Queue with DMA
    //
    .I2C_SCL                   ( I2C_SCL                     ),
    .I2C_SDA                   ( I2C_SDA                     ),

    //
    // Misc
    //
	.CLK_4M_CNTL_o             ( CLK_4M_CNTL                  ),
	.CLK_1M_CNTL_o             ( CLK_1M_CNTL                  ),
	
    .Device_ID                 ( Device_ID                   ), // output [15:0]

    // UART
    //
    //.SIN                       ( SIN                         ),
    //.SOUT                      ( SOUT                        ),

    //
    // I2C Master - Sensor with DMA
    //
    //.I2C_SCL_SEN               ( I2C_SCL_SEN                 ),
    //.I2C_SDA_SEN               ( I2C_SDA_SEN                 ),

    .i2c_Sen_Intr_o            ( i2c_Sen_Intr                ),
    .UART_Intr_o               ( UART_Intr                   ),
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
    .SDMA_Active_CQ_i          ( SDMA_Active_CQ              )
	                                                         );
															 
assign CQ_I2C_Intr = i2c_Intr | CQ_Intr;


// Empty Verilog model of QLAL4S3B
//
qlal4s3b_cell_macro              u_qlal4s3b_cell_macro
                               (
    // AHB-To-FPGA Bridge
	//
    .WBs_ADR                   ( WBs_ADR                     ), // output [16:0] | Address Bus                to   FPGA
    .WBs_CYC                   ( WBs_CYC                     ), // output        | Cycle Chip Select          to   FPGA
    .WBs_BYTE_STB              ( WBs_BYTE_STB                ), // output  [3:0] | Byte Select                to   FPGA
    .WBs_WE                    ( WBs_WE                      ), // output        | Write Enable               to   FPGA
    .WBs_RD                    ( WBs_RD                      ), // output        | Read  Enable               to   FPGA
    .WBs_STB                   ( WBs_STB                     ), // output        | Strobe Signal              to   FPGA
    .WBs_WR_DAT                ( WBs_WR_DAT                  ), // output [31:0] | Write Data Bus             to   FPGA
    .WB_CLK                    ( WB_CLK                      ), // input         | FPGA Clock               from FPGA
    .WB_RST                    ( WB_RST                      ), // output        | FPGA Reset               to   FPGA
    .WBs_RD_DAT                ( WBs_RD_DAT                  ), // input  [31:0] | Read Data Bus              from FPGA
    .WBs_ACK                   ( WBs_ACK                     ), // input         | Transfer Cycle Acknowledge from FPGA
    //
    // SDMA Signals
    //
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
    .Device_ID                 ( Device_ID[15:0]             ), // input  [15:0]
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
//pragma attribute u_AL4S3B_FPGA_IP            preserve_cell true

endmodule
