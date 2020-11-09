// -----------------------------------------------------------------------------
// title          : AL4S3B Example Fabric Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_Fabric_Registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/03	
// last update    : 2016/02/03
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
// date            version    author         description
// 2016/02/03      1.0        Glen Gomes     Initial Release
// 2017/10/01      1.0        Anand A Wadke  Added external VCOM control signal.
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module AL4S3B_Fabric_Registers ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         WBs_ADR_i,
                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_CLK_i,
                         WBs_RST_i,
                         WBs_DAT_o,
                         WBs_ACK_o,

                         //
                         // Misc
                         //
						 JDI_LCD_ena_vcom_gen_i,
						 
						 CLK_32K_i, 
						 RST_fb_i,
						 VCOM_o,
						 CLK_4M_CNTL_o,
						 CLK_1M_CNTL_o,
                         Device_ID_o,
				         GPIO_IN_i,
				         GPIO_OUT_o,
				         GPIO_OE_o

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7  ;   // Allow for up to 128 registers in the fabric
parameter                DATAWIDTH                   =  32  ;   // Allow for up to 128 registers in the fabric

parameter                FABRIC_REG_ID_VALUE_ADR     =  7'h0; 
parameter                FABRIC_CLOCK_CONTROL_ADR    =  7'h1; 
parameter                FABRIC_GPIO_IN_REG_ADR      =  7'h2; 
parameter                FABRIC_GPIO_OUT_REG_ADR     =  7'h3; 
parameter                FABRIC_GPIO_OE_REG_ADR      =  7'h4; 
parameter                FABRIC_REG_SCRATCH_REG_ADR  =  7'h5; 

parameter                AL4S3B_DEVICE_ID            = 16'h0;
parameter                AL4S3B_REV_LEVEL            = 32'h0;
parameter                AL4S3B_GPIO_REG             = 22'h0;
parameter                AL4S3B_GPIO_OE_REG          = 22'h0;
parameter                AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   Fabric
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   Fabric
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   Fabric
input                    WBs_WE_i      ;  // Write Enable               to   Fabric
input                    WBs_STB_i     ;  // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   Fabric
input                    WBs_CLK_i     ;  // Fabric Clock               from Fabric
input                    WBs_RST_i     ;  // Fabric Reset               to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from Fabric
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from Fabric

//
// Misc
//
output           [23:0]  Device_ID_o   ;

output 					 CLK_4M_CNTL_o;
output 					 CLK_1M_CNTL_o;

output 					 VCOM_o;

// GPIO
//
input            [21:0]  GPIO_IN_i     ;
output           [21:0]  GPIO_OUT_o    ;
output           [21:0]  GPIO_OE_o     ;

input                    JDI_LCD_ena_vcom_gen_i      ; 
input                    CLK_32K_i      ; 
input                    RST_fb_i      ; 
 
wire                     CLK_32K_i      ; 
wire                     RST_fb_i      ; 

wire                     VCOM_o      ;

// Fabric Global Signals
//
wire                     WBs_CLK_i     ;  // Wishbone Fabric Clock 
wire                     WBs_RST_i     ;  // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Wishbone Address Bus
wire                     WBs_CYC_i     ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [3:0]  WBs_BYTE_STB_i;  // Wishbone Byte   Enables
wire                     WBs_WE_i      ;  // Wishbone Write  Enable Strobe
wire                     WBs_STB_i     ;  // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Wishbone Read   Data Bus

reg                      WBs_ACK_o     ;  // Wishbone Client Acknowledge

// Misc
//
//reg               [15:0]  Device_ID_o   ;
wire              [23:0]  Device_ID_o   ;

// GPIO
//
wire             [21:0]  GPIO_IN_i     ;
reg              [21:0]  GPIO_OUT_o    ;
reg              [21:0]  GPIO_OE_o     ;

//reg				 [1:0]   Clk_Cntrl;



//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
//wire                     FB_Dev_ID_Wr_Dcd      ;
wire                     FB_Clk_Cntl_Wr_Dcd   ;
wire                     FB_GPIO_Reg_Wr_Dcd    ;
wire                     FB_GPIO_OE_Reg_Wr_Dcd ;
//wire                     FB_Scratch_Reg_Wr_Dcd ;

reg [8:0] count;
reg		  VCOM_Enable;
reg       VCOM_EN_int;
reg		  VCOM_r; 
reg		  VCOM_EN_32K_r1;
reg		  VCOM_EN_32K_r2;

//------Logic Operations---------------
//
assign CLK_4M_CNTL_o = 1'b0 ;
assign CLK_1M_CNTL_o = 1'b0 ;
assign VCOM_o = VCOM_EN_int & VCOM_r;


