// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_IP.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 03/Jan/2019	
// last update    : 03/Jan/2019
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The FPGA example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to registers and memory 
//              located in the programmable fabric.
// -----------------------------------------------------------------------------
// copyright (c) 2019
// -----------------------------------------------------------------------------
// revisions  :
// date            version     author         description
// Jan/03/2019      1.0        Anand       Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

module AL4S3B_FPGA_IP ( 

                // AHB-To_FPGA Bridge I/F
                //
				//CLK_12M_i,

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
				
				sys_ref_clk_i,
				
				SDMA_Req_f_o,
                SDMA_Sreq_f_o,
                SDMA_Done_f_i,
                SDMA_Active_f_i,
				
				fDone_Intr_o, 
				f_DMA_Intr_o, 

                Device_ID,
                debug_o
				
                );


//------Port Parameters----------------
//

parameter       APERWIDTH                   = 17            ;
parameter       APERSIZE                    =  9            ;

// Assumes 128K Byte FPGA Memory Aperture
parameter       f_REG_BASE_ADDR           = 17'h00000     ; 
parameter       RESERVED         			= 17'h00800     ; 
parameter       f_COSSIN_RAM_BASE_ADDR    = 17'h01000     ; 
parameter       DMA_REG_BASE_ADDR     		= 17'h10000     ; 
parameter       DMA0_DPORT_BASE_ADDR          = 17'h11000     ; 

parameter       AL4S3B_DEVICE_ID            = 20'h00FFD;
parameter       AL4S3B_REV_LEVEL            = 16'h0001;
parameter       AL4S3B_SCRATCH_REG          = 32'h12345678  ;

parameter       AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC; // Distinguish access to undefined area

parameter       DEFAULT_READ_VALUE          = 32'hBAD_FAB_AC; // Bad FPGA Access

//parameter       ADDRWIDTH_f_REG           =  13            ;
parameter       ADDRWIDTH_f_REG           =  17            ;
parameter       DATAWIDTH_f_REG           = 32            ;
parameter       COEFFADDRWIDTH              =   9           ;
parameter       fRAMADDRWIDTH             =   9           ;


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
input 			sys_ref_clk_i;
output          fDone_Intr_o   ;				
output          f_DMA_Intr_o  ;	
input 			SDMA_Done_f_i	;
input 			SDMA_Active_f_i;
output          SDMA_Req_f_o  ;				
output          SDMA_Sreq_f_o ;
output   [19:0] Device_ID       ;
output   [7:0]  debug_o   ;


// Wishbone Bus Signals
//
wire            WB_CLK           ;  // Wishbone FPGA Clock
wire            WB_RST           ;  // Wishbone FPGA Reset
wire    [16:0]  WBs_ADR          ;  // Wishbone Address Bus
wire            WBs_CYC          ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire     [3:0]  WBs_BYTE_STB     ;  // Wishbone Byte   Enables
wire            WBs_WE           ;  // Wishbone Write  Enable Strobe
wire            WBs_RD           ;  // Wishbone Read   Enable Strobe
wire            WBs_STB          ;  // Wishbone Transfer      Strobe
reg     [31:0]  WBs_RD_DAT       ;  // Wishbone Read   Data Bus
wire    [31:0]  WBs_WR_DAT       ;  // Wishbone Write  Data Bus
wire            WBs_ACK          ;  // Wishbone Client Acknowledge

wire          	fDone_Intr_o   ;				
wire          	f_DMA_Intr_o  ;	

wire 			SDMA_Done_f_i	;
wire 			SDMA_Active_f_i;

wire      	    SDMA_Req_f_o  ;				
wire          	SDMA_Sreq_f_o ;

// Misc
wire    [19:0]  Device_ID        ;
//------Define Parameters--------------
// Default I/O timeout statemachine
parameter       DEFAULT_IDLE   =  0  ;
parameter       DEFAULT_COUNT  =  1  ;


//------Internal Signals---------------
// Wishbone Bus Signals
wire            		WBs_CYC_f_Reg   ;
wire            		WBs_CYC_f_Realmg_RAM ; 
wire            		WBs_CYC_f_CosSin_RAM ;
wire            		WBs_CYC_DMA_Reg ;
		
wire            		WBs_ACK_f        ; 
		
wire    [31:0]  		WBs_DAT_f       	 ;
wire    [31:0]  		WBs_DMA_REG_DAT       	 ;
wire    [31:0]  		WBs_CosSin_RAM_DAT   ;
wire    [31:0]  		WBs_f_RealImg_RAM_DAT   	 ;


//------Logic Operations---------------
// Define the Chip Select for each interface
//
assign WBs_CYC_f_Reg   	    = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== f_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                                & (  WBs_CYC                                                                                );
							
assign WBs_CYC_DMA_Reg          = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== DMA_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                                & (  WBs_CYC                                                                                );

assign WBs_CYC_f_Realmg_RAM  = ((  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== DMA0_DPORT_BASE_ADDR	[APERWIDTH-1:APERSIZE+2] ))	
                                & (  WBs_CYC                                                                                );

