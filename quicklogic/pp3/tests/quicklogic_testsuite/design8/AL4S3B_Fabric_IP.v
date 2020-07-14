// -----------------------------------------------------------------------------
// title          : AL4S3B Example Fabric IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_Fabric_IP.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/Oct/09	
// last update    : 2016/Oct/09
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The Fabric example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to registers and memory 
//              located in the programmable fabric.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         	description
// 2017/Oct/09      1.0        Anand A Wadke     Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

`define ENAB_UART_16550_inst
//`define ENAB_I2C_Master_w_CmdQueue_inst
//`define UART

module AL4S3B_Fabric_IP ( 

                // AHB-To_Fabric Bridge I/F
                //
				CLK_32K_i,
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
                // GPIO
`ifdef ENAB_GPIO_INT				
                GPIO_PIN,
`endif
				CLK_4M_CNTL_o,
				CLK_1M_CNTL_o,
				
				
                Device_ID,
//`ifdef UART
                // UART
                SIN,
                SOUT,
                UART_Intr_o,
//`endif				
				
`ifdef ENAB_I2C_Master_w_CmdQueue_inst
                i2c_Sen_Intr_o,				
                i2c_Intr_o,
                CQ_Intr_o,
				LCD_DMA_Intr_o,
                SDMA_Req_Sen_o,
                SDMA_Sreq_Sen_o,
                SDMA_Done_Sen_i,
                SDMA_Active_Sen_i,
                SDMA_Req_CQ_o,
                SDMA_Sreq_CQ_o,
                SDMA_Done_CQ_i,
                SDMA_Active_CQ_i,				
`endif				

                I2C_SCL_SEN,
                I2C_SDA_SEN,

				//OV7670 VGA Signal
				PCLK_i,
				VSYNC_i,
				HREF_HSYNC_i,
				RGB_DAT_i,			
				
                VGA_Intr_o,
			    VGA_DMA_Intr_o,

                SDMA_Req_VGA_o,
                SDMA_Sreq_VGA_o,
                SDMA_Done_VGA_i,
                SDMA_Active_VGA_i
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

parameter       FABRIC_REG_BASE_ADDRESS     = 17'h00000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       IN_FRM_SAMP_VGA_BASE_ADDRESS    	= 17'h00800      ; // Assumes 128K Byte Fabric Memory Aperture
parameter       UART_BASE_ADDRESS           = 17'h01000      ; // Assumes 128K Byte Fabric Memory Aperture
parameter       QL_RESERVED_BASE_ADDRESS    = 17'h01800      ; // Assumes 128K Byte Fabric Memory Aperture

`ifdef ENAB_I2C_Master_w_CmdQueue_inst
parameter       I2C_BUS_BASE_ADDRESS        = 17'h00800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       CQ_REG_BUS_BASE_ADDRESS     = 17'h01800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       CQ_TXFIFO_BUS_BASE_ADDRESS  = 17'h02000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       LCD_REG_BUS_BASE_ADDRESS    = 17'h02800     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       LCD_SRAM_BUS_BASE_ADDRESS   = 17'h03000     ; // Assumes 128K Byte Fabric Memory Aperture
parameter       I2C_BUS_SEN_BASE_ADDRESS    = 17'h04000     ; // Assumes 128K Byte Fabric Memory Aperture
`endif



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

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad Fabric Access
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

parameter       ADDRWIDTH_VGA_REG           =  10            ;
parameter       DATAWIDTH_VGA_REG           = 32            ;

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
input   [16:0]  WBs_ADR          ;  // Address Bus                to   Fabric
input           WBs_CYC          ;  // Cycle Chip Select          to   Fabric
input    [3:0]  WBs_BYTE_STB     ;  // Byte Select                to   Fabric
input           WBs_WE           ;  // Write Enable               to   Fabric
input           WBs_RD           ;  // Read  Enable               to   Fabric
input           WBs_STB          ;  // Strobe Signal              to   Fabric
input   [31:0]  WBs_WR_DAT       ;  // Write Data Bus             to   Fabric
input           WB_CLK           ;  // Fabric Clock               from Fabric
input           WB_RST           ;  // Fabric Reset               to   Fabric
output  [31:0]  WBs_RD_DAT       ;  // Read Data Bus              from Fabric
output          WBs_ACK          ;  // Transfer Cycle Acknowledge from Fabric

// GPIO
//
`ifdef ENAB_GPIO_INT
inout   [21:0]  GPIO_PIN         ;
`endif

// Misc
output   [23:0]  Device_ID       ;

// UART
input           SIN              ;
output          SOUT             ;
output          UART_Intr_o      ;

`ifdef ENAB_I2C_Master_w_CmdQueue_inst
output          i2c_Sen_Intr_o   ;
output          i2c_Intr_o       ;
output          CQ_Intr_o        ;
output			LCD_DMA_Intr_o   ;
output   		SDMA_Req_Sen_o   ;
output   		SDMA_Sreq_Sen_o  ;
input    		SDMA_Done_Sen_i  ;
input    		SDMA_Active_Sen_i;

output          SDMA_Req_CQ_o    ;
output          SDMA_Sreq_CQ_o   ;
input           SDMA_Done_CQ_i   ;
input           SDMA_Active_CQ_i ; 
`endif

inout           I2C_SCL_SEN      ;
inout           I2C_SDA_SEN      ;



input           CLK_32K_i		 ; 
input           RST_fb_i		 ; 

output			CLK_4M_CNTL_o;
output			CLK_1M_CNTL_o; 

//VGA Interface
input 			PCLK_i;
input 			VSYNC_i;
input 			HREF_HSYNC_i;
input 	[7:0]	RGB_DAT_i;	

output                   VGA_Intr_o           ;
output					 VGA_DMA_Intr_o		 ;

output                   SDMA_Req_VGA_o       ;
output                   SDMA_Sreq_VGA_o      ;
input                    SDMA_Done_VGA_i      ;
input                    SDMA_Active_VGA_i    ; 



// Fabric Global Signals
//
wire            WB_CLK           ;  // Wishbone Fabric Clock
wire            WB_RST           ;  // Wishbone Fabric Reset

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
wire    [21:0]  GPIO_PIN         ;

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
wire    [21:0]  GPIO_In              ;
wire    [21:0]  GPIO_Out             ;
wire    [21:0]  GPIO_oe              ;

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
wire            WBs_CYC_Fabric_Reg   ;
wire            WBs_CYC_I2C          ;
wire            WBs_CYC_CQ_Reg       ;
wire            WBs_CYC_CQ_Tx_FIFO   ;  
wire            WBs_CYC_LCD_Reg      ;
wire            WBs_CYC_SRAM    	 ;
wire            WBs_CYC_UART         ;
wire            WBs_CYC_I2C_Sen      ;
wire            WBs_CYC_QL_Reserved  ;
wire            WBs_CYC_VGA_REG  ;
wire            WBs_CYC_jdi_LCD_TXFIFO  ;

wire            WBs_ACK_Fabric_Reg   ;
wire            WBs_ACK_CQ           ;
wire            WBs_ACK_UART         ;
wire            WBs_ACK_I2C_Sen      ;
wire            WBs_ACK_QL_Reserved  ;
wire            WBs_ACK_VGA  ;

wire    [31:0]  WBs_DAT_o_Fabric_Reg ;
wire    [31:0]  WBs_DAT_o_I2C        ;
wire    [15:0]  WBs_DAT_o_UART       ;
wire    [31:0]  WBs_DAT_o_CQ         ;
wire    [31:0]  WBs_DAT_o_LCD         ;
wire    [31:0]  WBs_DAT_o_I2C_Sen    ; 
wire    [31:0]  WBs_DAT_o_QL_Reserved;
//wire    [15:0]  WBs_DAT_o_VGA;
wire    [31:0]  WBs_DAT_o_VGA;



//------Logic Operations---------------
//


// Define the Chip Select for each interface
//

assign WBs_CYC_Fabric_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FABRIC_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_VGA_REG  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == IN_FRM_SAMP_VGA_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC  																				);								

