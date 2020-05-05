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
                GPIO_PIN,
				//GPIO_PIN_i,
				//GPIO_PIN_o,

                //
                // Misc
				CLK_4M_CNTL_o,
				CLK_1M_CNTL_o,
				
                Device_ID
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

parameter       FPGA_REG_BASE_ADDRESS     = 17'h00000     ; // Assumes 128K Byte FPGA Memory Aperture
parameter       QL_RESERVED_BASE_ADDRESS    = 17'h00800     ; // Assumes 128K Byte FPGA Memory Aperture

parameter       ADDRWIDTH_FAB_REG           =  7            ;
parameter       DATAWIDTH_FAB_REG           = 32            ;

parameter                FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter                FPGA_MODE_SEL_ADR         =  7'h1; 
parameter                FPGA_GPIO_IN_REG_ADR1     =  7'h2; 
parameter                FPGA_GPIO_IN_REG_ADR2     =  7'h3;
parameter                FPGA_GPIO_OUT_REG_ADR1    =  7'h4; 
parameter                FPGA_GPIO_OUT_REG_ADR2    =  7'h5; 
parameter                FPGA_GPIO_OE_REG_ADR1     =  7'h6; 
parameter                FPGA_GPIO_OE_REG_ADR2     =  7'h7;

parameter                FPGA_PWM_EN_POL_ADR       =  7'h8; 
parameter                FPGA_DUTY_CYCLE_ADR1      =  7'h9; 
parameter                FPGA_FREQ_CYCLE_ADR1      =  7'hA;
parameter                FPGA_DUTY_CYCLE_ADR2      =  7'hB;
parameter                FPGA_FREQ_CYCLE_ADR2      =  7'hC;
parameter                FPGA_DUTY_CYCLE_ADR3      =  7'hD;
parameter                FPGA_FREQ_CYCLE_ADR3      =  7'hE;
parameter                FPGA_DUTY_CYCLE_ADR4      =  7'hF;
parameter                FPGA_FREQ_CYCLE_ADR4      =  7'h10;

parameter                AL4S3B_DEVICE_ID            = 16'h0;
parameter                AL4S3B_REV_LEVEL            = 32'h0;
parameter                AL4S3B_GPIO_REG             = 46'h0;
parameter                AL4S3B_GPIO_OE_REG          = 46'h0;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

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
inout   [45:0]  GPIO_PIN         ;
//input   [5:0]  GPIO_PIN_i       ;
//output  [7:0]  GPIO_PIN_o       ;

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
wire    [45:0]  GPIO_PIN         ;
//wire    [5:0]   GPIO_PIN_i       ;
//wire    [7:0]   GPIO_PIN_o       ;


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
wire    [45:0]  GPIO_In              ;
wire    [45:0]  GPIO_Out             ;
wire    [45:0]  GPIO_oe              ;

// Wishbone Bus Signals
//
wire            WBs_CYC_FPGA_Reg   ;
wire            WBs_CYC_QL_Reserved  ;

wire            WBs_ACK_FPGA_Reg   ;
wire            WBs_ACK_QL_Reserved  ;

wire    [31:0]  WBs_DAT_o_FPGA_Reg ;
wire    [31:0]  WBs_DAT_o_QL_Reserved;

// PWM
wire			pwm_s1;
  
wire	[15:0]	freq_cycle_reg1;
wire  	        freq_cycle_toggle1;

wire	[15:0]	duty_cycle_reg1;
wire 	        duty_cycle_toggle1;

wire	[3:0]	pwm_en;
wire	[3:0]	idle_pol;

wire			pwm_s2;
  
wire	[15:0]	freq_cycle_reg2;
wire  	        freq_cycle_toggle2;

wire	[15:0]	duty_cycle_reg2;
wire 	        duty_cycle_toggle2;

wire			pwm_s3;
  
wire	[15:0]	freq_cycle_reg3;
wire  	        freq_cycle_toggle3;

