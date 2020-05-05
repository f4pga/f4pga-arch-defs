// -----------------------------------------------------------------------------
// title          : I2C Slave Rx FIFOs (Left & Right) Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_Rx_FIFOs.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Right Rx FIFO and Left Rx FiFO for receiving the right & Left
//              channel I2S data
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version      author                description
// 2017/03/23      1.0        Rakesh Moolacheri     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module i2s_slave_Rx_FIFOs( 

						 i2s_clk_i,
						 
                         WBs_CLK_i,
                         WBs_RST_i,

                         Rx_FIFO_Flush_i,
						 
						 L_RXFIFO_DAT_i,
						 L_RXFIFO_PUSH_i, 
						 
						 R_RXFIFO_DAT_i,
						 R_RXFIFO_PUSH_i, 

						 L_RXFIFO_DAT_o,
                         L_RXFIFO_Pop_i,
                         
						 R_RXFIFO_DAT_o,
                         R_RXFIFO_Pop_i,
						 
						 STEREO_EN_i,
						 LR_CHNL_SEL_i,
						 LR_RXFIFO_DAT_o,
						 LR_Rx_FIFO_Full_o,
						 LR_Rx_FIFO_Empty_o,
						 LR_Rx_FIFO_Level_o,
						 
						 LR_RXFIFO_Pop_i,
						 DMA_Busy_i,

                         L_Rx_FIFO_Empty_o,
                         L_Rx_FIFO_Full_o,
                         L_Rx_FIFO_Level_o,
						 
						 R_Rx_FIFO_Empty_o,
                         R_Rx_FIFO_Full_o,
                         R_Rx_FIFO_Level_o
                         );


//------Port Parameters----------------
//

//
// None at this time
//

//------Port Signals-------------------
//

// Fabric Global Signals
//
input                    i2s_clk_i;

input                    WBs_CLK_i;         // Wishbone Fabric Clock
input                    WBs_RST_i;         // Wishbone Fabric Reset


// Rx FIFO Signals
//
input                    Rx_FIFO_Flush_i;

input            [15:0]  L_RXFIFO_DAT_i;
input                    L_RXFIFO_PUSH_i;

input            [15:0]  R_RXFIFO_DAT_i;
input                    R_RXFIFO_PUSH_i;

output           [15:0]  L_RXFIFO_DAT_o;
input                    L_RXFIFO_Pop_i;

output           [15:0]  R_RXFIFO_DAT_o; 
input                    R_RXFIFO_Pop_i; 

output           [31:0]  LR_RXFIFO_DAT_o;
input                    STEREO_EN_i;
input                    LR_CHNL_SEL_i; 
output                   LR_Rx_FIFO_Full_o; 
output                   LR_Rx_FIFO_Empty_o; 
output            [8:0]  LR_Rx_FIFO_Level_o;

input                    LR_RXFIFO_Pop_i; 
input                    DMA_Busy_i;

output                   L_Rx_FIFO_Full_o;
output                   L_Rx_FIFO_Empty_o;
output            [8:0]  L_Rx_FIFO_Level_o;

output                   R_Rx_FIFO_Full_o;
output                   R_Rx_FIFO_Empty_o;
output            [8:0]  R_Rx_FIFO_Level_o;


// Fabric Global Signals
//
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset
    

// Tx FIFO Signals
//
wire                    Rx_FIFO_Flush_i;

wire            [15:0]  L_RXFIFO_DAT_i;
wire                    L_RXFIFO_PUSH_i;

wire            [15:0]  R_RXFIFO_DAT_i;
wire                    R_RXFIFO_PUSH_i;

wire           [15:0]   L_RXFIFO_DAT_o;
wire                    L_RXFIFO_Pop_i;
wire           [15:0]   L_RXFIFO_DAT;

wire           [15:0]   R_RXFIFO_DAT_o;
wire                    R_RXFIFO_Pop_i;
wire           [15:0]   R_RXFIFO_DAT;

wire           [31:0]   LR_RXFIFO_DAT_o;
wire           [15:0]   LR_RXFIFO_DAT;

wire                    LR_RXFIFO_PUSH;
wire                    STR_RXFIFO_PUSH;
wire                    LR_RXFIFO_PUSH_WBCLK;
wire                    STR_RXFIFO_PUSH_WBCLK;
wire                    STR_RXFIFO_Pop;
wire                    STEREO_EN_i;
wire                    LR_CHNL_SEL_i; 
wire                    LR_Rx_FIFO_Full_o; 
wire                    LR_Rx_FIFO_Empty_o;

wire                    LR_RXFIFO_Pop_i; 
wire                    DMA_Busy_i; 

reg 					L_RXFIFO_PUSH_r, L_RXFIFO_PUSH_r1, L_RXFIFO_PUSH_r2;
reg 					R_RXFIFO_PUSH_r, R_RXFIFO_PUSH_r1, R_RXFIFO_PUSH_r2;

wire   					L_RXFIFO_PUSH;
wire   					R_RXFIFO_PUSH;