// Define the Fabric's local register write enables
//
//assign FB_Dev_ID_Wr_Dcd       = ( WBs_ADR_i == FABRIC_REG_ID_VALUE_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Clk_Cntl_Wr_Dcd    = ( WBs_ADR_i == FABRIC_CLOCK_CONTROL_ADR  ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_Reg_Wr_Dcd     = ( WBs_ADR_i == FABRIC_GPIO_OUT_REG_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_OE_Reg_Wr_Dcd  = ( WBs_ADR_i == FABRIC_GPIO_OE_REG_ADR     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FB_Scratch_Reg_Wr_Dcd  = ( WBs_ADR_i == FABRIC_REG_SCRATCH_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);


// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
		VCOM_Enable    	  <= 1'b0 ;
        GPIO_OUT_o        <= AL4S3B_GPIO_REG     ;
        GPIO_OE_o         <= AL4S3B_GPIO_OE_REG  ;
        WBs_ACK_o         <=  1'b0               ;
    end  
    else
    begin

        if(FB_Clk_Cntl_Wr_Dcd   && WBs_BYTE_STB_i[0])
		begin
			VCOM_Enable     <= WBs_DAT_i[0] ;
		end	

        // Define the GPIO Register 
        //
        if(FB_GPIO_Reg_Wr_Dcd    && WBs_BYTE_STB_i[0])
			GPIO_OUT_o[7:0]         <= WBs_DAT_i[7:0]  ;

        if(FB_GPIO_Reg_Wr_Dcd    && WBs_BYTE_STB_i[1])
			GPIO_OUT_o[15:8]        <= WBs_DAT_i[15:8] ;

        if(FB_GPIO_Reg_Wr_Dcd    && WBs_BYTE_STB_i[2])
			GPIO_OUT_o[19:16]       <= WBs_DAT_i[19:16];

        if(FB_GPIO_Reg_Wr_Dcd    && WBs_BYTE_STB_i[3])
			GPIO_OUT_o[21:20]       <= WBs_DAT_i[21:20];


        // Define the GPIO Control Register 
        //
        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
			GPIO_OE_o[7:0]          <= WBs_DAT_i[7:0]  ;

        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[1])
			GPIO_OE_o[15:8]         <= WBs_DAT_i[15:8] ;

        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[2])
			GPIO_OE_o[19:16]        <= WBs_DAT_i[19:16];

        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[3])
			GPIO_OE_o[21:20]        <= WBs_DAT_i[21:20];


        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
    end  
end

assign Device_ID_o = 24'hABC001; 
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i        or
         Device_ID_o      or
         VCOM_Enable      or
         GPIO_IN_i        or
         GPIO_OUT_o       or
         GPIO_OE_o        
         //Scratch_Register
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    FABRIC_REG_ID_VALUE_ADR     : WBs_DAT_o <= { 8'h0, Device_ID_o          };
    FABRIC_CLOCK_CONTROL_ADR    : WBs_DAT_o <= { 31'h0, VCOM_Enable		    };
    FABRIC_GPIO_IN_REG_ADR      : WBs_DAT_o <= { 10'h0, GPIO_IN_i           };
    FABRIC_GPIO_OUT_REG_ADR     : WBs_DAT_o <= { 10'h0, GPIO_OUT_o          };
    FABRIC_GPIO_OE_REG_ADR      : WBs_DAT_o <= { 10'h0, GPIO_OE_o           };
    //FABRIC_REG_SCRATCH_REG_ADR  : WBs_DAT_o <=     32'h0;
	default                     : WBs_DAT_o <=          AL4S3B_DEF_REG_VALUE ;
	endcase
end


//------Instantiate Modules------------
//
always @(posedge CLK_32K_i or posedge RST_fb_i)    
begin
    if (RST_fb_i)
    begin
        count	<=  9'h0  ;
		VCOM_r  <=  1'b0   ;
    end
    else 
    begin  
	    if (count == 9'h111)
		  begin
			count	<=  9'h0  ;
			VCOM_r  <= ~VCOM_r ;
		  end
		else
		  begin
			count   <=  count + 1;
			VCOM_r  <=  VCOM_r ;
		  end
 	end
end 

always @( posedge CLK_32K_i or posedge RST_fb_i)
begin
    if (RST_fb_i)
    begin
		VCOM_EN_32K_r1	 	<= 1'b0;
		VCOM_EN_32K_r2	 	<= 1'b0;
    end  
    else
    begin
		//VCOM_EN_32K_r1	 	<= VCOM_Enable;
		VCOM_EN_32K_r1	 	<= VCOM_Enable | JDI_LCD_ena_vcom_gen_i;
		VCOM_EN_32K_r2	 	<= VCOM_EN_32K_r1;
    end  
end

always @( posedge CLK_32K_i or posedge RST_fb_i)
begin
    if (RST_fb_i)
    begin
		VCOM_EN_int	 	<= 1'b0;
    end  
    else
    begin
        if (VCOM_r == 1'b0)
		   VCOM_EN_int	 	<= VCOM_EN_32K_r2;
		else
		   VCOM_EN_int	 	<= VCOM_EN_int;
    end  
end

//
// None Currently
//

endmodule
