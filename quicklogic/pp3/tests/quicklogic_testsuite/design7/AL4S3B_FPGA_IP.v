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
				CLK_4M_i,
				RST_fb_i,
				
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

                //
                // GPIO
                //
                GPIO_PIN,

                //
                // I2C Master - CQ
                //
                I2C_SCL,
                I2C_SDA,

                //
                // Misc
                //
				CLK_4M_CNTL_o,
				CLK_1M_CNTL_o,
				
                Device_ID,

                // UART
                //
                SIN,
                SOUT,

                i2c_Sen_Intr_o,
                UART_Intr_o,
                i2c_Intr_o,
                CQ_Intr_o,
				LCD_DMA_Intr_o,

                //
                // I2C Master - Sensor
                //
                I2C_SCL_SEN,
                I2C_SDA_SEN,

                SDMA_Req_Sen_o,
                SDMA_Sreq_Sen_o,
                SDMA_Done_Sen_i,
                SDMA_Active_Sen_i,

                //
                // I2C Master - CQ DMA
                //
                SDMA_Req_CQ_o,
                SDMA_Sreq_CQ_o,
                SDMA_Done_CQ_i,
                SDMA_Active_CQ_i

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
parameter       AL4S3B_GPIO_REG             = 21'h0         ;
parameter       AL4S3B_GPIO_OE_REG          = 21'h0         ;
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       ADDRWIDTH_CQ_REG            = 10            ;
parameter       DATAWIDTH_CQ_REG            = 32            ;

parameter       I2C_DEFAULT_READ_VALUE      = 32'hBAD_12C_AC; // Bad I2C    Access

parameter       CQ_STATUS_REG_ADR           =  7'h0         ;
parameter       CQ_CONTROL_REG_ADR          =  7'h1         ;
parameter       CQ_FIFO_LEVEL_REG_ADR       =  7'h2         ;

parameter       CQ_CNTL_DEF_REG_VALUE       = 32'hC0C_DEF_AC; // Distinguish access to undefined area
parameter       CQ_FIFO_DEF_REG_VALUE       = 32'hF1F_DEF_AC; // Distinguish access to undefined area

parameter       LCD_RAM_DEF_REG_VALUE       = 32'hDEADBEEF;

parameter       ADDRWIDTH_DMA_REG           =  7            ;
//parameter       ADDRWIDTH_DMA_REG           =  9            ;
parameter       DATAWIDTH_DMA_REG           = 32            ;

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access
parameter       DEFAULT_CNTR_WIDTH          =  3            ;
parameter       DEFAULT_CNTR_TIMEOUT        =  7            ;

parameter       ADDRWIDTH_QL_RESERVED       =  7            ;
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
inout   [22:0]  GPIO_PIN         ;

// I2C Master - Command Queue with DMA
//
inout           I2C_SCL          ;
inout           I2C_SDA          ;

// Misc
//
output   [23:0]  Device_ID       ;

// UART
//
input           SIN              ;
output          SOUT             ;

output          i2c_Sen_Intr_o   ;
output          UART_Intr_o      ;
output          i2c_Intr_o       ;
output          CQ_Intr_o        ;
output			LCD_DMA_Intr_o   ;

// I2C Master - Sensor with DMA
//
inout           I2C_SCL_SEN      ;
inout           I2C_SDA_SEN      ;

output   		SDMA_Req_Sen_o   ;
output   		SDMA_Sreq_Sen_o  ;
input    		SDMA_Done_Sen_i  ;
input    		SDMA_Active_Sen_i;

output          SDMA_Req_CQ_o    ;
output          SDMA_Sreq_CQ_o   ;
input           SDMA_Done_CQ_i   ;
input           SDMA_Active_CQ_i ; 

input           CLK_4M_i		 ; 
input           RST_fb_i		 ; 

output			CLK_4M_CNTL_o;
output			CLK_1M_CNTL_o;


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

// GPIO
//
wire    [22:0]  GPIO_PIN         ;

