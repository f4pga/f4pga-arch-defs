// -----------------------------------------------------------------------------
// title          : LCD controller Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : LCD_controller_registers.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: LCD controller register
//              
//               
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/06/02      1.0        Rakesh M     Initial Release
// 
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module LCD_controller_registers ( 

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
						 
						 WBs_SRAM_CYC_i,
						 WBs_SRAM_ACK_o,
						 
						 LCD_CNTL_EN_o,
						 AUTO_PAN_EN_o,
						 //LCD_PAN_EN_o,
						 //LCD_PAN_RNL_o,
						 //LCD_Dp_Strt_Adr_o,
						 LCD_SLV_Adr_o,
						 LCD_CNTL_Busy_i,
						 LCD_Clr_i,
						 LCD_LD_Done_i,
						 DMA_Clr_i,
						 DMA_REQ_i,
						 DMA_Done_i,

                         DMA_EN_o,
						 DMA_Done_IRQ_o,
						 LCD_Load_Done_IRQ_o,
						 
						 SRAM_RD_DAT_o,
						 SRAM_RD_ADR_i
                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH             = 10            ; // 
parameter                DATAWIDTH             = 32            ; // 

parameter                LCD_STATUS_REG_ADR    =  4'h0         ; // LCD Status   Register
parameter                LCD_CONTROL_REG_ADR   =  4'h1         ; // LCD Control  Register
parameter                LCD_PAN_CNTL_REG_ADR  =  4'h2         ; // LCD PAN control register 
parameter                LCD_SLV_ADR_REG_ADR  =   4'h3         ; // LCD PAN control register 
parameter                LCD_START_REG_ADR     =  4'h4         ; // LCD Display Start Address  Register


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
input   [DATAWIDTH-1:0]  WBs_DAT_i       ; // Write Data Bus             to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o       ; // Read Data Bus              from Fabric
output                   WBs_ACK_o       ; // Transfer Cycle Acknowledge from Fabric

output		DMA_EN_o;
output		LCD_CNTL_EN_o; 
output		AUTO_PAN_EN_o;
//output		LCD_PAN_EN_o;
//output		LCD_PAN_RNL_o;
//output   [11:0] LCD_Dp_Strt_Adr_o;
output   [6:0] LCD_SLV_Adr_o;
output		LCD_Load_Done_IRQ_o;
output   [7:0]  SRAM_RD_DAT_o    ;

input	 LCD_LD_Done_i;
input	 DMA_REQ_i; 
input	 LCD_CNTL_Busy_i;
input	 DMA_Clr_i;
input    LCD_Clr_i;

input    [11:0]  SRAM_RD_ADR_i ;
						 
input		WBs_SRAM_CYC_i;
output      WBs_SRAM_ACK_o;

input		DMA_Done_i;
output		DMA_Done_IRQ_o;


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
wire    [DATAWIDTH-1:0]  WBs_DAT_i       ; // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o       ; // Wishbone Read   Data Bus

reg                      WBs_ACK_o       ; // Wishbone Client Acknowledge


wire		WBs_SRAM_CYC_i;
reg      WBs_SRAM_ACK_o;

wire     WBs_ACK_o_nxt;
wire     WBs_SRAM_ACK_o_nxt;



//reg   [11:0] LCD_Dp_Strt_Adr_o;
reg   [6:0] LCD_SLV_Adr_o;
reg		DMA_EN_o;
reg  	LCD_CNTL_EN_o;
reg		AUTO_PAN_EN_o;
//reg  	LCD_PAN_EN_o; 
//reg  	LCD_PAN_RNL_o; 
reg		LCD_Load_Done_IRQ;
reg		LCD_Load_Done_IRQ_EN;

wire	DMA_Done_i;
reg 	DMA_Done_IRQ_EN;
reg		DMA_Done_IRQ;

wire [6:0] LCD_Control;
wire [3:0] LCD_Status;
wire [7:0] SRAM1_RD_DAT;
wire [7:0] SRAM2_RD_DAT;

wire LCD_Load_Done;





//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//


wire                     LCD_Control_Reg_Wr_Dcd ;
//wire                     LCD_pan_cntl_Reg_Wr_Dcd ;
//wire                     LCD_Start_Reg_Wr_Dcd ;  
wire					 LCD_SLV_ADR_Reg_Wr_Dcd;





wire             [31:0] SRAM_WR_DAT   ;
wire             [8:0]  SRAM_WR_ADR   ;
wire             [10:0] SRAM_RD_ADR   ;
wire					SRAM_WR_EN;
wire					SRAM1_WR_EN;
wire					SRAM2_WR_EN;



//------Logic Operations---------------
//
//interrupts
assign  DMA_Done_IRQ_o		=  DMA_Done_IRQ & DMA_Done_IRQ_EN;
assign  LCD_Load_Done_IRQ_o	=  LCD_Load_Done_IRQ & LCD_Load_Done_IRQ_EN;

// Determine each register decode     
//
assign LCD_Control_Reg_Wr_Dcd = ( WBs_ADR_i[3:0] == LCD_CONTROL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
//assign LCD_pan_cntl_Reg_Wr_Dcd = ( WBs_ADR_i[3:0] == LCD_PAN_CNTL_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
assign LCD_SLV_ADR_Reg_Wr_Dcd = ( WBs_ADR_i[3:0] == LCD_SLV_ADR_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;
//assign LCD_Start_Reg_Wr_Dcd = ( WBs_ADR_i[3:0] == LCD_START_REG_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ; 

   
// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

		DMA_EN_o	 	  <= 1'b0;
		DMA_Done_IRQ_EN <= 1'b0; 
		DMA_Done_IRQ    <= 1'b0;
		
		LCD_CNTL_EN_o	<= 1'b0;
		AUTO_PAN_EN_o	<= 1'b0;
		LCD_Load_Done_IRQ	 <= 1'b0;
		LCD_Load_Done_IRQ_EN	 <= 1'b0;

        WBs_ACK_o            <=  1'b0;
		//LCD_PAN_EN_o	 	<= 1'b0;
		//LCD_PAN_RNL_o	 	<= 1'b0;
		//LCD_Dp_Strt_Adr_o   <= 12'h0;
		LCD_SLV_Adr_o		<= 7'h3C;
		
		WBs_SRAM_ACK_o      <=  1'b0;
    end  
    else
    begin
	
		if ( LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            LCD_CNTL_EN_o  <=  WBs_DAT_i[0];
		else if (LCD_Clr_i)
			LCD_CNTL_EN_o  <=  1'b0;  
			
		if ( LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            AUTO_PAN_EN_o  <=  WBs_DAT_i[1];
		else if (LCD_Clr_i)
			AUTO_PAN_EN_o  <=  1'b0;

        if ( LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            DMA_EN_o  <=  WBs_DAT_i[2];
		else if (DMA_Clr_i)
			DMA_EN_o  <=  1'b0;
			
		if ( LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            LCD_Load_Done_IRQ_EN  <=  WBs_DAT_i[3];
		
		if ( (LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0]) || LCD_LD_Done_i)
        begin
            LCD_Load_Done_IRQ   <=  LCD_LD_Done_i ? 1'b1 : WBs_DAT_i[4];
        end
		
		if ( LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0]) 
            DMA_Done_IRQ_EN  <=  WBs_DAT_i[5];
			
		if ( (LCD_Control_Reg_Wr_Dcd && WBs_BYTE_STB_i[0]) || DMA_Done_i)
        begin
            DMA_Done_IRQ   <=  DMA_Done_i ? 1'b1 : WBs_DAT_i[6];
        end

/*
        if ( LCD_pan_cntl_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
		  begin
            LCD_PAN_EN_o  <=  WBs_DAT_i[0];
			LCD_PAN_RNL_o <=  WBs_DAT_i[1];
		  end
*/
			
		if ( LCD_SLV_ADR_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            LCD_SLV_Adr_o  <=  WBs_DAT_i[6:0];
		
/*		
		if ( LCD_Start_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
            LCD_Dp_Strt_Adr_o  <=  WBs_DAT_i[11:0];
*/

        WBs_ACK_o               <=  WBs_ACK_o_nxt;
		WBs_SRAM_ACK_o      	<=  WBs_SRAM_ACK_o_nxt;
    end  
end

assign LCD_Load_Done = LCD_Load_Done_IRQ;
assign LCD_Status = {DMA_REQ_i,DMA_Done_IRQ,LCD_Load_Done,LCD_CNTL_Busy_i};
assign LCD_Control = {DMA_Done_IRQ,DMA_Done_IRQ_EN,LCD_Load_Done_IRQ,LCD_Load_Done_IRQ_EN,DMA_EN_o,AUTO_PAN_EN_o,LCD_CNTL_EN_o};
// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i [3:0]        or
		 LCD_Status             or
		 LCD_Control            or
		 //LCD_PAN_RNL_o		or
		 //LCD_PAN_EN_o	        or
		 //LCD_Dp_Strt_Adr_o 	or
		 LCD_SLV_Adr_o
		 
 )
 begin
    case(WBs_ADR_i[3:0])
    LCD_STATUS_REG_ADR    : WBs_DAT_o <= { 28'h0, LCD_Status };
    LCD_CONTROL_REG_ADR   : WBs_DAT_o <= { 25'h0, LCD_Control };
	//LCD_PAN_CNTL_REG_ADR  : WBs_DAT_o <= { 30'h0, LCD_PAN_RNL_o,LCD_PAN_EN_o};
	LCD_SLV_ADR_REG_ADR   : WBs_DAT_o <= { 25'h0, LCD_SLV_Adr_o };
    //LCD_START_REG_ADR     : WBs_DAT_o <= { 20'h0, LCD_Dp_Strt_Adr_o };
	default               : WBs_DAT_o <=          32'h0 ;
	endcase
end

assign WBs_SRAM_ACK_o_nxt  =   WBs_SRAM_CYC_i & WBs_STB_i & (~WBs_ACK_o);

assign SRAM_WR_EN =  WBs_SRAM_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) ;

assign SRAM_WR_DAT     = WBs_DAT_i;
assign SRAM_WR_ADR =  WBs_ADR_i[8:0]; 

assign SRAM_RD_ADR =  SRAM_RD_ADR_i[10:0];  
assign SRAM_RD_DAT_o = SRAM_RD_ADR_i[11]? SRAM2_RD_DAT: SRAM1_RD_DAT ;

assign SRAM1_WR_EN = (WBs_ADR_i[9])? 1'b0: SRAM_WR_EN;
assign SRAM2_WR_EN = (WBs_ADR_i[9])? SRAM_WR_EN: 1'b0;


r512x32_2048x8 u_r512x32_2048x8_1
(
    .WA                 (       SRAM_WR_ADR     ),
    .RA                 (       SRAM_RD_ADR     ),
    .WD                 (		SRAM_WR_DAT	  ),
    .WD_SEL             (       SRAM1_WR_EN     ),
    .RD_SEL             (       1'b1     ),
    .WClk               (       WBs_CLK_i            ),
    .RClk               (       WBs_CLK_i            ),
    .WClk_En            ( 1'b1                    ),
    .RClk_En            ( 1'b1                    ),
    .WEN                (       4'hF      ),
    .RD                 (       SRAM1_RD_DAT     ),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )
);

r512x32_2048x8 u_r512x32_2048x8_2
(
    .WA                 (       SRAM_WR_ADR     ),
    .RA                 (       SRAM_RD_ADR     ),
    .WD                 (		SRAM_WR_DAT	  ),
    .WD_SEL             (       SRAM2_WR_EN     ),
    .RD_SEL             (       1'b1     ),
    .WClk               (       WBs_CLK_i            ),
    .RClk               (       WBs_CLK_i            ),
    .WClk_En            ( 1'b1                    ),
    .RClk_En            ( 1'b1                    ),
    .WEN                (       4'hF      ),
    .RD                 (       SRAM2_RD_DAT     ),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )
);

/*
r512x32_512x32 u_r512x32_512x32_1
(
    .WA                 (       SRAM_WR_ADR     ),
    .RA                 (       SRAM_RD_ADR     ),
    .WD                 (		SRAM_WR_DAT	  ),
    .WD_SEL             (       SRAM1_WR_EN     ),
    .RD_SEL             (       1'b1     ),
    .WClk               (       WBs_CLK_i            ),
    .RClk               (       WBs_CLK_i            ),
    .WClk_En            ( 1'b1                    ),
    .RClk_En            ( 1'b1                    ),
    .WEN                (       4'hF      ),
    .RD                 (       SRAM1_RD_DAT     ),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )
);


r512x32_512x32 u_r512x32_512x32_2
(
    .WA                 (       SRAM_WR_ADR     ),
    .RA                 (       SRAM_RD_ADR     ),
    .WD                 (		SRAM_WR_DAT	  ),
    .WD_SEL             (       SRAM2_WR_EN     ),
    .RD_SEL             (       1'b1     ),
    .WClk               (       WBs_CLK_i            ),
    .RClk               (       WBs_CLK_i            ),
    .WClk_En            ( 1'b1                    ),
    .RClk_En            ( 1'b1                    ),
    .WEN                (       4'hF      ),
    .RD                 (       SRAM2_RD_DAT     ),
    .LS                 ( 1'b0                    ),
	.DS                 ( 1'b0                    ),
	.SD                 ( 1'b0                    ),
	.LS_RB1             ( 1'b0                    ),
	.DS_RB1             ( 1'b0                    ),
	.SD_RB1             ( 1'b0                    )
);
*/

endmodule
