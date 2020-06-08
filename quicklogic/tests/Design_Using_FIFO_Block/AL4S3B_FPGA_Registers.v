// -----------------------------------------------------------------------------
// title          : AL4S3B Example FPGA Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_FPGA_Registers.v
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
// date            version    author                  description
// 2020/05/27      1.0        Rakesh moolacheri     Initial Release
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
						 WBs_RD_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_CLK_i,
                         WBs_RST_i,
                         WBs_DAT_o,
                         WBs_ACK_o,

                         //
                         // Misc
                         //
						 CLK_4M_CNTL_o,
						 CLK_1M_CNTL_o,
                         Device_ID_o,
						 	 
				         GPIO_IN_i,
				         GPIO_OUT_o,
				         GPIO_OE_o

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   9  ;   // Allow for up to 128 registers in the FPGA
parameter                DATAWIDTH                   =  32  ;   // Allow for up to 128 registers in the FPGA

parameter                FPGA_REG_ID_VALUE_ADR     =  9'h0; 
parameter                FPGA_REV_NUM_ADR          =  9'h1; 
parameter                FPGA_GPIO_IN_REG_ADR      =  9'h2; 
parameter                FPGA_GPIO_OUT_REG_ADR     =  9'h3; 
parameter                FPGA_GPIO_OE_REG_ADR      =  9'h4; 

parameter       		 FPGA_FIFO1_ACC_ADR        =  9'h40; 
parameter       		 FPGA_FIFO1_FLAG_ADR       =  9'h41; 
parameter       		 FPGA_FIFO2_ACC_ADR        =  9'h80; 
parameter       		 FPGA_FIFO2_FLAG_ADR       =  9'h81; 
parameter       		 FPGA_FIFO3_ACC_ADR        =  9'h100; 
parameter       		 FPGA_FIFO3_FLAG_ADR       =  9'h101; 

parameter                AL4S3B_DEVICE_ID            = 16'h0;
parameter                AL4S3B_REV_LEVEL            = 32'h0;
parameter                AL4S3B_GPIO_REG             = 8'h0;
parameter                AL4S3B_GPIO_OE_REG          = 8'h0;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   FPGA
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   FPGA
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   FPGA
input                    WBs_WE_i      ;  // Write Enable               to   FPGA
input           		 WBs_RD_i        ;  // Read  Enable               to   FPGA
input                    WBs_STB_i     ;  // Strobe Signal              to   FPGA
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   FPGA
input                    WBs_CLK_i     ;  // FPGA Clock               from FPGA
input                    WBs_RST_i     ;  // FPGA Reset               to   FPGA
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from FPGA
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from FPGA

//
// Misc
//
output           [31:0]  Device_ID_o   ;

output 					 CLK_4M_CNTL_o;
output 					 CLK_1M_CNTL_o;

// GPIO
//
input            [7:0]  GPIO_IN_i     ;
output           [7:0]  GPIO_OUT_o    ;
output           [7:0]  GPIO_OE_o     ;



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
wire                     WBs_RD_i      ;  // Wishbone Read  Enable Strobe
wire                     WBs_STB_i     ;  // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Wishbone Read   Data Bus

reg                      WBs_ACK_o     ;  // Wishbone Client Acknowledge

// Misc
//
wire               [31:0]  Device_ID_o   ;
wire               [15:0]  Rev_No        ;

// GPIO
//
wire             [7:0]  GPIO_IN_i     ;
reg              [7:0]  GPIO_OUT_o    ;
reg              [7:0]  GPIO_OE_o     ;

wire [3:0] PUSH_FLAG1;
wire [3:0] POP_FLAG1;
wire [3:0] PUSH_FLAG2;
wire [3:0] POP_FLAG2;
wire [3:0] PUSH_FLAG3;
wire [3:0] POP_FLAG3;

wire       Almost_Full1;
wire       Almost_Empty1;
wire       Almost_Full2;
wire       Almost_Empty2;
wire       Almost_Full3;
wire       Almost_Empty3;

wire [15:0] FIFO1_DOUT;
wire [15:0] FIFO2_DOUT;
wire [31:0] FIFO3_DOUT;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     FB_GPIO_Reg_Wr_Dcd    ;
wire                     FB_GPIO_OE_Reg_Wr_Dcd ;

wire                     FB_FIFO1_Wr_Dcd    ;
wire                     FB_FIFO2_Wr_Dcd    ;
wire                     FB_FIFO3_Wr_Dcd    ;

wire					 WBs_ACK_o_nxt;

