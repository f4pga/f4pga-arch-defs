// -----------------------------------------------------------------------------
// title          : I2C Master with Command Queue Tx FIFO Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_CmdQueue_Tx_FIFO.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2C Master with Command Queue is designed for use in the 
//              fabric of the AL4S3B. The only AL4S3B specific portion is the Tx
//              FIFO. 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/03/11      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module I2C_Master_w_CmdQueue_Tx_FIFO( 


                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,

                         WBs_ACK_o,

                         Tx_FIFO_Flush_i,
						 
						 LCD_TXFIFO_DAT_i,
						 LCD_TXFIFO_PUSH_i,
						 LCD_CNTL_Busy_i,

                         Tx_FIFO_Pop_i,
                         Tx_FIFO_DAT_o,
                         Tx_FIFO_BYTE_STB_o,

                         Tx_FIFO_Empty_o,
                         Tx_FIFO_Full_o,
                         Tx_FIFO_Level_o

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
input                    WBs_CLK_i;         // Wishbone Fabric Clock
input                    WBs_RST_i;         // Wishbone Fabric Reset

input                    WBs_CYC_i;
input                    WBs_WE_i ;
input             [3:0]  WBs_BYTE_STB_i;
input                    WBs_STB_i;
input            [31:0]  WBs_DAT_i;

output                   WBs_ACK_o;


// Tx FIFO Signals
//
input                    Tx_FIFO_Flush_i;

input            [35:0]  LCD_TXFIFO_DAT_i;
input                    LCD_TXFIFO_PUSH_i;
input                    LCD_CNTL_Busy_i;

input                    Tx_FIFO_Pop_i;

output           [31:0]  Tx_FIFO_DAT_o;
output            [3:0]  Tx_FIFO_BYTE_STB_o;

output                   Tx_FIFO_Empty_o;
output                   Tx_FIFO_Full_o;
output            [8:0]  Tx_FIFO_Level_o;


// Fabric Global Signals
//
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset

wire                     WBs_CYC_i;
wire                     WBs_WE_i ;
wire              [3:0]  WBs_BYTE_STB_i;
wire                     WBs_STB_i;
wire             [31:0]  WBs_DAT_i;

reg                      WBs_ACK_o;
wire                     WBs_ACK_o_nxt;

// Tx FIFO Signals
//
wire                     Tx_FIFO_Flush_i;

wire                     Tx_FIFO_Pop_i;

wire             [31:0]  Tx_FIFO_DAT_o;
wire              [3:0]  Tx_FIFO_BYTE_STB_o;


// FIFO Flags
//
reg                      Tx_FIFO_Empty_o;
reg                      Tx_FIFO_Empty_o_nxt;

reg                      Tx_FIFO_Full_o;
reg                      Tx_FIFO_Full_o_nxt;


// Count of FIFO contents
//
reg               [8:0]  Tx_FIFO_Level_o;
reg               [8:0]  Tx_FIFO_Level_o_nxt;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//


// Transmitter Bus Matching
//
wire             [31:0]  Tx_DAT_Out;
wire              [3:0]  Tx_BYTE_STB_Out;


// Local Flush Signal
//
wire                     Tx_FIFO_Flush;

wire                     Tx_FIFO_Push;
wire                     Tx_FIFO_Push_int;
wire 			[35:0]	 Tx_FIFO_DIN;



//------Logic Operations---------------
//

// Define the acknowledge to Wishbone write transfers
//
assign WBs_ACK_o_nxt = WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o);


// Define the "Push" into the FIFO from the Wishbone Write Cycle
//
// Note: The "Push" is timed to have one cycle of setup and one cycle of hold time.
//
assign Tx_FIFO_Push_int  = WBs_CYC_i & WBs_STB_i & WBs_WE_i & (~WBs_ACK_o) & (~WBs_RST_i);


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        Tx_FIFO_Level_o <= 9'h0;
		Tx_FIFO_Empty_o <= 1'b1;
		Tx_FIFO_Full_o  <= 1'b0;

        WBs_ACK_o       <= 1'b0;
    end  
    else
    begin
        Tx_FIFO_Level_o <= Tx_FIFO_Level_o_nxt;
		Tx_FIFO_Empty_o <= Tx_FIFO_Empty_o_nxt;
		Tx_FIFO_Full_o  <= Tx_FIFO_Full_o_nxt;

        WBs_ACK_o       <= WBs_ACK_o_nxt;
    end  
end


