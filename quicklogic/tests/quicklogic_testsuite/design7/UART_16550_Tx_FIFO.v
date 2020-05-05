// -----------------------------------------------------------------------------
// title          : UART 16550 Tx FIFO Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550_Tx_FIFO.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/22	
// last update    : 2016/02/22
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The UART 16550 is designed for use in the fabric of the
//              AL4S3B. The only AL4S3B specific portion are the Rx and Tx
//              FIFOs. The remaining logic is a generic UART based on a single
//              clock network. There are no derived clocks as in some designs.
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


module UART_16550_Tx_FIFO( 


                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_DAT_i,

                         Tx_FIFO_Flush_i,

                         Tx_FIFO_Push_i,

                         Tx_FIFO_Pop_i,
                         Tx_FIFO_DAT_o,

                         Tx_FIFO_Empty_o,
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

input             [7:0]  WBs_DAT_i;


// Tx FIFO Signals
//
input                    Tx_FIFO_Flush_i;

input                    Tx_FIFO_Push_i;

input                    Tx_FIFO_Pop_i;
output            [7:0]  Tx_FIFO_DAT_o;

output                   Tx_FIFO_Empty_o;

output            [8:0]  Tx_FIFO_Level_o;

// Fabric Global Signals
//
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset


wire              [7:0]  WBs_DAT_i;


// Tx FIFO Signals
//
wire                     Tx_FIFO_Flush_i;

wire                     Tx_FIFO_Push_i;

wire                     Tx_FIFO_Pop_i;
wire              [7:0]  Tx_FIFO_DAT_o;


// FIFO Flags
//
reg                      Tx_FIFO_Empty_o;
reg                      Tx_FIFO_Empty_o_nxt;

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
wire              [8:0]  Tx_DAT_Out;

// Local Flush Signal
//
wire                     Tx_FIFO_Flush;



//------Logic Operations---------------
//


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        Tx_FIFO_Level_o <= 9'h0;
		Tx_FIFO_Empty_o <= 1'b1;
    end  
    else
    begin
        Tx_FIFO_Level_o <= Tx_FIFO_Level_o_nxt;
		Tx_FIFO_Empty_o <= Tx_FIFO_Empty_o_nxt;
    end  
end


// Determine the Tx FIFO Level
//
always @( Tx_FIFO_Pop_i          or
          Tx_FIFO_Push_i         or
          Tx_FIFO_Flush_i        or
          Tx_FIFO_Level_o
         )
begin

    case(Tx_FIFO_Flush_i)
    1'b0:
    begin
        case({Tx_FIFO_Pop_i, Tx_FIFO_Push_i})
        2'b00: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: Tx_FIFO_Level_o_nxt <= Tx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      Tx_FIFO_Level_o_nxt <=  9'h0;
    endcase

end 


// Determine the Tx FIFO Empty Flag
//
always @( Tx_FIFO_Pop_i          or
          Tx_FIFO_Push_i         or
          Tx_FIFO_Flush_i        or
          Tx_FIFO_Level_o        or
          Tx_FIFO_Empty_o
         )
begin

    case(Tx_FIFO_Flush_i)
    1'b0:
    begin
        case({Tx_FIFO_Pop_i, Tx_FIFO_Push_i})
        2'b00: Tx_FIFO_Empty_o_nxt <=  Tx_FIFO_Empty_o                         ;  // No Operation -> Hold
        2'b01: Tx_FIFO_Empty_o_nxt <=  1'b0                                    ;  // Push         -> add      one byte
        2'b10: Tx_FIFO_Empty_o_nxt <= (Tx_FIFO_Level_o == 9'h001) ? 1'b1 : 1'b0;  // Pop          -> subtract one byte
        2'b11: Tx_FIFO_Empty_o_nxt <=  Tx_FIFO_Empty_o                         ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      Tx_FIFO_Empty_o_nxt <=  1'b1;  // Rest -> Clear the flag
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
assign Tx_FIFO_DAT_o     = Tx_FIFO_Empty_o ? 8'h0 : Tx_DAT_Out[7:0];


//------Instantiate Modules------------
//

// Transmit FIFO - Base on AL4S3B 512x9 FIFO
//
f512x9_512x9 u_tx_fifo      (
		.DIN                ( {1'b0, WBs_DAT_i}     ),
		.Fifo_Push_Flush    ( Tx_FIFO_Flush         ),
		.Fifo_Pop_Flush     ( Tx_FIFO_Flush         ),
		.PUSH               ( Tx_FIFO_Push_i        ),
		.POP                ( Tx_FIFO_Pop_i         ),
		.Clk                ( WBs_CLK_i             ),
        .Clk_En             ( 1'b1                  ),
	    .Fifo_Dir           ( 1'b1                  ),
	    .Async_Flush        ( Tx_FIFO_Flush         ),
        .Almost_Full        (                       ),
	    .Almost_Empty       (                       ),
	    .PUSH_FLAG          (                       ),
	    .POP_FLAG           (                       ),
	    .DOUT               ( Tx_DAT_Out            ) 
        );


endmodule
