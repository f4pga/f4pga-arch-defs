// -----------------------------------------------------------------------------
// title          : I2C Master with Command Queue Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_CmdQueue_Registers.v
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
// 2016/05/21      1.1        Anand Wadke    Added DMA registers.
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module I2C_Master_w_CmdQueue_Registers_dma ( 

                         // AHB-To_Fabric Bridge I/F
                         //
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

                         // Command Queue
                         //
                         CQ_Busy_i,

                         CQ_Enable_o,
                         CQ_Single_Step_o,
                         CQ_Intr_o,

                         // Tx
                         //
                         Tx_FIFO_Empty_i,
                         Tx_FIFO_Full_i,
                         Tx_FIFO_Level_i,

                         Tx_FIFO_Flush_o,
						 
						 //DMA
						 dma_done_i,	
						 dma_active_i,
						 
						 Tx_FIFO_dma_ena_o
						 

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH             =  7            ; // 
parameter                DATAWIDTH             = 32            ; // 

parameter                CQ_STATUS_REG_ADR     =  7'h0         ; // Command Queue Status     Register
parameter                CQ_CONTROL_REG_ADR    =  7'h1         ; // Command Queue Control    Register
parameter                CQ_FIFO_LEVEL_REG_ADR =  7'h2         ; // Command Queue FIFO Level Register
parameter                CQ_DMA_CTRL_REG_ADR   =  7'h3         ; // Command Queue DMA Control Register
parameter                CQ_DMA_STS_REG_ADR 	   =  7'h4         ; // Command Queue DMA Status Register


parameter                CQ_CNTL_DEF_REG_VALUE = 32'hC0C_DEF_AC; // Distinguish access to undefined area


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input                    WBs_CLK_i       ; // Fabric Clock               from Fabric
input                    WBs_RST_i       ; // Fabric Reset               to   Fabric

input   [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Address Bus                to   Fabric
input                    WBs_CYC_i       ; // Cycle Chip Select          to   Fabric
input             [1:0]  WBs_BYTE_STB_i  ;
input                    WBs_WE_i        ; // Write Enable               to   Fabric
input                    WBs_STB_i       ; // Strobe Signal              to   Fabric
input            [15:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

// Command Queue
//
input                    CQ_Busy_i       ;

output                   CQ_Enable_o     ;
output                   CQ_Single_Step_o;
output                   CQ_Intr_o       ;


// Tx
//
input                    Tx_FIFO_Empty_i ;
input                    Tx_FIFO_Full_i  ;
input             [8:0]  Tx_FIFO_Level_i ;

output                   Tx_FIFO_Flush_o ;

input                    dma_done_i	 ;
input                    dma_active_i ;
output                   Tx_FIFO_dma_ena_o ;


// Fabric Global Signals
//
wire                     WBs_CLK_i       ; // Wishbone Fabric Clock
wire                     WBs_RST_i       ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i       ; // Wishbone Address Bus
wire                     WBs_CYC_i       ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [1:0]  WBs_BYTE_STB_i  ;
wire                     WBs_WE_i        ; // Wishbone Write  Enable Strobe
wire                     WBs_STB_i       ; // Wishbone Transfer      Strobe
wire             [15:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_o       ; // Wishbone Client Acknowledge


// Command Queue
//
reg                      CQ_Enable_o     ;
reg                      CQ_Single_Step_o;
wire                     CQ_Intr_o       ;


// Tx
//
wire                     Tx_FIFO_Empty_i ;
wire                     Tx_FIFO_Full_i  ;
wire              [8:0]  Tx_FIFO_Level_i ;

reg                      Tx_FIFO_Flush_o ;
//reg                      Tx_FIFO_dma_ena_o ;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

wire                     CMD_QUEUE_CTR_Wr_Dcd;    // Command Queue Control    Register
//wire                     CMD_QUEUE_DMA_ctrlPreg_Wr_Dcd;    // Command Queue DMA Control    Register

reg                      CQ_Intr_Enable      ;
reg                      CQ_Intr_Status      ;

wire                     CQ_Intr_Status_Dcd  ;

reg                      Tx_FIFO_Empty_i_1ff ;

//reg               [7:0]  scratch_reg         ;


//------Logic Operations---------------
//
assign Tx_FIFO_dma_ena_o = 1'b0;
// Determine each register decode
//
assign CMD_QUEUE_CTR_Wr_Dcd  			= ( WBs_ADR_i == CQ_CONTROL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
//assign CMD_QUEUE_DMA_ctrlPreg_Wr_Dcd  	= ( WBs_ADR_i == CQ_DMA_CTRL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;


// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt         =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

        CQ_Intr_Enable       <=  1'b0;
        CQ_Intr_Status       <=  1'b0;

        CQ_Single_Step_o     <=  1'b1;
        CQ_Enable_o          <=  1'b0;

        //Tx_FIFO_dma_ena_o    <=  1'b0;
		
        Tx_FIFO_Flush_o      <=  1'b0;
        Tx_FIFO_Empty_i_1ff  <=  1'b1;

        //scratch_reg          <=  8'h0;

        WBs_ACK_o            <=  1'b0;
    end  
    else
    begin
	    //DMA control register
	    //if ( CMD_QUEUE_DMA_ctrlPreg_Wr_Dcd && WBs_BYTE_STB_i[0])
		//begin
		//    Tx_FIFO_dma_ena_o <= WBs_DAT_i[0];
		//end
	

        // FIFO Control Register
        //
        if ( CMD_QUEUE_CTR_Wr_Dcd && WBs_BYTE_STB_i[0])
        begin
            Tx_FIFO_Flush_o  <=  WBs_DAT_i[4];
            CQ_Intr_Enable   <=  WBs_DAT_i[3];
            CQ_Single_Step_o <= ~WBs_DAT_i[1];
            CQ_Enable_o      <=  WBs_DAT_i[0];
        end
		

        // Determine the Interrupt Status
        //
        // Note: Interrupt is triggered when the Tx FIFO transitions from not Empty to Empty
        //
        if ( (CMD_QUEUE_CTR_Wr_Dcd && WBs_BYTE_STB_i[0]) || CQ_Intr_Status_Dcd)
        begin
            CQ_Intr_Status   <=  CQ_Intr_Status_Dcd ? 1'b1 : WBs_DAT_i[2];
        end

        Tx_FIFO_Empty_i_1ff  <=  Tx_FIFO_Empty_i;

        //if ( CMD_QUEUE_CTR_Wr_Dcd && WBs_BYTE_STB_i[1])
        //    scratch_reg      <=  WBs_DAT_i[15:8];

        WBs_ACK_o            <=  WBs_ACK_o_nxt;
    end  
end


// Detect when the Tx FIFO has just done empty
//
assign CQ_Intr_Status_Dcd    =  (~Tx_FIFO_Empty_i_1ff) & Tx_FIFO_Empty_i;


// Determine the interrupt output
//
assign CQ_Intr_o             = CQ_Intr_Status & CQ_Intr_Enable;


// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i              or
         CQ_Intr_Enable         or
         CQ_Intr_Status         or
         CQ_Busy_i              or 
         CQ_Enable_o            or
         CQ_Single_Step_o       or
         CQ_Intr_o              or
         Tx_FIFO_Flush_o        or
         //scratch_reg            or
		 Tx_FIFO_Level_i        or
         Tx_FIFO_Full_i         or
         Tx_FIFO_Empty_i        
		 //Tx_FIFO_dma_ena_o

 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    CQ_STATUS_REG_ADR           : WBs_DAT_o <= { 26'h0, CQ_Intr_o             ,
			                                            CQ_Busy_i             ,
                                                  2'h0, Tx_FIFO_Full_i        ,
                                                        Tx_FIFO_Empty_i      };
    CQ_CONTROL_REG_ADR          : WBs_DAT_o <= { 27'h0 , Tx_FIFO_Flush_o       ,
                                                        CQ_Intr_Enable        ,
                                                        CQ_Intr_Status        ,
                                                       ~CQ_Single_Step_o      ,
                                                        CQ_Enable_o          };
    CQ_FIFO_LEVEL_REG_ADR       : WBs_DAT_o <= { 23'h0, Tx_FIFO_Level_i      };
	
    //CQ_DMA_CTRL_REG_ADR         : WBs_DAT_o <= { 28'h0, 3'b000, Tx_FIFO_dma_ena_o      };
	
	//CQ_DMA_STS_REG_ADR			: WBs_DAT_o <= { 28'h0, 3'b000, dma_active_i      };
	
	default                     : WBs_DAT_o <=          CQ_CNTL_DEF_REG_VALUE ;
	endcase
end


endmodule