wire  					LR_RXFIFO_Pop;
wire   					L_RXFIFO_Pop;
wire   					R_RXFIFO_Pop;

  
// FIFO Flags
//
wire                     L_Rx_FIFO_Full_o;
wire                     L_Rx_FIFO_Empty_o; 
wire			[3:0]	 L_POP_FLAG;

wire                     R_Rx_FIFO_Full_o;
wire                     R_Rx_FIFO_Empty_o; 
wire			[3:0]	 R_POP_FLAG; 

wire			[3:0]	 LR_POP_FLAG;

// Count of FIFO contents
//
reg               [8:0]  L_Rx_FIFO_Level_o;
reg               [8:0]  L_Rx_FIFO_Level_nxt;

reg               [8:0]  R_Rx_FIFO_Level_o;
reg               [8:0]  R_Rx_FIFO_Level_nxt;

reg               [8:0]  LR_Rx_FIFO_Level_o; 
reg               [8:0]  LR_Rx_FIFO_Level_nxt;

wire					 MONO_RXFIFO_PUSH_L; 
wire					 MONO_RXFIFO_PUSH_R;

wire					 L_MONO_RXFIFO_PUSH;
wire					 R_MONO_RXFIFO_PUSH;

reg   					 LR_RXFIFO_PUSH_t; 
reg   					 LR_RXFIFO_PUSH_tr1;
wire					 LR_RXFIFO_PUSH_NEG;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//


//------Logic Operations---------------
//
// Determine when to Flush the FIFOs
//
assign Rx_FIFO_Flush      = WBs_RST_i | Rx_FIFO_Flush_i;

//syncing with WBs_CLK_i clock

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        L_RXFIFO_PUSH_r   <= 1'b0;
		L_RXFIFO_PUSH_r1  <= 1'b0;
		L_RXFIFO_PUSH_r2  <= 1'b0;
		
        R_RXFIFO_PUSH_r   <= 1'b0;
		R_RXFIFO_PUSH_r1  <= 1'b0;
		R_RXFIFO_PUSH_r2  <= 1'b0;
		
    end  
    else
    begin
        L_RXFIFO_PUSH_r   <= L_RXFIFO_PUSH_i;
		L_RXFIFO_PUSH_r1  <= L_RXFIFO_PUSH_r;
		L_RXFIFO_PUSH_r2  <= L_RXFIFO_PUSH_r1;
		
        R_RXFIFO_PUSH_r   <= R_RXFIFO_PUSH_i;
		R_RXFIFO_PUSH_r1  <= R_RXFIFO_PUSH_r;
		R_RXFIFO_PUSH_r2  <= R_RXFIFO_PUSH_r1;

    end  
end

assign L_RXFIFO_PUSH = L_RXFIFO_PUSH_r2 & ~L_RXFIFO_PUSH_r1;
assign R_RXFIFO_PUSH = R_RXFIFO_PUSH_r2 & ~R_RXFIFO_PUSH_r1;

// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        L_Rx_FIFO_Level_o  <= 9'h0;
		R_Rx_FIFO_Level_o  <= 9'h0; 
		LR_Rx_FIFO_Level_o <= 9'h0;
		LR_RXFIFO_PUSH_tr1 <= 1'b0;
    end  
    else
    begin
	    L_Rx_FIFO_Level_o  <= L_Rx_FIFO_Level_nxt;
	    R_Rx_FIFO_Level_o  <= R_Rx_FIFO_Level_nxt;
		LR_Rx_FIFO_Level_o <= LR_Rx_FIFO_Level_nxt;
		LR_RXFIFO_PUSH_tr1 <= LR_RXFIFO_PUSH_t;
    end  
end

// Determine the Rx FIFO Level  
//
assign LR_RXFIFO_PUSH_WBCLK  = (LR_CHNL_SEL_i)? R_RXFIFO_PUSH: L_RXFIFO_PUSH;

always @( posedge WBs_CLK_i or posedge Rx_FIFO_Flush)
begin
    if (Rx_FIFO_Flush)
    begin
         LR_RXFIFO_PUSH_t  <= 1'b0;
    end  
    else
    begin
	  if (LR_RXFIFO_PUSH_WBCLK)
		 LR_RXFIFO_PUSH_t  <= ~LR_RXFIFO_PUSH_t;
	  else
	     LR_RXFIFO_PUSH_t  <=  LR_RXFIFO_PUSH_t;
    end  
end

assign LR_RXFIFO_PUSH_NEG = LR_RXFIFO_PUSH_tr1 & ~LR_RXFIFO_PUSH_t;
assign STR_RXFIFO_PUSH_WBCLK = (STEREO_EN_i)? 1'b0 : LR_RXFIFO_PUSH_NEG;
assign STR_RXFIFO_Pop = (STEREO_EN_i)? 1'b0 : LR_RXFIFO_Pop;

always @( STR_RXFIFO_Pop            or
          STR_RXFIFO_PUSH_WBCLK     or
          Rx_FIFO_Flush_i           or
          LR_Rx_FIFO_Level_o
         )