`ifdef ENAB_UART_16550_inst							
assign WBs_CYC_UART         = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 
`endif							

assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC  																				);							

							

`ifdef ENAB_I2C_Master_w_CmdQueue_inst
assign WBs_CYC_I2C          = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2C_BUS_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 

assign WBs_CYC_CQ_Reg       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == CQ_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_CQ_Tx_FIFO   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == CQ_TXFIFO_BUS_BASE_ADDRESS [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_CYC_LCD_Reg      = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == LCD_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

							
assign WBs_CYC_SRAM         = (  WBs_ADR[APERWIDTH-1:APERSIZE+3] == LCD_SRAM_BUS_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+3] ) 
                             & (  WBs_CYC                                                                                );

							 
assign WBs_CYC_I2C_Sen      = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == I2C_BUS_SEN_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (( WBs_CYC & WBs_WE  & WBs_BYTE_STB[0]                                                    ) 
                            |  ( WBs_CYC & WBs_RD                                                                       )); 							
							
`endif							
			

//assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE-1] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE-1] ) 
//                            & (  WBs_CYC                                                                                );


// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_Fabric_Reg
`ifdef ENAB_I2C_Master_w_CmdQueue_inst
                            |    WBs_ACK_CQ
                            |    WBs_ACK_I2C_Sen							
`endif		
`ifdef ENAB_UART_16550_inst					
                            |    WBs_ACK_UART
`endif							
                            |    WBs_ACK_QL_Reserved
							|    WBs_ACK_VGA;


// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_Fabric_Reg  or
         WBs_DAT_o_I2C         or
         WBs_DAT_o_UART        or
         WBs_DAT_o_CQ          or
		 WBs_DAT_o_LCD		   or
         WBs_DAT_o_I2C_Sen     or
         WBs_DAT_o_QL_Reserved or
         WBs_DAT_o_VGA 	   or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FABRIC_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_Fabric_Reg   ;
    QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_QL_Reserved  ;
    //IN_FRM_SAMP_VGA_BASE_ADDRESS     [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <= { 16'h0, WBs_DAT_o_VGA } ;
    IN_FRM_SAMP_VGA_BASE_ADDRESS     [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=   		 WBs_DAT_o_VGA  ;
`ifdef ENAB_UART_16550_inst	
	UART_BASE_ADDRESS          [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <= { 16'h0, WBs_DAT_o_UART        };
`endif	
`ifdef ENAB_I2C_Master_w_CmdQueue_inst	
    I2C_BUS_BASE_ADDRESS       [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_I2C          ;
    CQ_REG_BUS_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_CQ           ;
	LCD_REG_BUS_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_LCD          ;
    I2C_BUS_SEN_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_I2C_Sen      ;
`endif
	default:                                             WBs_RD_DAT  <=          DEFAULT_READ_VALUE     ;
	endcase
end


//------Instantiate Modules------------
//

// Define the Fabric I/O Pad Signals
//
// Note: Use the Constraint manager in SpDE to assign these buffers to FBIO pads.
//

// GPIO
//
`ifdef ENAB_GPIO_INT
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
`endif
// I2C Master - Command Queue with DMA
//
bipad  u_bipad_I20  ( .A( I2C_scl_pad_o ), .EN(~I2C_scl_padoen_o ), .Q( I2C_scl_pad_i ), .P( I2C_SCL      ) );
bipad  u_bipad_I21  ( .A( I2C_sda_pad_o ), .EN(~I2C_sda_padoen_o ), .Q( I2C_sda_pad_i ), .P( I2C_SDA      ) );

// UART
//
`ifdef ENAB_UART_16550_inst
//inpad  u_inpad_I22  (                                               .Q( SIN_i         ), .P( SIN          ) );
//outpad u_outpad_I27 ( .A( SOUT_o        ),                                               .P( SOUT         ) );
	assign SIN_i = SIN;
	assign SOUT = SOUT_o;
`endif
// I2C Master - Sensor with DMA
//
bipad  u_bipad_I36  ( .A( I2C_Sen_scl_pad_o ), .EN(~I2C_Sen_scl_padoen_o ), .Q( I2C_Sen_scl_pad_i ), .P( I2C_SCL_SEN      ) );
bipad  u_bipad_I37  ( .A( I2C_Sen_sda_pad_o ), .EN(~I2C_Sen_sda_padoen_o ), .Q( I2C_Sen_sda_pad_i ), .P( I2C_SDA_SEN      ) );


// General Fabric Resources 
//
AL4S3B_Fabric_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FABRIC_REG_ID_VALUE_ADR    ( FABRIC_REG_ID_VALUE_ADR       ),
    .FABRIC_CLOCK_CONTROL_ADR   ( FABRIC_CLOCK_CONTROL_ADR     ),
    .FABRIC_GPIO_IN_REG_ADR     ( FABRIC_GPIO_IN_REG_ADR        ),
    .FABRIC_GPIO_OUT_REG_ADR    ( FABRIC_GPIO_OUT_REG_ADR       ),
    .FABRIC_GPIO_OE_REG_ADR     ( FABRIC_GPIO_OE_REG_ADR        ),
    .FABRIC_REG_SCRATCH_REG_ADR ( FABRIC_REG_SCRATCH_REG_ADR    ),

    .AL4S3B_DEVICE_ID           ( AL4S3B_DEVICE_ID              ),
    .AL4S3B_REV_LEVEL           ( AL4S3B_REV_LEVEL              ),
    .AL4S3B_GPIO_REG            ( AL4S3B_GPIO_REG               ),
    .AL4S3B_GPIO_OE_REG         ( AL4S3B_GPIO_OE_REG            ),
    .AL4S3B_SCRATCH_REG         ( AL4S3B_SCRATCH_REG            ),

    .AL4S3B_DEF_REG_VALUE       ( AL4S3B_DEF_REG_VALUE          )
                                                                )

     u_AL4S3B_Fabric_Registers 
	                           ( 
    // AHB-To_Fabric Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_FAB_REG+1:2] ),
    .WBs_CYC_i                 ( WBs_CYC_Fabric_Reg             ),
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_DAT_o                 ( WBs_DAT_o_Fabric_Reg           ),
    .WBs_ACK_o                 ( WBs_ACK_Fabric_Reg             ),

    //
    // Misc 
    //
	.CLK_32K_i                 ( CLK_32K_i              		), 
	.RST_fb_i                  ( RST_fb_i              	    	), 
	
	.CLK_4M_CNTL_o             ( CLK_4M_CNTL_o             		),
	.CLK_1M_CNTL_o             ( CLK_1M_CNTL_o             		),
	
	.JDI_LCD_ena_vcom_gen_i	   ( ena_vcom_gen_sig	),
	
	
	//JDI LCD Control Signal
	
    .Device_ID_o               ( Device_ID                      ),
	// 
	// GPIO
	//
	.GPIO_IN_i                 ( GPIO_In                        ),
	.GPIO_OUT_o                ( GPIO_Out                       ),
	.GPIO_OE_o                 ( GPIO_oe                        )
                                                                );