// I2C Master LCD
//
wire            I2C_SCL          ;
wire            I2C_SDA          ;

// I2C Master sensor
wire           I2C_SCL_SEN      ;
wire           I2C_SDA_SEN      ;

// Misc
//
wire    [23:0]  Device_ID        ;

// UART
//
wire            SIN              ;
wire            SOUT             ;

wire            i2c_Sen_Intr_o   ;
wire            UART_Intr_o      ;
wire            i2c_Intr_o       ;
wire            CQ_Intr_o        ;
wire            LCD_DMA_Intr_o   ;

wire     		SDMA_Req_Sen_o   ;
wire     		SDMA_Sreq_Sen_o  ;
wire     		SDMA_Done_Sen_i  ;
wire     		SDMA_Active_Sen_i;

wire            SDMA_Req_CQ_o    ;
wire            SDMA_Sreq_CQ_o   ;
wire            SDMA_Done_CQ_i   ;
wire            SDMA_Active_CQ_i ;


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
wire    [22:0]  GPIO_In              ;
wire    [22:0]  GPIO_Out             ;
wire    [22:0]  GPIO_oe              ;

// I2C Master-CQ
//
wire            I2C_scl_pad_i        ;
wire            I2C_scl_pad_o        ;
wire            I2C_scl_padoen_o     ;
wire            I2C_sda_pad_i        ;
wire            I2C_sda_pad_o        ;
wire            I2C_sda_padoen_o     ;

// UART
//
wire            SIN_i                ;
wire            SOUT_o               ;

// I2C Master-Sensor
//
wire            I2C_Sen_scl_pad_i    ;
wire            I2C_Sen_scl_pad_o    ;
wire            I2C_Sen_scl_padoen_o ;
wire            I2C_Sen_sda_pad_i    ;
wire            I2C_Sen_sda_pad_o    ;
wire            I2C_Sen_sda_padoen_o ;

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ;
wire            WBs_CYC_I2C          ;
wire            WBs_CYC_CQ_Reg       ;
wire            WBs_CYC_CQ_Tx_FIFO   ;  
wire            WBs_CYC_LCD_Reg      ;
wire            WBs_CYC_SRAM    	 ;
wire            WBs_CYC_UART         ;
wire            WBs_CYC_I2C_Sen      ;
wire            WBs_CYC_QL_Reserved  ;

wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_CQ           ;
wire            WBs_ACK_UART         ;
wire            WBs_ACK_I2C_Sen      ;
wire            WBs_ACK_QL_Reserved  ;

wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_o_I2C        ;
wire    [15:0]  WBs_DAT_o_UART       ;
wire    [31:0]  WBs_DAT_o_CQ         ;
wire    [31:0]  WBs_DAT_o_LCD         ;
wire    [31:0]  WBs_DAT_o_I2C_Sen    ;
wire    [31:0]  WBs_DAT_o_QL_Reserved;


//------Logic Operations---------------
//


// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_I2C          = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2C_BUS_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 

assign WBs_CYC_CQ_Reg       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == CQ_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_CQ_Tx_FIFO   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == CQ_TXFIFO_BUS_BASE_ADDRESS [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_UART         = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 

assign WBs_CYC_LCD_Reg      = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == LCD_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_SRAM         = (  WBs_ADR[APERWIDTH-1:APERSIZE+3] == LCD_SRAM_BUS_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+3] ) 
                             & (  WBs_CYC                                                                                );

							 
assign WBs_CYC_I2C_Sen      = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2C_BUS_SEN_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 							


assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC  																				);

//assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE-1] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE-1] ) 
//                            & (  WBs_CYC                                                                                );


// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg
                            |    WBs_ACK_CQ
                            |    WBs_ACK_UART
                            |    WBs_ACK_I2C_Sen
                            |    WBs_ACK_QL_Reserved;


// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg  or
         WBs_DAT_o_I2C         or
         WBs_DAT_o_UART        or
         WBs_DAT_o_CQ          or
		 WBs_DAT_o_LCD		   or
         WBs_DAT_o_I2C_Sen     or
         WBs_DAT_o_QL_Reserved or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_FPGA_Reg   ;
    I2C_BUS_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_I2C          ;
    UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <= { 16'h0, WBs_DAT_o_UART        };
    CQ_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_CQ           ;
    //CQ_TXFIFO_BUS_BASE_ADDRESS [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          CQ_FIFO_DEF_REG_VALUE  ;
	LCD_REG_BUS_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_LCD          ;
	//LCD_SRAM_BUS_BASE_ADDRESS  [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          LCD_RAM_DEF_REG_VALUE  ;
    I2C_BUS_SEN_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_I2C_Sen      ;
    QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_QL_Reserved  ;
	default:                                             WBs_RD_DAT  <=          DEFAULT_READ_VALUE     ;
	endcase
end


//------Instantiate Modules------------
//

// Define the FPGA I/O Pad Signals
//
// Note: Use the Constraint manager in SpDE to assign these buffers to FBIO pads.
//

// GPIO
//
bipad u_bipad_I0    ( .A( GPIO_Out[0]   ), .EN( GPIO_oe[0]       ), .Q( GPIO_In[0]    ), .P( GPIO_PIN[0]  ) );
bipad u_bipad_I1    ( .A( GPIO_Out[1]   ), .EN( GPIO_oe[1]       ), .Q( GPIO_In[1]    ), .P( GPIO_PIN[1]  ) );
bipad u_bipad_I2    ( .A( GPIO_Out[2]   ), .EN( GPIO_oe[2]       ), .Q( GPIO_In[2]    ), .P( GPIO_PIN[2]  ) );
bipad u_bipad_I3    ( .A( GPIO_Out[3]   ), .EN( GPIO_oe[3]       ), .Q( GPIO_In[3]    ), .P( GPIO_PIN[3]  ) );
bipad u_bipad_I4    ( .A( GPIO_Out[4]   ), .EN( GPIO_oe[4]       ), .Q( GPIO_In[4]    ), .P( GPIO_PIN[4]  ) );
bipad u_bipad_I5    ( .A( GPIO_Out[5]   ), .EN( GPIO_oe[5]       ), .Q( GPIO_In[5]    ), .P( GPIO_PIN[5]  ) );
bipad u_bipad_I6    ( .A( GPIO_Out[6]   ), .EN( GPIO_oe[6]       ), .Q( GPIO_In[6]    ), .P( GPIO_PIN[6]  ) );
bipad u_bipad_I7    ( .A( GPIO_Out[7]   ), .EN( GPIO_oe[7]       ), .Q( GPIO_In[7]    ), .P( GPIO_PIN[7]  ) );
bipad u_bipad_I8    ( .A( GPIO_Out[8]   ), .EN( GPIO_oe[8]       ), .Q( GPIO_In[8]    ), .P( GPIO_PIN[8]  ) );
bipad u_bipad_I9    ( .A( GPIO_Out[9]   ), .EN( GPIO_oe[9]       ), .Q( GPIO_In[9]    ), .P( GPIO_PIN[9]  ) );
bipad u_bipad_I10   ( .A( GPIO_Out[10]  ), .EN( GPIO_oe[10]      ), .Q( GPIO_In[10]   ), .P( GPIO_PIN[10] ) );
bipad u_bipad_I11   ( .A( GPIO_Out[11]  ), .EN( GPIO_oe[11]      ), .Q( GPIO_In[11]   ), .P( GPIO_PIN[11] ) );
bipad u_bipad_I12   ( .A( GPIO_Out[12]  ), .EN( GPIO_oe[12]      ), .Q( GPIO_In[12]   ), .P( GPIO_PIN[12] ) );
bipad u_bipad_I13   ( .A( GPIO_Out[13]  ), .EN( GPIO_oe[13]      ), .Q( GPIO_In[13]   ), .P( GPIO_PIN[13] ) );
bipad u_bipad_I14   ( .A( GPIO_Out[14]  ), .EN( GPIO_oe[14]      ), .Q( GPIO_In[14]   ), .P( GPIO_PIN[14] ) );
bipad u_bipad_I15   ( .A( GPIO_Out[15]  ), .EN( GPIO_oe[15]      ), .Q( GPIO_In[15]   ), .P( GPIO_PIN[15] ) );
bipad u_bipad_I16   ( .A( GPIO_Out[16]  ), .EN( GPIO_oe[16]      ), .Q( GPIO_In[16]   ), .P( GPIO_PIN[16] ) );
bipad u_bipad_I17   ( .A( GPIO_Out[17]  ), .EN( GPIO_oe[17]      ), .Q( GPIO_In[17]   ), .P( GPIO_PIN[17] ) );
bipad u_bipad_I18   ( .A( GPIO_Out[18]  ), .EN( GPIO_oe[18]      ), .Q( GPIO_In[18]   ), .P( GPIO_PIN[18] ) );
bipad u_bipad_I19   ( .A( GPIO_Out[19]  ), .EN( GPIO_oe[19]      ), .Q( GPIO_In[19]   ), .P( GPIO_PIN[19] ) );
bipad u_bipad_I34   ( .A( GPIO_Out[20]  ), .EN( GPIO_oe[20]      ), .Q( GPIO_In[20]   ), .P( GPIO_PIN[20] ) );
bipad u_bipad_I35   ( .A( GPIO_Out[21]  ), .EN( GPIO_oe[21]      ), .Q( GPIO_In[21]   ), .P( GPIO_PIN[21] ) );
bipad u_bipad_I39   ( .A( GPIO_Out[22]  ), .EN( GPIO_oe[22]      ), .Q( GPIO_In[22]   ), .P( GPIO_PIN[22] ) );

// I2C Master - Command Queue with DMA
//
bipad  u_bipad_I20  ( .A( I2C_scl_pad_o ), .EN(~I2C_scl_padoen_o ), .Q( I2C_scl_pad_i ), .P( I2C_SCL      ) );
bipad  u_bipad_I21  ( .A( I2C_sda_pad_o ), .EN(~I2C_sda_padoen_o ), .Q( I2C_sda_pad_i ), .P( I2C_SDA      ) );

// UART
//
inpad  u_inpad_I22  (                                               .Q( SIN_i         ), .P( SIN          ) );
outpad u_outpad_I27 ( .A( SOUT_o        ),                                               .P( SOUT         ) );

// I2C Master - Sensor with DMA
//
bipad  u_bipad_I36  ( .A( I2C_Sen_scl_pad_o ), .EN(~I2C_Sen_scl_padoen_o ), .Q( I2C_Sen_scl_pad_i ), .P( I2C_SCL_SEN      ) );
bipad  u_bipad_I37  ( .A( I2C_Sen_sda_pad_o ), .EN(~I2C_Sen_sda_padoen_o ), .Q( I2C_Sen_sda_pad_i ), .P( I2C_SDA_SEN      ) );


// General FPGA Resources 
//
AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FPGA_REG_ID_VALUE_ADR    ( FPGA_REG_ID_VALUE_ADR       ),
    .FPGA_CLOCK_CONTROL_ADR   ( FPGA_CLOCK_CONTROL_ADR     ),
    .FPGA_GPIO_IN_REG_ADR     ( FPGA_GPIO_IN_REG_ADR        ),
    .FPGA_GPIO_OUT_REG_ADR    ( FPGA_GPIO_OUT_REG_ADR       ),
    .FPGA_GPIO_OE_REG_ADR     ( FPGA_GPIO_OE_REG_ADR        ),
    .FPGA_REG_SCRATCH_REG_ADR ( FPGA_REG_SCRATCH_REG_ADR    ),

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
    .WBs_CYC_i                 ( WBs_CYC_FPGA_Reg             ),
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_DAT_o_FPGA_Reg           ),
    .WBs_ACK_o                 ( WBs_ACK_FPGA_Reg             ),

    //
    // Misc
    //
	.CLK_4M_CNTL_o             ( CLK_4M_CNTL_o             		),
	.CLK_1M_CNTL_o             ( CLK_1M_CNTL_o             		),
	
    .Device_ID_o               ( Device_ID                      ),
	// 
	// GPIO
	//
	.GPIO_IN_i                 ( GPIO_In                        ),
	.GPIO_OUT_o                ( GPIO_Out                       ),
	.GPIO_OE_o                 ( GPIO_oe                        )
                                                                );