begin

    case(Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({STR_RXFIFO_Pop, STR_RXFIFO_PUSH_WBCLK})
        2'b00: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one word
        2'b10: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one word
        2'b11: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      LR_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end 


assign LR_RXFIFO_Pop = (DMA_Busy_i)? LR_RXFIFO_Pop_i : L_RXFIFO_Pop_i; 
assign L_RXFIFO_Pop = (STEREO_EN_i)? LR_RXFIFO_Pop : 1'b0;
assign MONO_RXFIFO_PUSH_L = (STEREO_EN_i)? L_RXFIFO_PUSH : 1'b0;

always @( L_RXFIFO_Pop           or
          MONO_RXFIFO_PUSH_L     or
          Rx_FIFO_Flush_i        or
          L_Rx_FIFO_Level_o
         )
begin

    case(Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({L_RXFIFO_Pop, MONO_RXFIFO_PUSH_L})
        2'b00: L_Rx_FIFO_Level_nxt <= L_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: L_Rx_FIFO_Level_nxt <= L_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: L_Rx_FIFO_Level_nxt <= L_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: L_Rx_FIFO_Level_nxt <= L_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      L_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end 

assign R_RXFIFO_Pop = (STEREO_EN_i)? LR_RXFIFO_Pop : 1'b0;
assign MONO_RXFIFO_PUSH_R = (STEREO_EN_i)? R_RXFIFO_PUSH : 1'b0;

always @( R_RXFIFO_Pop           or
          MONO_RXFIFO_PUSH_R     or
          Rx_FIFO_Flush_i        or
          R_Rx_FIFO_Level_o
         )
begin

    case(Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({R_RXFIFO_Pop, MONO_RXFIFO_PUSH_R})
        2'b00: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      R_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end 


// Determine the Rx FIFO Empty Flag
//
assign L_Rx_FIFO_Empty_o = (L_POP_FLAG == 4'h0)? 1'b1 : 1'b0;
assign R_Rx_FIFO_Empty_o = (R_POP_FLAG == 4'h0)? 1'b1 : 1'b0;

assign L_Rx_FIFO_Full_o = (L_POP_FLAG == 4'hF)? 1'b1 : 1'b0;
assign R_Rx_FIFO_Full_o = (R_POP_FLAG == 4'hF)? 1'b1 : 1'b0;

assign LR_Rx_FIFO_Full_o = (LR_POP_FLAG == 4'hF)? 1'b1 : 1'b0; 
assign LR_Rx_FIFO_Empty_o = (LR_POP_FLAG == 4'h0)? 1'b1 : 1'b0;


// Match port sizes
//
// Note: The FIFO's contents are undefine prior to the first Push. Therefore,
//       the output should be forced to a default (i.e. "safe") value.
//
assign L_RXFIFO_DAT_o      = L_Rx_FIFO_Empty_o ? 16'h0 : L_RXFIFO_DAT;
assign R_RXFIFO_DAT_o      = R_Rx_FIFO_Empty_o ? 16'h0 : R_RXFIFO_DAT;

//------Instantiate Modules------------
//

// Left Receive FIFO - Base on AL4S3B 512x16 FIFO
//
assign L_MONO_RXFIFO_PUSH = (STEREO_EN_i)? L_RXFIFO_PUSH_i: 1'b0;

af512x16_512x16                u_af512x16_512x16_L
                            (
        .DIN                ( L_RXFIFO_DAT_i		),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( L_MONO_RXFIFO_PUSH    ),
        .POP                ( L_RXFIFO_Pop          ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( L_POP_FLAG            ),
        .DOUT               ( L_RXFIFO_DAT          )
        );

// Right Receive FIFO - Base on AL4S3B 512x16 FIFO
//
assign R_MONO_RXFIFO_PUSH = (STEREO_EN_i)? R_RXFIFO_PUSH_i: 1'b0;

af512x16_512x16                u_af512x16_512x16_R
                            (
        .DIN                ( R_RXFIFO_DAT_i		),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( R_MONO_RXFIFO_PUSH    ),
        .POP                ( R_RXFIFO_Pop          ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( R_POP_FLAG            ),
        .DOUT               ( R_RXFIFO_DAT          )
        );
		
		
		
assign LR_RXFIFO_DAT   = (LR_CHNL_SEL_i)? R_RXFIFO_DAT_i: L_RXFIFO_DAT_i;
assign LR_RXFIFO_PUSH  = (LR_CHNL_SEL_i)? R_RXFIFO_PUSH_i: L_RXFIFO_PUSH_i;
assign STR_RXFIFO_PUSH = (STEREO_EN_i)? 1'b0 : LR_RXFIFO_PUSH;

// Right/Left Receive FIFO - Base on AL4S3B af1024x16_512x32 FIFO
//
af1024x16_512x32                u_af1024x16_512x32_LR
                            (
        .DIN                ( LR_RXFIFO_DAT		    ),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( STR_RXFIFO_PUSH       ),
        .POP                ( STR_RXFIFO_Pop        ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( LR_POP_FLAG           ),
        .DOUT               ( LR_RXFIFO_DAT_o       )
        );
endmodule