wire	[15:0]	duty_cycle_reg3;
wire 	        duty_cycle_toggle3;

wire			pwm_s4;
  
wire	[15:0]	freq_cycle_reg4;
wire  	        freq_cycle_toggle4;

wire	[15:0]	duty_cycle_reg4;
wire 	        duty_cycle_toggle4;

wire	[3:0]	gpio_pwm_out;
wire	[3:0]	mode_sel;

wire			PWM1;
wire			PWM2;
wire			PWM3;
wire			PWM4;
//------Logic Operations---------------
//


// Define the Chip Select for each interface
//
assign WBs_CYC_FPGA_Reg   = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC                                                                                );

assign WBs_CYC_QL_Reserved  = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == QL_RESERVED_BASE_ADDRESS   [APERWIDTH-1:APERSIZE+2] ) 
                            & (  WBs_CYC  																				);


// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_FPGA_Reg
                            |    WBs_ACK_QL_Reserved;


// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DAT_o_FPGA_Reg  or
         WBs_DAT_o_QL_Reserved or
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
    FPGA_REG_BASE_ADDRESS    [APERWIDTH-1:APERSIZE+2]: WBs_RD_DAT  <=          WBs_DAT_o_FPGA_Reg   ;
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
assign gpio_pwm_out[0] = mode_sel[0]? PWM1: GPIO_Out[8]; 
assign gpio_pwm_out[1] = mode_sel[1]? PWM2: GPIO_Out[6];
assign gpio_pwm_out[2] = mode_sel[2]? PWM3: GPIO_Out[9];
assign gpio_pwm_out[3] = mode_sel[3]? PWM4: GPIO_Out[10];