I2C_Master_w_CmdQueue         #(

    .ADDRWIDTH                 ( ADDRWIDTH_CQ_REG               ),
    .DATAWIDTH                 ( DATAWIDTH_CQ_REG               ),

    .I2C_DEFAULT_READ_VALUE    ( I2C_DEFAULT_READ_VALUE         ), 

    .CQ_STATUS_REG_ADR         ( CQ_STATUS_REG_ADR              ),
    .CQ_CONTROL_REG_ADR        ( CQ_CONTROL_REG_ADR             ),
    .CQ_FIFO_LEVEL_REG_ADR     ( CQ_FIFO_LEVEL_REG_ADR          ),

    .CQ_CNTL_DEF_REG_VALUE     ( CQ_CNTL_DEF_REG_VALUE          )
                                                                )
                                 u_I2C_Master_w_CmdQueue 
                               ( 

     // AHB-To_FPGA Bridge I/F
     //
	.CLK_4M_i				   ( CLK_4M_i						), 
	.RST_fb_i				   ( RST_fb_i						),
	
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),

    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_CQ_REG+1:2]  ),

    .WBs_CYC_I2C_i             ( WBs_CYC_I2C                    ),
    .WBs_CYC_CQ_Reg_i          ( WBs_CYC_CQ_Reg                 ),
    .WBs_CYC_CQ_Tx_FIFO_i      ( WBs_CYC_CQ_Tx_FIFO             ),
	.WBs_CYC_LCD_Reg_i         ( WBs_CYC_LCD_Reg                ),
	.WBs_CYC_SRAM_i            ( WBs_CYC_SRAM                   ),

    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o_CQ_Reg_o        ( WBs_DAT_o_CQ                   ),
	.WBs_DAT_o_LCD_Reg_o	   ( WBs_DAT_o_LCD                  ),
    .WBs_DAT_o_I2C_o           ( WBs_DAT_o_I2C                  ),
    .WBs_ACK_o                 ( WBs_ACK_CQ                     ),

    .scl_pad_i                 ( I2C_scl_pad_i                  ), 
    .scl_pad_o                 ( I2C_scl_pad_o                  ), 
    .scl_padoen_o              ( I2C_scl_padoen_o               ), 

    .sda_pad_i                 ( I2C_sda_pad_i                  ), 
    .sda_pad_o                 ( I2C_sda_pad_o                  ), 
    .sda_padoen_o              ( I2C_sda_padoen_o               ),

    .i2c_Intr_o                ( i2c_Intr_o                     ),
    .CQ_Intr_o                 ( CQ_Intr_o                      ),
	
	.LCD_DMA_Intr_o            ( LCD_DMA_Intr_o                 ),

    .SDMA_Req_CQ_o             ( SDMA_Req_CQ_o                  ),
    .SDMA_Sreq_CQ_o            ( SDMA_Sreq_CQ_o                 ),
    .SDMA_Done_CQ_i            ( SDMA_Done_CQ_i                 ),
    .SDMA_Active_CQ_i          ( SDMA_Active_CQ_i               )
                                                                );