`ifdef ENAB_I2C_Master_w_CmdQueue_inst
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

     // AHB-To_Fabric Bridge I/F
     //
	.CLK_4M_i				   ( CLK_32K_i						), 
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

`endif

`ifdef ENAB_UART_16550_inst
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
`endif		



in_vga_wrapper_Top #(
					.ADDRWIDTH   						( ADDRWIDTH_VGA_REG	),             
					.DATAWIDTH   						( DATAWIDTH_VGA_REG	),             
                    
				    .IN_VGA_STATUS_REG_ADDR 			( IN_VGA_STATUS_REG_ADDR 			),			 	 
				    .IN_VGA_CONTROL_REG_ADR		    ( IN_VGA_CONTROL_REG_ADR		    ),
				    .IN_VGA_RX_FIFO_DATCNT_REG_ADR	( IN_VGA_RX_FIFO_DATCNT_REG_ADR	),  
				    .IN_VGA_RX_FIFO_LINECNT_REG_ADR   ( IN_VGA_RX_FIFO_LINECNT_REG_ADR  ),
				    .IN_VGA_DMA_CONTROL_REG_ADR	    ( IN_VGA_DMA_CONTROL_REG_ADR	    ),
				    .IN_VGA_DMA_STATUS_REG_ADR	    ( IN_VGA_DMA_STATUS_REG_ADR	    ),  
				    .IN_VGA_RGB_RXDATA_REG_ADR	    ( IN_VGA_RGB_RXDATA_REG_ADR	    ),  
				    .IN_VGA_DEBUG_REG_ADR	       	    ( IN_VGA_DEBUG_REG_ADR	       	), 
				  	  
				    .IN_VGA_DEF_REG_VALUE  			( IN_VGA_DEF_REG_VALUE	)
					
					
					)
				u_in_vga_wrapper_Top

					(
					    .WBs_ADR_i			( WBs_ADR[ADDRWIDTH_VGA_REG+1:2]  ),										
					    .WBs_CYC_i			( WBs_CYC_VGA_REG				 ),										
					    .WBs_WE_i			( WBs_WE             			 ),
						.WBs_BYTE_STB_i				( WBs_BYTE_STB                   	 ),						
					    .WBs_STB_i			( WBs_STB                        ),										
					    .WBs_DAT_i			( WBs_WR_DAT                     ),							
					    .WBs_CLK_i			( WB_CLK                        ),						
					    .WBs_RST_i			( WB_RST                        ),						  				
					    .WBs_DAT_o			( WBs_DAT_o_VGA				),										
					    .WBs_ACK_o			( WBs_ACK_VGA                	),						//( WBs_BYTE_STB                   	 ),	

						.VGA_Intr_o			( VGA_Intr_o                 	),				
						.VGA_DMA_Intr_o	    ( VGA_DMA_Intr_o             	),				
													
						.SDMA_Req_VGA_o		( SDMA_Req_VGA_o                  ),	
						.SDMA_Sreq_VGA_o	( SDMA_Sreq_VGA_o                 ),	
						.SDMA_Done_VGA_i	( SDMA_Done_VGA_i                 ),	
						.SDMA_Active_VGA_i	( SDMA_Active_VGA_i               ),							
						                                        			
                      			
					    .PCLK_i    			(PCLK_i    		),
					    .VSYNC_i    		(VSYNC_i    	),
					    .HREF_HSYNC_i    	(HREF_HSYNC_i   ),
					    .RGB_DAT_i    		(RGB_DAT_i   	)
						
						) ;

												
								