// GPIO
//
bipad u_bipad_I0    ( .A( GPIO_Out[0]   ), .EN( GPIO_oe[0]       ), .Q( GPIO_In[0]    ), .P( GPIO_PIN[0]  ) );
bipad u_bipad_I1    ( .A( GPIO_Out[1]   ), .EN( GPIO_oe[1]       ), .Q( GPIO_In[1]    ), .P( GPIO_PIN[1]  ) );
bipad u_bipad_I2    ( .A( GPIO_Out[2]   ), .EN( GPIO_oe[2]       ), .Q( GPIO_In[2]    ), .P( GPIO_PIN[2]  ) );
bipad u_bipad_I3    ( .A( GPIO_Out[3]   ), .EN( GPIO_oe[3]       ), .Q( GPIO_In[3]    ), .P( GPIO_PIN[3]  ) );
bipad u_bipad_I4    ( .A( GPIO_Out[4]   ), .EN( GPIO_oe[4]       ), .Q( GPIO_In[4]    ), .P( GPIO_PIN[4]  ) );
bipad u_bipad_I5    ( .A( GPIO_Out[5]   ), .EN( GPIO_oe[5]       ), .Q( GPIO_In[5]    ), .P( GPIO_PIN[5]  ) );
bipad u_bipad_I6    ( .A( gpio_pwm_out[1]   ), .EN( GPIO_oe[6]       ), .Q( GPIO_In[6]    ), .P( GPIO_PIN[6]  ) );
bipad u_bipad_I7    ( .A( GPIO_Out[7]   ), .EN( GPIO_oe[7]       ), .Q( GPIO_In[7]    ), .P( GPIO_PIN[7]  ) );
bipad u_bipad_I8    ( .A( gpio_pwm_out[0]   ), .EN( GPIO_oe[8]       ), .Q( GPIO_In[8]    ), .P( GPIO_PIN[8]  ) );
bipad u_bipad_I9    ( .A( gpio_pwm_out[2]   ), .EN( GPIO_oe[9]       ), .Q( GPIO_In[9]    ), .P( GPIO_PIN[9]  ) );
bipad u_bipad_I10   ( .A( gpio_pwm_out[3]   ), .EN( GPIO_oe[10]      ), .Q( GPIO_In[10]   ), .P( GPIO_PIN[10] ) );
bipad u_bipad_I11   ( .A( GPIO_Out[11]  ), .EN( GPIO_oe[11]      ), .Q( GPIO_In[11]   ), .P( GPIO_PIN[11] ) );
bipad u_bipad_I12   ( .A( GPIO_Out[12]  ), .EN( GPIO_oe[12]      ), .Q( GPIO_In[12]   ), .P( GPIO_PIN[12] ) );
bipad u_bipad_I13   ( .A( GPIO_Out[13]  ), .EN( GPIO_oe[13]      ), .Q( GPIO_In[13]   ), .P( GPIO_PIN[13] ) );
bipad u_bipad_I14   ( .A( GPIO_Out[14]  ), .EN( GPIO_oe[14]      ), .Q( GPIO_In[14]   ), .P( GPIO_PIN[14] ) );
bipad u_bipad_I15   ( .A( GPIO_Out[15]  ), .EN( GPIO_oe[15]      ), .Q( GPIO_In[15]   ), .P( GPIO_PIN[15] ) );
bipad u_bipad_I16   ( .A( GPIO_Out[16]  ), .EN( GPIO_oe[16]      ), .Q( GPIO_In[16]   ), .P( GPIO_PIN[16] ) );
bipad u_bipad_I17   ( .A( GPIO_Out[17]  ), .EN( GPIO_oe[17]      ), .Q( GPIO_In[17]   ), .P( GPIO_PIN[17] ) );
bipad u_bipad_I18   ( .A( GPIO_Out[18]  ), .EN( GPIO_oe[18]      ), .Q( GPIO_In[18]   ), .P( GPIO_PIN[18] ) );
bipad u_bipad_I19   ( .A( GPIO_Out[19]  ), .EN( GPIO_oe[19]      ), .Q( GPIO_In[19]   ), .P( GPIO_PIN[19] ) );
bipad u_bipad_I20   ( .A( GPIO_Out[20]  ), .EN( GPIO_oe[20]      ), .Q( GPIO_In[20]   ), .P( GPIO_PIN[20] ) );
bipad u_bipad_I21   ( .A( GPIO_Out[21]  ), .EN( GPIO_oe[21]      ), .Q( GPIO_In[21]   ), .P( GPIO_PIN[21] ) );
bipad u_bipad_I22   ( .A( GPIO_Out[22]  ), .EN( GPIO_oe[22]      ), .Q( GPIO_In[22]   ), .P( GPIO_PIN[22] ) );
bipad u_bipad_I23   ( .A( GPIO_Out[23]  ), .EN( GPIO_oe[23]      ), .Q( GPIO_In[23]   ), .P( GPIO_PIN[23] ) );
bipad u_bipad_I24   ( .A( GPIO_Out[24]  ), .EN( GPIO_oe[24]      ), .Q( GPIO_In[24]   ), .P( GPIO_PIN[24] ) );
bipad u_bipad_I25   ( .A( GPIO_Out[25]  ), .EN( GPIO_oe[25]      ), .Q( GPIO_In[25]   ), .P( GPIO_PIN[25] ) );
bipad u_bipad_I26   ( .A( GPIO_Out[26]  ), .EN( GPIO_oe[26]      ), .Q( GPIO_In[26]   ), .P( GPIO_PIN[26] ) );
bipad u_bipad_I27   ( .A( GPIO_Out[27]  ), .EN( GPIO_oe[27]      ), .Q( GPIO_In[27]   ), .P( GPIO_PIN[27] ) );
bipad u_bipad_I28   ( .A( GPIO_Out[28]  ), .EN( GPIO_oe[28]      ), .Q( GPIO_In[28]   ), .P( GPIO_PIN[28] ) );
bipad u_bipad_I29   ( .A( GPIO_Out[29]  ), .EN( GPIO_oe[29]      ), .Q( GPIO_In[29]   ), .P( GPIO_PIN[29] ) );
bipad u_bipad_I30   ( .A( GPIO_Out[30]  ), .EN( GPIO_oe[30]      ), .Q( GPIO_In[30]   ), .P( GPIO_PIN[30] ) );
bipad u_bipad_I31   ( .A( GPIO_Out[31]  ), .EN( GPIO_oe[31]      ), .Q( GPIO_In[31]   ), .P( GPIO_PIN[31] ) );
/* bipad u_bipad_I32   ( .A( GPIO_Out[32]  ), .EN( GPIO_oe[32]      ), .Q( GPIO_In[32]   ), .P( GPIO_PIN[32] ) );
bipad u_bipad_I33   ( .A( GPIO_Out[33]  ), .EN( GPIO_oe[33]      ), .Q( GPIO_In[33]   ), .P( GPIO_PIN[33] ) );
bipad u_bipad_I34   ( .A( GPIO_Out[34]  ), .EN( GPIO_oe[34]      ), .Q( GPIO_In[34]   ), .P( GPIO_PIN[34] ) );
bipad u_bipad_I35   ( .A( GPIO_Out[35]  ), .EN( GPIO_oe[35]      ), .Q( GPIO_In[35]   ), .P( GPIO_PIN[35] ) );
bipad u_bipad_I36   ( .A( GPIO_Out[36]  ), .EN( GPIO_oe[36]      ), .Q( GPIO_In[36]   ), .P( GPIO_PIN[36] ) );
bipad u_bipad_I37   ( .A( GPIO_Out[37]  ), .EN( GPIO_oe[37]      ), .Q( GPIO_In[37]   ), .P( GPIO_PIN[37] ) );
bipad u_bipad_I38   ( .A( GPIO_Out[38]  ), .EN( GPIO_oe[38]      ), .Q( GPIO_In[38]   ), .P( GPIO_PIN[38] ) );
bipad u_bipad_I39   ( .A( GPIO_Out[39]  ), .EN( GPIO_oe[39]      ), .Q( GPIO_In[39]   ), .P( GPIO_PIN[39] ) );
bipad u_bipad_I40   ( .A( GPIO_Out[40]  ), .EN( GPIO_oe[40]      ), .Q( GPIO_In[40]   ), .P( GPIO_PIN[40] ) );
bipad u_bipad_I41   ( .A( GPIO_Out[41]  ), .EN( GPIO_oe[41]      ), .Q( GPIO_In[41]   ), .P( GPIO_PIN[41] ) );
bipad u_bipad_I42   ( .A( GPIO_Out[42]  ), .EN( GPIO_oe[42]      ), .Q( GPIO_In[42]   ), .P( GPIO_PIN[42] ) );
bipad u_bipad_I43   ( .A( GPIO_Out[43]  ), .EN( GPIO_oe[43]      ), .Q( GPIO_In[43]   ), .P( GPIO_PIN[43] ) );
bipad u_bipad_I44   ( .A( GPIO_Out[44]  ), .EN( GPIO_oe[44]      ), .Q( GPIO_In[44]   ), .P( GPIO_PIN[44] ) );
bipad u_bipad_I45   ( .A( GPIO_Out[45]  ), .EN( GPIO_oe[45]      ), .Q( GPIO_In[45]   ), .P( GPIO_PIN[45] ) ); */