// Serial Port
//
UART_16550 u_UART_16550        
                               ( 
    // AHB-To_FPGA Bridge I/F
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


// External I2C Sensor Support with DMA
//

I2C_Master_w_DMA              #(

    .ADDRWIDTH                 ( ADDRWIDTH_DMA_REG              ),
    .DATAWIDTH                 ( DATAWIDTH_DMA_REG              )
	                                                            )
                                 u_I2C_Master_w_DMA               
                               (
    .WBs_CLK_i                 ( WB_CLK                      	),
    .WBs_RST_i                 ( WB_RST                      	),

    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_DMA_REG+1:2] ),

    .WBs_CYC_I2C_Sen_i         ( WBs_CYC_I2C_Sen                ),

    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                       	),
    .WBs_STB_i                 ( WBs_STB                      	),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o_I2C_Sen_o       ( WBs_DAT_o_I2C_Sen              ),
    .WBs_ACK_o                 ( WBs_ACK_I2C_Sen                ),

    .scl_Sen_pad_i             ( I2C_Sen_scl_pad_i              ),  
    .scl_Sen_pad_o             ( I2C_Sen_scl_pad_o              ),
    .scl_Sen_padoen_o          ( I2C_Sen_scl_padoen_o           ),

    .sda_Sen_pad_i             ( I2C_Sen_sda_pad_i              ),   
    .sda_Sen_pad_o             ( I2C_Sen_sda_pad_o              ),
    .sda_Sen_padoen_o          ( I2C_Sen_sda_padoen_o           ),

    .i2c_Sen_Intr_o            ( i2c_Sen_Intr_o                 ),

    .SDMA_Req_Sen_o            ( SDMA_Req_Sen_o                 ),
    .SDMA_Sreq_Sen_o           ( SDMA_Sreq_Sen_o                ),
    .SDMA_Done_Sen_i           ( SDMA_Done_Sen_i                ),
    .SDMA_Active_Sen_i         ( SDMA_Active_Sen_i              )
                                                                );

