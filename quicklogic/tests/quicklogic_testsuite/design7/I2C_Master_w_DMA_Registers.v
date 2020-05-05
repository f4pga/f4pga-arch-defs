// -----------------------------------------------------------------------------
// title          : I2C Master with DMA Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_DMA_Registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2C Master with Command Queue is designed for use in the 
//              fabric of the AL4S3B. The only AL4S3B specific portion are the Tx
//              FIFO. 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/03/11      1.0        Glen Gomes     Initial Release
// 2016/05/25      1.1        Rakesh M       Added DMA register / SRAM 
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module I2C_Master_w_DMA_Registers ( 

                         // AHB-To_Fabric Bridge I/F
                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_i,
                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_DAT_o,
                         WBs_ACK_o,
						 
						 DMA_Busy_i,
						 DMA_Clr_i,
						 DMA_Done_i,
						 DMA_Active_i,
						 DMA_REQ_i,
						 DMA_I2C_NACK_i,

                         DMA_EN_o,
						 DMA_Done_IRQ_o,
						 DMA_Done_IRQ_EN_o,
						 SLV_REG_ADR_o,
						 SEL_16BIT_o,
						 
                         I2C_SEN_DATA1_i 
                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH             =  7            ; // 
parameter                DATAWIDTH             = 32            ; // 

parameter                DMA_STATUS_REG_ADR    =  7'h40         ; // DMA Status   Register
parameter                DMA_CONTROL_REG_ADR   =  7'h41         ; // DMA Control  Register
//parameter                DMA_TRNS_CNT_REG_ADR  =  7'h42         ; // DMA transfer count register
//parameter                DMA_SCRATCH_REG_ADR   =  7'h43         ; // DMA Scratch  Register
parameter                DMA_SLV_ADR_REG_ADR   =  7'h44         ; // DMA Slave Adr, Reg1 Adr, Reg2 Adr  Register  
//parameter                DMA_DATA1_REG_ADR   =  7'h100        ;
//parameter                DMA_DATA2_REG_ADR   =  7'h101        ;

parameter                DMA_DATA1_REG_ADR   =  7'h48        ;
parameter                DMA_DATA2_REG_ADR   =  7'h49        ;

//parameter                DMA_REG_ADR1_REG_ADR  =  7'h45         ; 
//parameter                DMA_REG_ADR2_REG_ADR  =  7'h46         ; 

parameter                DMA_DEF_REG_VALUE     = 32'hC0C_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric

input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input            [2:0]	 WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [23:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

output		DMA_EN_o;
output		DMA_Done_IRQ_o;
output		DMA_Done_IRQ_EN_o;
output   [15:0]  SLV_REG_ADR_o    ;
output		SEL_16BIT_o;

input	 DMA_Done_i;
input	 DMA_Active_i; 
input	 DMA_REQ_i;
input	 DMA_I2C_NACK_i; 
input	 DMA_Busy_i;
input	 DMA_Clr_i;
						 
input           [23:0]  I2C_SEN_DATA1_i   ;


// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [2:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire             [23:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_o       ; // Wishbone Client Acknowledge

reg   [15:0]  SLV_REG_ADR_o    ;

reg		DMA_EN_o;
reg		DMA_Done_IRQ_o;
reg		DMA_Done_IRQ_EN_o;

wire [3:0] DMA_Control;
wire [4:0] DMA_Status;

reg		SEL_16BIT_o;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     DMA_Control_Reg_Wr_Dcd ;
wire                     DMA_Slv_Adr_Reg_Wr_Dcd ;

//------Logic Operations---------------
//

// Determine each register decode
//
assign DMA_Control_Reg_Wr_Dcd = ( WBs_ADR_i == DMA_CONTROL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign DMA_Slv_Adr_Reg_Wr_Dcd = ( WBs_ADR_i == DMA_SLV_ADR_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
   
// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);

// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

		DMA_EN_o	 		<= 1'b0;
		DMA_Done_IRQ_o	 	<= 1'b0;
		DMA_Done_IRQ_EN_o	<= 1'b0;
		SLV_REG_ADR_o		<= 16'h0;
        WBs_ACK_o           <= 1'b0; 
		SEL_16BIT_o         <= 1'b0;
    end  
    else
    begin

        if ( DMA_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_EN_o  <=  WBs_DAT_i[0];
		else if (DMA_Clr_i)
			DMA_EN_o  <=  1'b0;
			
		if ( DMA_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_Done_IRQ_EN_o  <=  WBs_DAT_i[1];
		
		if ( (DMA_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA_Done_i)
        begin
            DMA_Done_IRQ_o   <=  DMA_Done_i ? 1'b1 : WBs_DAT_i[2];
        end
		
		if ( DMA_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            SEL_16BIT_o  <=  WBs_DAT_i[3];

		if ( DMA_Slv_Adr_Reg_Wr_Dcd && WBs_BYTE_STB_i[1:0] == 2'h3)
            SLV_REG_ADR_o  <=  WBs_DAT_i[15:0];

        WBs_ACK_o               <=  WBs_ACK_o_nxt;
    end  
end

assign DMA_Status = {DMA_I2C_NACK_i,DMA_REQ_i,DMA_Active_i,DMA_Done_IRQ_o,DMA_Busy_i};
assign DMA_Control = {SEL_16BIT_o,DMA_Done_IRQ_o,DMA_Done_IRQ_EN_o,DMA_EN_o};
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              or
		 DMA_Status             or
		 DMA_Control            or
		 SLV_REG_ADR_o			or
		 I2C_SEN_DATA1_i        
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    DMA_STATUS_REG_ADR    : WBs_DAT_o <= { 27'h0, DMA_Status    };
    DMA_CONTROL_REG_ADR   : WBs_DAT_o <= { 28'h0, DMA_Control   };
	DMA_SLV_ADR_REG_ADR   : WBs_DAT_o <= { 16'h0, SLV_REG_ADR_o  };
	DMA_DATA1_REG_ADR     : WBs_DAT_o <= { I2C_SEN_DATA1_i, 8'h0 };
	default               : WBs_DAT_o <=          32'h0 ;
	endcase
end

endmodule