assign GPIO_PIN[32] = (GPIO_oe[32])? GPIO_Out[32]: 1'bz;
assign GPIO_PIN[33] = (GPIO_oe[33])? GPIO_Out[33]: 1'bz;
assign GPIO_PIN[34] = (GPIO_oe[34])? GPIO_Out[34]: 1'bz;
assign GPIO_PIN[35] = (GPIO_oe[35])? GPIO_Out[35]: 1'bz;
assign GPIO_PIN[36] = (GPIO_oe[36])? GPIO_Out[36]: 1'bz;
assign GPIO_PIN[37] = (GPIO_oe[37])? GPIO_Out[37]: 1'bz;
assign GPIO_PIN[38] = (GPIO_oe[38])? GPIO_Out[38]: 1'bz;
assign GPIO_PIN[39] = (GPIO_oe[39])? GPIO_Out[39]: 1'bz;
assign GPIO_PIN[40] = (GPIO_oe[40])? GPIO_Out[40]: 1'bz;
assign GPIO_PIN[41] = (GPIO_oe[41])? GPIO_Out[41]: 1'bz;
assign GPIO_PIN[42] = (GPIO_oe[42])? GPIO_Out[42]: 1'bz;
assign GPIO_PIN[43] = (GPIO_oe[43])? GPIO_Out[43]: 1'bz;
assign GPIO_PIN[44] = (GPIO_oe[44])? GPIO_Out[44]: 1'bz;
assign GPIO_PIN[45] = (GPIO_oe[45])? GPIO_Out[45]: 1'bz;

