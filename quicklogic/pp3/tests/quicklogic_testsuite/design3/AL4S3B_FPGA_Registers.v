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
                         Device_ID_o
                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7  ;   // Allow for up to 128 registers in the FPGA
parameter                DATAWIDTH                   =  32  ;   // Allow for up to 128 registers in the FPGA

parameter                FPGA_REG_ID_VALUE_ADR     =  7'h0; 
parameter                FPGA_REVISION_NO_ADR      =  7'h1; 
parameter                FPGA_REG_SCRATCH_REG_ADR  =  7'h2; 

parameter                AL4S3B_DEVICE_ID            = 20'h0AEC2;//20'h610EE; 
parameter                AL4S3B_REV_LEVEL            = 16'h0002;//Revision 2 For ACSLIP modification
parameter                AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   FPGA
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   FPGA
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   FPGA
input                    WBs_WE_i      ;  // Write Enable               to   FPGA
input                    WBs_STB_i     ;  // Strobe Signal              to   FPGA
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   FPGA
input                    WBs_CLK_i     ;  // FPGA Clock               from FPGA
input                    WBs_RST_i     ;  // FPGA Reset               to   FPGA
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from FPGA
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from FPGA

//
// Misc
//
output           [19:0]  Device_ID_o   ;


// FPGA Global Signals
//
wire                     WBs_CLK_i     ;  // Wishbone FPGA Clock
wire                     WBs_RST_i     ;  // Wishbone FPGA Reset

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
wire              [19:0]  Device_ID_o   ;
wire              [15:0]  Rev_No   ;

reg              [31:0]  Scratch_Reg   ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
//wire                     FB_Dev_ID_Wr_Dcd   ;
//wire                     FB_Rev_NO_Wr_Dcd    ;
wire                     FB_Scratch_Reg_Wr_Dcd ;


//------Logic Operations---------------

// Define the FPGA's local register write enables
//
//assign FB_Dev_ID_Wr_Dcd       = ( WBs_ADR_i == FPGA_REG_ID_VALUE_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
//assign FB_Rev_NO_Wr_Dcd    = ( WBs_ADR_i == FPGA_REVISION_NO_ADR  ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_Scratch_Reg_Wr_Dcd  = ( WBs_ADR_i == FPGA_REG_SCRATCH_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);


// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the FPGA's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        Scratch_Reg       <=  AL4S3B_SCRATCH_REG           ;
		WBs_ACK_o         <= 1'b0						   ;
    end  
    else
    begin

        if(FB_Scratch_Reg_Wr_Dcd   && WBs_BYTE_STB_i[0])
			Scratch_Reg[7:0]    <= WBs_DAT_i[7:0]  ;
			
		if(FB_Scratch_Reg_Wr_Dcd   && WBs_BYTE_STB_i[1])
			Scratch_Reg[15:8]     <= WBs_DAT_i[15:8]  ;
			
		if(FB_Scratch_Reg_Wr_Dcd   && WBs_BYTE_STB_i[2])
			Scratch_Reg[23:16]     <= WBs_DAT_i[23:16]  ;
			
		if(FB_Scratch_Reg_Wr_Dcd   && WBs_BYTE_STB_i[3])
			Scratch_Reg[31:24]     <= WBs_DAT_i[31:24]  ;
 
        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
    end  
end

assign Device_ID_o = AL4S3B_DEVICE_ID ; 
assign Rev_No      = AL4S3B_REV_LEVEL; 
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i        or
         Device_ID_o      or
         Rev_No  		  or
	    //Scratch_Register
         Scratch_Reg
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    FPGA_REG_ID_VALUE_ADR     : WBs_DAT_o <= { 12'h0, Device_ID_o         };
    FPGA_REVISION_NO_ADR      : WBs_DAT_o <= { 16'h0, Rev_No   		    };
    FPGA_REG_SCRATCH_REG_ADR  : WBs_DAT_o <=  Scratch_Reg;
	default                     : WBs_DAT_o <=          AL4S3B_DEF_REG_VALUE ;
	endcase
end


//------Instantiate Modules------------
//

//
// None Currently
//

endmodule