assign SDMA_Req_Sen_o = 1'b0;
assign SDMA_Sreq_Sen_o = 1'b0;
assign i2c_Sen_Intr_o = 1'b0;
assign WBs_DAT_o_I2C_Sen = 32'h0;
assign WBs_ACK_I2C_Sen = 1'b0;

assign I2C_Sen_scl_pad_o = 1'b0;
assign I2C_Sen_sda_pad_o = 1'b0;

assign I2C_Sen_scl_padoen_o = 1'b1;
assign I2C_Sen_sda_padoen_o = 1'b1;
   

// Reserved Resources Block
//
// Note: This block should be used in each QL fabric design
//
AL4S3B_Fabric_QL_Reserved     #(

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
                                 u_AL4S3B_Fabric_QL_Reserved
							   (
     // AHB-To_Fabric Bridge I/F
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



//pragma attribute u_AL4S3B_Fabric_Registers   preserve_cell true
//pragma attribute u_I2C_Master_w_CmdQueue     preserve_cell true
//pragma attribute u_UART_16550                preserve_cell true
//pragma attribute u_AL4S3B_Fabric_QL_Reserved preserve_cell true 

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

//--//pragma attribute u_bipad_I20                 preserve_cell true 
//--//pragma attribute u_bipad_I21                 preserve_cell true

//pragma attribute u_bipad_I36                 preserve_cell true 
//pragma attribute u_bipad_I37                 preserve_cell true

//pragma attribute u_inpad_I22                 preserve_cell true
//pragma attribute u_outpad_I27                preserve_cell true 

endmodule