assign GPIO_In[32] = GPIO_PIN[32];
assign GPIO_In[33] = GPIO_PIN[33];
assign GPIO_In[34] = GPIO_PIN[34];
assign GPIO_In[35] = GPIO_PIN[35];
assign GPIO_In[36] = GPIO_PIN[36];
assign GPIO_In[37] = GPIO_PIN[37];
assign GPIO_In[38] = GPIO_PIN[38];
assign GPIO_In[39] = GPIO_PIN[39];
assign GPIO_In[40] = GPIO_PIN[40];
assign GPIO_In[41] = GPIO_PIN[41];
assign GPIO_In[42] = GPIO_PIN[42];
assign GPIO_In[43] = GPIO_PIN[43];
assign GPIO_In[44] = GPIO_PIN[44];
assign GPIO_In[45] = GPIO_PIN[45];


/*
assign GPIO_PIN_o[0] = GPIO_Out[32];
assign GPIO_PIN_o[1] = GPIO_Out[33];
assign GPIO_PIN_o[2] = GPIO_Out[34];
assign GPIO_PIN_o[3] = GPIO_Out[35];
assign GPIO_PIN_o[4] = GPIO_Out[36];
assign GPIO_PIN_o[5] = GPIO_Out[37];
assign GPIO_PIN_o[6] = GPIO_Out[38];
assign GPIO_PIN_o[7] = GPIO_Out[39];
assign GPIO_PIN_o[8] = GPIO_Out[39];
assign GPIO_PIN_o[9] = GPIO_Out[39];
assign GPIO_PIN_o[10] = GPIO_Out[39];
assign GPIO_PIN_o[11] = GPIO_Out[39];
assign GPIO_PIN_o[12] = GPIO_Out[39];
assign GPIO_PIN_o[13] = GPIO_Out[39];
*/
/*
assign GPIO_In[40] = GPIO_PIN_i[0];
assign GPIO_In[41] = GPIO_PIN_i[1];
assign GPIO_In[42] = GPIO_PIN_i[2];
assign GPIO_In[43] = GPIO_PIN_i[3];
assign GPIO_In[44] = GPIO_PIN_i[4];
assign GPIO_In[45] = GPIO_PIN_i[5];
*/

