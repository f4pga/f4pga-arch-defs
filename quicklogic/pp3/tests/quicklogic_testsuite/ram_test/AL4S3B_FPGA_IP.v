// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_IP.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2020/05/27	
// last update    : 2020/05/27
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
// 2020/05/27      1.0        Rakesh moolacheri     Initial Release
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
                GPIO_PIN,

                //
                // Misc
				CLK_4M_CNTL_o,
				CLK_1M_CNTL_o,
				
                Device_ID
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    = 11             ;

parameter       FPGA_REG_BASE_ADDRESS       = 17'h00000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       FPGA_RAM0_BASE_ADDRESS      = 17'h02000     ; //0x40022000
parameter       FPGA_RAM1_BASE_ADDRESS      = 17'h04000     ; //0x40024000
parameter       FPGA_RAM2_BASE_ADDRESS      = 17'h06000     ; //0x40026000
parameter       FPGA_RAM3_BASE_ADDRESS      = 17'h08000     ; //0x40028000
parameter       FPGA_RAM4_BASE_ADDRESS      = 17'h0a000     ; //0x4002a000
parameter       QL_RESERVED_BASE_ADDRESS    = 17'h0c000     ; // Assumes 128K Byte FPGA Memory Aperture

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;

parameter       ADDRWIDTH_FAB_RAMs          =  11           ;

parameter       FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter       FPGA_REV_NUM_ADR          =  7'h1; 
parameter       FPGA_GPIO_IN_REG_ADR      =  7'h2; 
parameter       FPGA_GPIO_OUT_REG_ADR     =  7'h3;
parameter       FPGA_GPIO_OE_REG_ADR      =  7'h4; 


parameter       AL4S3B_DEVICE_ID            = 16'h0;
parameter       AL4S3B_REV_LEVEL            = 32'h0;
parameter       AL4S3B_GPIO_REG             = 8'h0;
parameter       AL4S3B_GPIO_OE_REG          = 8'h0;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

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
inout   [7:0]  GPIO_PIN         ;


// Misc
//
input           CLK_4M_i		 ; 
input           RST_fb_i		 ; 

output			CLK_4M_CNTL_o;
output			CLK_1M_CNTL_o;

output    [31:0]  Device_ID        ;


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
wire    [7:0]  GPIO_PIN         ;



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
wire    [7:0]  GPIO_In              ;
wire    [7:0]  GPIO_Out             ;
wire    [7:0]  GPIO_oe              ;

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ;
wire            WBs_CYC_QL_Reserved  ;

wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_QL_Reserved  ;

wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_o_QL_Reserved;

wire            WBs_RAM0_CYC   ;
wire            WBs_RAM1_CYC   ;
wire            WBs_RAM2_CYC   ;
wire            WBs_RAM3_CYC   ; 
wire            WBs_RAM4_CYC   ;

wire            WBs_ACK_RAMs   ;

wire    [31:0]  WBs_RAM0_DAT ;
wire    [31:0]  WBs_RAM1_DAT ;
wire    [31:0]  WBs_RAM2_DAT ;
wire    [31:0]  WBs_RAM3_DAT ;
wire    [31:0]  WBs_RAM4_DAT ;

//------Logic Operations---------------
//


// Define the Chip Select for each interface 
//
assign WBs_CYC_FPGA_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_RAM0_CYC       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_RAM0_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_RAM1_CYC       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_RAM1_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_RAM2_CYC       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_RAM2_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );
							
assign WBs_RAM3_CYC       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_RAM3_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                ); 
                            
assign WBs_RAM4_CYC       = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_RAM4_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC  																				);


// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg | WBs_ACK_RAMs
                            |    WBs_ACK_QL_Reserved;


// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg    or
		 WBs_RAM0_DAT          or
		 WBs_RAM1_DAT		   or
		 WBs_RAM2_DAT		   or
		 WBs_RAM3_DAT		   or
         WBs_DAT_o_QL_Reserved or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_DAT_o_FPGA_Reg   	;
	FPGA_RAM0_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_RAM0_DAT   		;
	FPGA_RAM1_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_RAM1_DAT   		;
	FPGA_RAM2_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_RAM2_DAT   		;
	FPGA_RAM3_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_RAM3_DAT   		; 
  FPGA_RAM4_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_RAM4_DAT   		;
    QL_RESERVED_BASE_ADDRESS [APERWIDTH-1:APERSIZE+2]:   WBs_RD_DAT  <=          WBs_DAT_o_QL_Reserved  ;
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

// General FPGA Resources 
//
AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FPGA_REG_ID_VALUE_ADR    	( FPGA_REG_ID_VALUE_ADR       	),
    .FPGA_REV_NUM_ADR         	( FPGA_REV_NUM_ADR            	),     
    .FPGA_GPIO_IN_REG_ADR     	( FPGA_GPIO_IN_REG_ADR        	),
    .FPGA_GPIO_OUT_REG_ADR    	( FPGA_GPIO_OUT_REG_ADR       	),
    .FPGA_GPIO_OE_REG_ADR     	( FPGA_GPIO_OE_REG_ADR        	),
	
    .AL4S3B_DEVICE_ID           ( AL4S3B_DEVICE_ID              ),
    .AL4S3B_REV_LEVEL           ( AL4S3B_REV_LEVEL              ),
    .AL4S3B_GPIO_REG            ( AL4S3B_GPIO_REG               ),
    .AL4S3B_GPIO_OE_REG         ( AL4S3B_GPIO_OE_REG            ),

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

	// 
	// GPIO
	//
	.GPIO_IN_i                 ( GPIO_In                        ),
	.GPIO_OUT_o                ( GPIO_Out                       ),
	.GPIO_OE_o                 ( GPIO_oe                        )
                                                                );
																
AL4S3B_FPGA_RAMs #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_RAMs            ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .AL4S3B_DEF_REG_VALUE       ( AL4S3B_DEF_REG_VALUE          )
                                                                )

     u_AL4S3B_FPGA_RAMs 
	                           ( 
    // AHB-To_FPGA Bridge I/F
    //
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_FAB_RAMs+1:2] ),
    .WBs_RAM0_CYC_i            ( WBs_RAM0_CYC                   ),
    .WBs_RAM1_CYC_i            ( WBs_RAM1_CYC                   ),
    .WBs_RAM2_CYC_i            ( WBs_RAM2_CYC                   ),
    .WBs_RAM3_CYC_i            ( WBs_RAM3_CYC                   ),
    .WBs_RAM4_CYC_i            ( WBs_RAM4_CYC                   ),
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                         ),
    .WBs_STB_i                 ( WBs_STB                        ),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_CLK_i                 ( WB_CLK                         ),
    .WBs_RST_i                 ( WB_RST                         ),
    .WBs_RAM0_DAT_o            ( WBs_RAM0_DAT               	),
    .WBs_RAM1_DAT_o            ( WBs_RAM1_DAT               	),
    .WBs_RAM2_DAT_o            ( WBs_RAM2_DAT               	),
    .WBs_RAM3_DAT_o            ( WBs_RAM3_DAT               	),
    .WBs_RAM4_DAT_o            ( WBs_RAM4_DAT               	),
    .WBs_ACK_o                 ( WBs_ACK_RAMs                   )
    );

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
//pragma attribute u_AL4S3B_FPGA_QL_Reserved preserve_cell true 

//pragma attribute u_bipad_I0                  preserve_cell true
//pragma attribute u_bipad_I1                  preserve_cell true 
//pragma attribute u_bipad_I2                  preserve_cell true
//pragma attribute u_bipad_I3                  preserve_cell true
//pragma attribute u_bipad_I4                  preserve_cell true 
//pragma attribute u_bipad_I5                  preserve_cell true
//pragma attribute u_bipad_I6                  preserve_cell true
//pragma attribute u_bipad_I7                  preserve_cell true

endmodule