wire					 FB_FIFO1_Rd_Dcd;
wire					 FB_FIFO2_Rd_Dcd;
wire					 FB_FIFO3_Rd_Dcd;

reg 					 pop1_r;  
reg 					 pop1_r1; 
reg 					 pop1_r2; 
reg 					 pop2_r;  
reg 					 pop2_r1; 
reg 					 pop2_r2;
reg 					 pop3_r;  
reg 					 pop3_r1; 
reg 					 pop3_r2; 
 
wire					 pop1;
wire					 pop2;
wire					 pop3;

//------Logic Operations---------------
//
assign CLK_4M_CNTL_o = 1'b0 ;
assign CLK_1M_CNTL_o = 1'b0 ;


// Define the FPGA's local register write enables
//
assign FB_GPIO_Reg_Wr_Dcd    = ( WBs_ADR_i == FPGA_GPIO_OUT_REG_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_GPIO_OE_Reg_Wr_Dcd = ( WBs_ADR_i == FPGA_GPIO_OE_REG_ADR     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);


assign FB_FIFO1_Wr_Dcd    = ( WBs_ADR_i == FPGA_FIFO1_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_FIFO2_Wr_Dcd    = ( WBs_ADR_i == FPGA_FIFO2_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FB_FIFO3_Wr_Dcd    = ( WBs_ADR_i == FPGA_FIFO3_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

assign FB_FIFO1_Rd_Dcd    = ( WBs_ADR_i == FPGA_FIFO1_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i) & (~WBs_ACK_o);
assign FB_FIFO2_Rd_Dcd    = ( WBs_ADR_i == FPGA_FIFO2_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i) & (~WBs_ACK_o);
assign FB_FIFO3_Rd_Dcd    = ( WBs_ADR_i == FPGA_FIFO3_ACC_ADR ) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i) & (~WBs_ACK_o);

// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the FPGA's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        GPIO_OUT_o        <= AL4S3B_GPIO_REG     ;
        GPIO_OE_o         <= AL4S3B_GPIO_OE_REG  ;
        WBs_ACK_o         <=  1'b0               ;
		pop1_r            <=  1'b0               ;
		pop1_r1           <=  1'b0               ;
		pop1_r2           <=  1'b0               ;
		pop2_r            <=  1'b0               ;
		pop2_r1           <=  1'b0               ;
		pop2_r2           <=  1'b0               ;
		pop3_r            <=  1'b0               ;
		pop3_r1           <=  1'b0               ;
		pop3_r2           <=  1'b0               ;
    end  
    else
    begin
        // Define the GPIO Register 
        //
        if(FB_GPIO_Reg_Wr_Dcd    && WBs_BYTE_STB_i[0]) 
			GPIO_OUT_o[7:0]         <= WBs_DAT_i[7:0]  ;

        // Define the GPIO Control Register 
        //
        if(FB_GPIO_OE_Reg_Wr_Dcd && WBs_BYTE_STB_i[0])
			GPIO_OE_o[7:0]          <= WBs_DAT_i[7:0]  ;

        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
		
		pop1_r            <=  FB_FIFO1_Rd_Dcd       ;
		pop1_r1           <=  pop1_r          		;
		pop1_r2           <=  pop1_r1         		;
		
		pop2_r            <=  FB_FIFO2_Rd_Dcd       ;
		pop2_r1           <=  pop2_r          		;
		pop2_r2           <=  pop2_r1         		;
		
		pop3_r            <=  FB_FIFO3_Rd_Dcd       ;
		pop3_r1           <=  pop3_r          		;
		pop3_r2           <=  pop3_r1         		;
		
    end  
end

// Define the how to read the local registers and memory
//
assign Device_ID_o = 32'hF1F07E57 ;
assign Rev_No = 16'h100 ;
always @(
         WBs_ADR_i         or
         Device_ID_o       or
         Rev_No  		   or
         GPIO_IN_i         or
         GPIO_OUT_o        or
         GPIO_OE_o         or   
         FIFO1_DOUT        or
		 PUSH_FLAG1        or	
		 POP_FLAG1         or
		 Almost_Full1      or
		 Almost_Empty1     or
         FIFO2_DOUT        or
		 PUSH_FLAG2        or	
		 POP_FLAG2         or
		 Almost_Full2      or
		 Almost_Empty2     or
         FIFO3_DOUT        or
		 PUSH_FLAG3        or	
		 POP_FLAG3         or
		 Almost_Full3      or
		 Almost_Empty3     
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    FPGA_REG_ID_VALUE_ADR     : WBs_DAT_o <= Device_ID_o;
    FPGA_REV_NUM_ADR          : WBs_DAT_o <= { 16'h0, Rev_No };  
    FPGA_GPIO_IN_REG_ADR      : WBs_DAT_o <= { 24'h0, GPIO_IN_i[7:0] };
    FPGA_GPIO_OUT_REG_ADR     : WBs_DAT_o <= { 24'h0, GPIO_OUT_o[7:0] };
    FPGA_GPIO_OE_REG_ADR      : WBs_DAT_o <= { 24'h0, GPIO_OE_o[7:0] };  
	FPGA_FIFO1_ACC_ADR        : WBs_DAT_o <= { 16'h0, FIFO1_DOUT };
	FPGA_FIFO1_FLAG_ADR       : WBs_DAT_o <= { 16'h0,Almost_Empty1,3'h0,POP_FLAG1,Almost_Full1,3'h0,PUSH_FLAG1 };
	FPGA_FIFO2_ACC_ADR        : WBs_DAT_o <= { 16'h0, FIFO2_DOUT };
	FPGA_FIFO2_FLAG_ADR       : WBs_DAT_o <= { 16'h0,Almost_Empty2,3'h0,POP_FLAG2,Almost_Full2,3'h0,PUSH_FLAG2 };
	FPGA_FIFO3_ACC_ADR        : WBs_DAT_o <= FIFO3_DOUT ;
	FPGA_FIFO3_FLAG_ADR       : WBs_DAT_o <= { 16'h0,Almost_Empty3,3'h0,POP_FLAG3,Almost_Full3,3'h0,PUSH_FLAG3 };
	default                   : WBs_DAT_o <= AL4S3B_DEF_REG_VALUE;
	endcase
end

assign pop1 = pop1_r1 & (~pop1_r2);
assign pop2 = pop2_r1 & (~pop2_r2);

af512x16_512x16_f512x16_512x16 FIFO1FIFO2_INST     (
				.DIN0(WBs_DAT_i[15:0]),
				.PUSH0(FB_FIFO1_Wr_Dcd),
				.POP0(pop1),
				.Fifo_Push_Flush0(WBs_RST_i),
				.Fifo_Pop_Flush0(WBs_RST_i),
				.Push_Clk0(WBs_CLK_i),
				.Pop_Clk0(WBs_CLK_i),
				.PUSH_FLAG0(PUSH_FLAG1),
				.POP_FLAG0(POP_FLAG1),
				.Push_Clk0_En(1'b1),
				.Pop_Clk0_En(1'b1),
				.Fifo0_Dir(1'b0),
				.Async_Flush0(WBs_RST_i),
				.Almost_Full0(Almost_Full1),
				.Almost_Empty0(Almost_Empty1),
				.DOUT0(FIFO1_DOUT),
				
				.DIN1(WBs_DAT_i[15:0]),
				.PUSH1(FB_FIFO2_Wr_Dcd),
				.POP1(pop2),
				.Fifo_Push_Flush1(WBs_RST_i),
				.Fifo_Pop_Flush1(WBs_RST_i),
				.Clk1(WBs_CLK_i),
				.PUSH_FLAG1(PUSH_FLAG2),
				.POP_FLAG1(POP_FLAG2),
				.Clk1_En(1'b1),
				.Fifo1_Dir(1'b0),
				.Async_Flush1(WBs_RST_i),
				.Almost_Full1(Almost_Full2),
				.Almost_Empty1(Almost_Empty2),
				.DOUT1(FIFO2_DOUT)
				);
				
assign pop3 = pop3_r1 & (~pop3_r2);

af512x32_512x32 FIFO3_INST      (
				.DIN(WBs_DAT_i[31:0]),
				.PUSH(FB_FIFO3_Wr_Dcd),
				.POP(pop3),
				.Fifo_Push_Flush(WBs_RST_i),
				.Fifo_Pop_Flush(WBs_RST_i),
				.Push_Clk(WBs_CLK_i),
				.Pop_Clk(WBs_CLK_i),
				.PUSH_FLAG(PUSH_FLAG3),
				.POP_FLAG(POP_FLAG3),
				.Push_Clk_En(1'b1),
				.Pop_Clk_En(1'b1),
				.Fifo_Dir(1'b0),
				.Async_Flush(WBs_RST_i),
				.Almost_Full(Almost_Full3),
				.Almost_Empty(Almost_Empty3),
				.DOUT(FIFO3_DOUT)
				);

endmodule