// General FPGA Resources 
//
AL4S3B_FPGA_Registers #(

    .ADDRWIDTH                  ( ADDRWIDTH_FAB_REG             ),
    .DATAWIDTH                  ( DATAWIDTH_FAB_REG             ),

    .FPGA_REG_ID_VALUE_ADR    ( FPGA_REG_ID_VALUE_ADR       ),
    .FPGA_MODE_SEL_ADR        ( FPGA_MODE_SEL_ADR           ),     
    .FPGA_GPIO_IN_REG_ADR1    ( FPGA_GPIO_IN_REG_ADR1       ),
    .FPGA_GPIO_IN_REG_ADR2    ( FPGA_GPIO_IN_REG_ADR2       ),
    .FPGA_GPIO_OUT_REG_ADR1   ( FPGA_GPIO_OUT_REG_ADR1      ),
    .FPGA_GPIO_OUT_REG_ADR2   ( FPGA_GPIO_OUT_REG_ADR2      ),
    .FPGA_GPIO_OE_REG_ADR1    ( FPGA_GPIO_OE_REG_ADR1       ),
    .FPGA_GPIO_OE_REG_ADR2    ( FPGA_GPIO_OE_REG_ADR2       ),
	
    .FPGA_PWM_EN_POL_ADR      ( FPGA_PWM_EN_POL_ADR         ),   
	.FPGA_DUTY_CYCLE_ADR1     ( FPGA_DUTY_CYCLE_ADR1        ),
	.FPGA_FREQ_CYCLE_ADR1     ( FPGA_FREQ_CYCLE_ADR1        ),
	.FPGA_DUTY_CYCLE_ADR2     ( FPGA_DUTY_CYCLE_ADR2        ),
	.FPGA_FREQ_CYCLE_ADR2     ( FPGA_FREQ_CYCLE_ADR2        ),
	.FPGA_DUTY_CYCLE_ADR3     ( FPGA_DUTY_CYCLE_ADR3        ),
	.FPGA_FREQ_CYCLE_ADR3     ( FPGA_FREQ_CYCLE_ADR3        ),
	.FPGA_DUTY_CYCLE_ADR4     ( FPGA_DUTY_CYCLE_ADR4        ),
	.FPGA_FREQ_CYCLE_ADR4     ( FPGA_FREQ_CYCLE_ADR4        ),

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
	//PWM
	.Mode_Sel_o  	           ( mode_sel                       ),
	.PWM_En_o  	               ( pwm_en                         ),
	.Idle_Pol_o                ( idle_pol                       ),

	.Freq_Cycle_Reg1_o         ( freq_cycle_reg1                ),
	.Freq_Cycle_Toggle1_o      ( freq_cycle_toggle1             ),
	.Duty_Cycle_Reg1_o         ( duty_cycle_reg1                ),
	.Duty_Cycle_Toggle1_o      ( duty_cycle_toggle1             ),
	
	.Freq_Cycle_Reg2_o         ( freq_cycle_reg2                ),
	.Freq_Cycle_Toggle2_o      ( freq_cycle_toggle2             ),
	.Duty_Cycle_Reg2_o         ( duty_cycle_reg2                ),
	.Duty_Cycle_Toggle2_o      ( duty_cycle_toggle2             ),
	
	.Freq_Cycle_Reg3_o         ( freq_cycle_reg3                ),
	.Freq_Cycle_Toggle3_o      ( freq_cycle_toggle3             ),
	.Duty_Cycle_Reg3_o         ( duty_cycle_reg3                ),
	.Duty_Cycle_Toggle3_o      ( duty_cycle_toggle3             ),
	
	.Freq_Cycle_Reg4_o         ( freq_cycle_reg4                ),
	.Freq_Cycle_Toggle4_o      ( freq_cycle_toggle4             ),
	.Duty_Cycle_Reg4_o         ( duty_cycle_reg4                ),
	.Duty_Cycle_Toggle4_o      ( duty_cycle_toggle4             ),

	// 
	// GPIO
	//
	.GPIO_IN_i                 ( GPIO_In                        ),
	.GPIO_OUT_o                ( GPIO_Out                       ),
	.GPIO_OE_o                 ( GPIO_oe                        )
                                                                );
																
///PWM1
assign PWM1 = (pwm_en[0])? pwm_s1: idle_pol[0];
pwm_counter pwm_counter_inst_1 (
   .CLK				(WB_CLK),
   .RST				(WB_RST),
   .FREQ_CYCLE_REG		(freq_cycle_reg1), 
   .FREQ_CYCLE_TOGGLE	(freq_cycle_toggle1), 
   .DUTY_CYCLE_REG		(duty_cycle_reg1),
   .DUTY_CYCLE_TOGGLE	(duty_cycle_toggle1),
   .PWM_ENA            	(pwm_en[0]), 
   .idle_pol			(idle_pol[0]), 
   .PWM 				(pwm_s1)
   ); 
   