assign WBs_CYC_f_CosSin_RAM    = (  WBs_ADR[APERWIDTH-1:APERSIZE+2] 	== f_COSSIN_RAM_BASE_ADDR    [APERWIDTH-1:APERSIZE+2] ) 
                                & (  WBs_CYC                                                                                );								
/* assign WBs_CYC_f_Realmg_RAM  = ((  WBs_ADR[APERWIDTH-1:APERSIZE+2] == DMA_REG_BASE_ADDR[APERWIDTH-1:APERSIZE+2] ) |
								  (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == DMA0_DPORT_BASE_ADDR[APERWIDTH-1:APERSIZE+2] ))	
                            & (  WBs_CYC                                                                                ); */
							

/* assign WBs_CYC_f_Img_RAM  = ((  WBs_ADR[APERWIDTH-1:APERSIZE+2] == DMA_REG_BASE_ADDR[APERWIDTH-1:APERSIZE+2] ) |
								  (  WBs_ADR[APERWIDTH-1:APERSIZE+2] == DMA0_DPORT_BASE_ADDR[APERWIDTH-1:APERSIZE+2] ))	
                            & (  WBs_CYC                                                                                ); */	


			

// Define the Acknowledge back to the host for everything
//
assign WBs_ACK              =    WBs_ACK_f;  

assign Device_ID          	=    AL4S3B_DEVICE_ID ; 
                            
						
// Define the how to read from each IP
//
always @(
         WBs_ADR               or
         WBs_DMA_REG_DAT       or
         WBs_DAT_f           or 
         WBs_CosSin_RAM_DAT    or 
         WBs_f_RealImg_RAM_DAT       or 
         WBs_RD_DAT    
        )
 begin
    case(WBs_ADR[APERWIDTH-1:APERSIZE+2])
		f_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2]			: WBs_RD_DAT  <=    WBs_DAT_f   ;
		DMA_REG_BASE_ADDR    [APERWIDTH-1:APERSIZE+2]			: WBs_RD_DAT  <=    WBs_DMA_REG_DAT   ;
		f_COSSIN_RAM_BASE_ADDR [APERWIDTH-1:APERSIZE+2]		: WBs_RD_DAT  <=    WBs_CosSin_RAM_DAT   ;
		DMA0_DPORT_BASE_ADDR [APERWIDTH-1:APERSIZE+2]			: WBs_RD_DAT  <=    WBs_f_RealImg_RAM_DAT   ;
	
		default													: WBs_RD_DAT  <=    DEFAULT_READ_VALUE     ;
	endcase
end

//------Instantiate Modules------------
//

// General FPGA Resources 

//
f_512_wrapp              #(

    .ADDRWIDTH                 ( ADDRWIDTH_f_REG              ),
    .DATAWIDTH                 ( DATAWIDTH_f_REG              ),
    .COEFFADDRWIDTH            ( COEFFADDRWIDTH                 ),
    .fRAMADDRWIDTH           ( fRAMADDRWIDTH                )
	                                                            )
    u_f_512_wrapp               
                               (
    .WBs_CLK_i                 ( WB_CLK                      	),
    .WBs_RST_i                 ( WB_RST                      	),

    //.WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_f_REG+2:2] ),// To accommodate the RAM access
    .WBs_ADR_i                 ( WBs_ADR[ADDRWIDTH_f_REG-1:2] ),

    .WBs_CYC_i         		   ( WBs_CYC_f_Reg                ), 
    .WBs_CYC_DMA_Reg_i  	   ( WBs_CYC_DMA_Reg         		),  
    .WBs_CYC_f_Realmg_RAM_i  ( WBs_CYC_f_Realmg_RAM         ),  
    .WBs_CYC_f_CosSin_RAM_i  ( WBs_CYC_f_CosSin_RAM         ),  
	
    .WBs_BYTE_STB_i            ( WBs_BYTE_STB                   ),
    .WBs_WE_i                  ( WBs_WE                       	),
    .WBs_STB_i                 ( WBs_STB                      	),
    .WBs_DAT_i                 ( WBs_WR_DAT                     ),
    .WBs_DAT_o                 ( WBs_DAT_f                    ),
    .WBs_DMAREG_DAT_o          ( WBs_DMA_REG_DAT                ),
    .WBs_CosSin_RAM_DAT_o      ( WBs_CosSin_RAM_DAT             ),
    .WBs_f_RAM_DAT_o         ( WBs_f_RealImg_RAM_DAT        ),
    .WBs_ACK_o                 ( WBs_ACK_f                    ),
	
	.sys_ref_clk_i		       ( sys_ref_clk_i ),

    .fDone_Intr_o            ( fDone_Intr_o                 ), 
	.f_DMA_Intr_o            ( f_DMA_Intr_o                 ),

    .SDMA_Req_f_o            ( SDMA_Req_f_o                 ), 
    .SDMA_Sreq_f_o           ( SDMA_Sreq_f_o                ),
    .SDMA_Done_f_i           ( SDMA_Done_f_i                ),
    .SDMA_Active_f_i         ( SDMA_Active_f_i              )
                                                                );
//pragma attribute u_f_512_wrapp   preserve_cell true
						
							
endmodule