// Determine the Tx FIFO Level
//
always @( Tx_FIFO_Pop_i          or
          Tx_FIFO_Push           or
          Tx_FIFO_Flush_i        or
          Tx_FIFO_Level_o
         )
begin

    case(Tx_FIFO_Flush_i)
    1'b0:
    begin
        case({Tx_FIFO_Pop_i, Tx_FIFO_Push})
        2'b00: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      Tx_FIFO_Level_o_nxt <=  9'h0                 ;
    endcase

end 


// Determine the Tx FIFO Empty Flag
//
always @( Tx_FIFO_Pop_i          or
          Tx_FIFO_Push           or
          Tx_FIFO_Flush_i        or
          Tx_FIFO_Level_o        or
          Tx_FIFO_Empty_o
         )
begin

    case(Tx_FIFO_Flush_i)
    1'b0:
    begin
        case({Tx_FIFO_Pop_i, Tx_FIFO_Push})
        2'b00: Tx_FIFO_Empty_o_nxt <=  Tx_FIFO_Empty_o                         ;  // No Operation -> Hold
        2'b01: Tx_FIFO_Empty_o_nxt <=  1'b0                                    ;  // Push         -> add      one byte
        2'b10: Tx_FIFO_Empty_o_nxt <= (Tx_FIFO_Level_o == 9'h001) ? 1'b1 : 1'b0;  // Pop          -> subtract one byte
        2'b11: Tx_FIFO_Empty_o_nxt <=  Tx_FIFO_Empty_o                         ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      Tx_FIFO_Empty_o_nxt <=  1'b1                                    ;  // Rest -> Clear the flag
    endcase

end 

// Determine the Tx FIFO Full Flag
//
always @( Tx_FIFO_Pop_i          or
          Tx_FIFO_Push           or
          Tx_FIFO_Flush_i        or
          Tx_FIFO_Level_o        or
          Tx_FIFO_Full_o
         )
begin

    case(Tx_FIFO_Flush_i)
    1'b0:
    begin
        case({Tx_FIFO_Pop_i, Tx_FIFO_Push})
        2'b00: Tx_FIFO_Full_o_nxt <=  Tx_FIFO_Full_o                          ;  // No Operation -> Hold
        2'b01: Tx_FIFO_Full_o_nxt <= (Tx_FIFO_Level_o == 9'h1FE) ? 1'b1 : 1'b0;  // Push         -> add      one byte
        2'b10: Tx_FIFO_Full_o_nxt <=  1'b0                                    ;  // Pop          -> subtract one byte
        2'b11: Tx_FIFO_Full_o_nxt <=  Tx_FIFO_Full_o                          ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      Tx_FIFO_Full_o_nxt <=  1'b0                                    ;  // Rest -> Clear the flag
    endcase

end 



// Determine when to Flush the FIFOs
//
assign Tx_FIFO_Flush      = WBs_RST_i | Tx_FIFO_Flush_i;


// Match port sizes
//
// Note: The FIFO's contents are undefine prior to the first Push. Therefore,
//       the output should be forced to a default (i.e. "safe") value.
//
assign Tx_FIFO_DAT_o      = Tx_FIFO_Empty_o ? 32'h0 : Tx_DAT_Out;
assign Tx_FIFO_BYTE_STB_o = Tx_FIFO_Empty_o ?  4'h0 : Tx_BYTE_STB_Out  ;


//------Instantiate Modules------------
//
assign Tx_FIFO_Push = (LCD_CNTL_Busy_i)? LCD_TXFIFO_PUSH_i: Tx_FIFO_Push_int;
assign Tx_FIFO_DIN  = (LCD_CNTL_Busy_i)? LCD_TXFIFO_DAT_i: {WBs_BYTE_STB_i,WBs_DAT_i};

// Transmit FIFO - Base on AL4S3B 512x36 FIFO
//

f512x36_512x36                u_CQ_tx_fifo
                            (
        .DIN                (Tx_FIFO_DIN			),
        .Fifo_Push_Flush    ( Tx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Tx_FIFO_Flush         ),
        .PUSH               ( Tx_FIFO_Push          ),
        .POP                ( Tx_FIFO_Pop_i         ),
        .Clk                ( WBs_CLK_i             ),
        .Clk_En             ( 1'b1                  ),
        .Fifo_Dir           ( 1'b1                  ),
        .Async_Flush        ( Tx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           (                       ),
        .DOUT               ({Tx_BYTE_STB_Out        ,
                              Tx_DAT_Out           })
                                                    );


endmodule