///PWM2
assign PWM2 = (pwm_en[1])? pwm_s2: idle_pol[1];
pwm_counter pwm_counter_inst_2 (
   .CLK				(WB_CLK),
   .RST				(WB_RST),
   .FREQ_CYCLE_REG		(freq_cycle_reg2), 
   .FREQ_CYCLE_TOGGLE	(freq_cycle_toggle2), 
   .DUTY_CYCLE_REG		(duty_cycle_reg2),
   .DUTY_CYCLE_TOGGLE	(duty_cycle_toggle2),
   .PWM_ENA            	(pwm_en[1]), 
   .idle_pol			(idle_pol[1]), 
   .PWM 				(pwm_s2)
   ); 
   
///PWM3
assign PWM3 = (pwm_en[2])? pwm_s3: idle_pol[2];
pwm_counter pwm_counter_inst_3 (
   .CLK				(WB_CLK),
   .RST				(WB_RST),
   .FREQ_CYCLE_REG		(freq_cycle_reg3), 
   .FREQ_CYCLE_TOGGLE	(freq_cycle_toggle3), 
   .DUTY_CYCLE_REG		(duty_cycle_reg3),
   .DUTY_CYCLE_TOGGLE	(duty_cycle_toggle3),
   .PWM_ENA            	(pwm_en[2]), 
   .idle_pol			(idle_pol[2]), 
   .PWM 				(pwm_s3)
   ); 

///PWM4
assign PWM4 = (pwm_en[3])? pwm_s4: idle_pol[3];
pwm_counter pwm_counter_inst_4 (
   .CLK				(WB_CLK),
   .RST				(WB_RST),
   .FREQ_CYCLE_REG		(freq_cycle_reg4), 
   .FREQ_CYCLE_TOGGLE	(freq_cycle_toggle4), 
   .DUTY_CYCLE_REG		(duty_cycle_reg4),
   .DUTY_CYCLE_TOGGLE	(duty_cycle_toggle4),
   .PWM_ENA            	(pwm_en[3]), 
   .idle_pol			(idle_pol[3]), 
   .PWM 				(pwm_s4)
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
//pragma attribute u_bipad_I20                 preserve_cell true
//pragma attribute u_bipad_I21                 preserve_cell true
//pragma attribute u_bipad_I22                 preserve_cell true 
//pragma attribute u_bipad_I23                 preserve_cell true 
//pragma attribute u_bipad_I24                 preserve_cell true 
//pragma attribute u_bipad_I25                 preserve_cell true 
//pragma attribute u_bipad_I26                 preserve_cell true 
//pragma attribute u_bipad_I27                 preserve_cell true 
//pragma attribute u_bipad_I28                 preserve_cell true 
//pragma attribute u_bipad_I29                 preserve_cell true
//pragma attribute u_bipad_I30                 preserve_cell true
//pragma attribute u_bipad_I31                 preserve_cell true
//pragma attribute u_bipad_I32                 preserve_cell true
//pragma attribute u_bipad_I33                 preserve_cell true
//pragma attribute u_bipad_I34                 preserve_cell true
//pragma attribute u_bipad_I35                 preserve_cell true
//pragma attribute u_bipad_I36                 preserve_cell true
//pragma attribute u_bipad_I37                 preserve_cell true
//pragma attribute u_bipad_I38                 preserve_cell true
//pragma attribute u_bipad_I39                 preserve_cell true
//pragma attribute u_bipad_I40                 preserve_cell true
//pragma attribute u_bipad_I41                 preserve_cell true
//pragma attribute u_bipad_I42                 preserve_cell true
//pragma attribute u_bipad_I43                 preserve_cell true
//pragma attribute u_bipad_I44                 preserve_cell true
//pragma attribute u_bipad_I45                 preserve_cell true


endmodule