//assign SDMA_Req_Sen_o = 1'b0;
//assign SDMA_Sreq_Sen_o = 1'b0;
//assign i2c_Sen_Intr_o = 1'b0;

// Reserved Resources Block
//
// Note: This block should be used in each QL FPGA design
//
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



//pragma attribute u_AL4S3B_FPGA_Registers   preserve_cell true
//pragma attribute u_I2C_Master_w_CmdQueue     preserve_cell true
//pragma attribute u_UART_16550                preserve_cell true
//pragma attribute u_AL4S3B_FPGA_QL_Reserved preserve_cell true 

//pragma attribute u_bipad_I0                  preserve_cell true
//pragma attribute u_bipad_I1                  preserve_cell true 
//pragma attribute u_bipad_I2                  preserve_cell true
//pragma attribute u_bipad_I3                  preserve_cell true
//pragma attribute u_bipad_I4                  preserve_cell true 
//pragma attribute u_bipad_I5                  preserve_cell true
//pragma attribute u_bipad_I6                  preserve_cell true
//pragma attribute u_bipad_I7                  preserve_cell true
//pragma attribute u_bipad_I8                  preserve_cell true
//pragma attribute u_bipad_I9                  preserve_cell true
//pragma attribute u_bipad_I10                 preserve_cell true
//pragma attribute u_bipad_I11                 preserve_cell true
//pragma attribute u_bipad_I12                 preserve_cell true 
//pragma attribute u_bipad_I13                 preserve_cell true 
//pragma attribute u_bipad_I14                 preserve_cell true 
//pragma attribute u_bipad_I15                 preserve_cell true 
//pragma attribute u_bipad_I16                 preserve_cell true 
//pragma attribute u_bipad_I17                 preserve_cell true 
//pragma attribute u_bipad_I18                 preserve_cell true 
//pragma attribute u_bipad_I19                 preserve_cell true
//pragma attribute u_bipad_I34                 preserve_cell true
//pragma attribute u_bipad_I35                 preserve_cell true 
//pragma attribute u_bipad_I39                 preserve_cell true

//pragma attribute u_bipad_I20                 preserve_cell true 
//pragma attribute u_bipad_I21                 preserve_cell true

//pragma attribute u_bipad_I36                 preserve_cell true 
//pragma attribute u_bipad_I37                 preserve_cell true

//pragma attribute u_inpad_I22                 preserve_cell true
//pragma attribute u_outpad_I27                preserve_cell true 

endmodule
