// -----------------------------------------------------------------------------
// title          : UART 16550 Tx Logic Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550_Tx_Logic.v
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


module UART_16550_Tx_Logic( 


                            WBs_CLK_i,
                            WBs_RST_i,

                            WBs_DAT_i,

                            SOUT_o,

                            Tx_FIFO_Push_i,
                            Tx_FIFO_Pop_o,
                            Tx_FIFO_DAT_i,

                            Tx_FIFO_Empty_i,

                            Tx_FIFO_Enable_i,

                            Tx_Word_Length_Select_i,
                            Tx_Number_of_Stop_Bits_i,
                            Tx_Enable_Parity_i,
                            Tx_Even_Parity_Select_i,
                            Tx_Sticky_Parity_i,

                            Tx_Break_Control_i,

                            Rx_Tx_Loop_Back_i,

                            Tx_Clock_Divisor_i,
                            Tx_Clock_Divisor_Load_i,
                            Tx_Baud_16x_o,

                            Tx_Storage_Empty_o,
                            Tx_Logic_Empty_o,

                            Tx_SOUT_o

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
input                       WBs_CLK_i;         // Wishbone Fabric Clock
input                       WBs_RST_i;         // Wishbone Fabric Reset

input                [7:0]  WBs_DAT_i;

output                      SOUT_o;


// Tx FIFO Signals
//
input                       Tx_FIFO_Push_i;
output                      Tx_FIFO_Pop_o;
input                [7:0]  Tx_FIFO_DAT_i;

input                       Tx_FIFO_Empty_i;

input                       Tx_FIFO_Enable_i;

input                [1:0]  Tx_Word_Length_Select_i;
input                       Tx_Number_of_Stop_Bits_i;
input                       Tx_Enable_Parity_i;
input                       Tx_Even_Parity_Select_i;
input                       Tx_Sticky_Parity_i;

input                       Tx_Break_Control_i;

input                       Rx_Tx_Loop_Back_i;

input               [15:0]  Tx_Clock_Divisor_i;
input                       Tx_Clock_Divisor_Load_i;
output                      Tx_Baud_16x_o;


output                      Tx_Storage_Empty_o;
output                      Tx_Logic_Empty_o;

output                      Tx_SOUT_o;

// Fabric Global Signals
//
wire                        WBs_CLK_i;         // Wishbone Fabric Clock
wire                        WBs_RST_i;         // Wishbone Fabric Reset


wire                 [7:0]  WBs_DAT_i;

wire                        SOUT_o;


// Tx FIFO Signals
//
wire                        Tx_FIFO_Push_i;

reg                         Tx_FIFO_Pop_o;
reg                         Tx_FIFO_Pop_o_nxt;

wire                 [7:0]  Tx_FIFO_DAT_i;

wire                        Tx_FIFO_Empty_i;

wire                        Tx_FIFO_Enable_i;

// Tx Control Signals
//
wire                 [1:0]  Tx_Word_Length_Select_i;
wire                        Tx_Number_of_Stop_Bits_i;
wire                        Tx_Enable_Parity_i;
wire                        Tx_Even_Parity_Select_i;
wire                        Tx_Sticky_Parity_i;

wire                        Tx_Break_Control_i;

wire                        Rx_Tx_Loop_Back_i;

wire                [15:0]  Tx_Clock_Divisor_i;
wire                        Tx_Clock_Divisor_Load_i;
wire                        Tx_Baud_16x_o;

wire                        Tx_Storage_Empty_o;
wire                        Tx_Logic_Empty_o;

reg                         Tx_SOUT_o;


//------Define Parameters--------------
//

parameter                   TX_STATE_WIDTH     = 1;

parameter                   TX_STATE_IDLE      = 0;
parameter                   TX_STATE_TRANSFER  = 1;


//------Internal Signals---------------
//

reg                 [15:0]  Tx_Baud_16x_cntr;
reg                 [15:0]  Tx_Baud_16x_cntr_nxt;

reg                         Tx_Baud_16x_cntr_tc;
reg                         Tx_Baud_16x_cntr_tc_nxt;

reg                  [3:0]  Tx_Bit_Time_cntr;
reg                  [3:0]  Tx_Bit_Time_cntr_nxt;

reg                         Tx_Bit_Time_cntr_tc;
reg                         Tx_Bit_Time_cntr_tc_nxt;

reg                         Tx_Bit_Time_cntr_ld;
reg                         Tx_Bit_Time_cntr_ld_nxt;

reg                  [3:0]  Tx_Xfr_Length_cntr;
reg                  [3:0]  Tx_Xfr_Length_cntr_nxt;

reg                         Tx_Xfr_Length_cntr_tc;
reg                         Tx_Xfr_Length_cntr_tc_nxt;

reg                         Tx_Xfr_Length_cntr_ld;
reg                         Tx_Xfr_Length_cntr_ld_nxt;

reg                  [7:0]  Tx_Holding_Reg;

reg                  [9:0]  Tx_Shift_Reg;
reg                  [9:0]  Tx_Shift_Reg_nxt;

reg                         Tx_Shift_Reg_ld;
reg                         Tx_Shift_Reg_ld_nxt;

wire                 [7:0]  Tx_Shift_Reg_Data;

reg                         Tx_Parity_Odd;
reg                         Tx_Parity;

reg   [TX_STATE_WIDTH-1:0]  Tx_State;
reg   [TX_STATE_WIDTH-1:0]  Tx_State_nxt;

reg                         Tx_Transfer_Busy;
reg                         Tx_Transfer_Busy_nxt;

reg                         Tx_Holding_Reg_Empty;
reg                         Tx_Holding_Reg_Empty_nxt;


//------Logic Operations---------------
//

// Determine the Loop Back Connections to the external port
//
assign SOUT_o     = Rx_Tx_Loop_Back_i  ? 1'b1            : Tx_SOUT_o;


// Select the Output Serial Stream
//
always @(Tx_Break_Control_i  or
         Tx_Transfer_Busy    or
         Tx_Shift_Reg
        )
begin
    case({Tx_Break_Control_i, Tx_Transfer_Busy})
    2'b00: Tx_SOUT_o <= 1'b1            ; // Waiting for transfer
    2'b01: Tx_SOUT_o <= Tx_Shift_Reg[0] ; // Select  Tx Shift Register output on the serial stream
    2'b10: Tx_SOUT_o <= 1'b0            ; // Select  "Break"           output on the serial stream
    2'b11: Tx_SOUT_o <= 1'b0            ; // Select  "Break"           output on the serial stream 
    endcase                               //     The "Break" output has priority over data from the
end                                       //     Tx Shift Register.


// Determine the 16x Baud Rate Enable
//
// Note: This design will use this signal to determine its serial transfer
//       rate. This avoids the pitfalls of using derived clocks.
//
assign Tx_Baud_16x_o  = Tx_Baud_16x_cntr_tc;


// Define the Fabric's Local Registers
//

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

        Tx_FIFO_Pop_o            <=  1'b0;

        Tx_Baud_16x_cntr         <= 16'h0;
        Tx_Baud_16x_cntr_tc      <=  1'b0;

        Tx_State                 <= TX_STATE_IDLE;

        Tx_Transfer_Busy         <=  1'b0;

        Tx_Bit_Time_cntr         <=  4'h0;
        Tx_Bit_Time_cntr_tc      <=  1'b1;
        Tx_Bit_Time_cntr_ld      <=  1'b1;

		Tx_Xfr_Length_cntr       <=  4'h0;
		Tx_Xfr_Length_cntr_tc    <=  1'b0;
		Tx_Xfr_Length_cntr_ld    <=  1'b0;

        Tx_Holding_Reg           <=  8'h0;
        Tx_Holding_Reg_Empty     <=  1'b1;

        Tx_Shift_Reg             <= 10'h0;
        Tx_Shift_Reg_ld          <=  1'b1;

    end  
    else
    begin

        Tx_FIFO_Pop_o            <=  Tx_FIFO_Pop_o_nxt          ;

        Tx_Baud_16x_cntr         <=  Tx_Baud_16x_cntr_nxt       ;
        Tx_Baud_16x_cntr_tc      <=  Tx_Baud_16x_cntr_tc_nxt    ;

        Tx_State                 <=  Tx_State_nxt               ;
        Tx_Transfer_Busy         <=  Tx_Transfer_Busy_nxt       ;

        Tx_Bit_Time_cntr         <=  Tx_Bit_Time_cntr_nxt       ;
        Tx_Bit_Time_cntr_tc      <=  Tx_Bit_Time_cntr_tc_nxt    ;
        Tx_Bit_Time_cntr_ld      <=  Tx_Bit_Time_cntr_ld_nxt    ;

		Tx_Xfr_Length_cntr       <=  Tx_Xfr_Length_cntr_nxt     ;
		Tx_Xfr_Length_cntr_tc    <=  Tx_Xfr_Length_cntr_tc_nxt  ;
		Tx_Xfr_Length_cntr_ld    <=  Tx_Xfr_Length_cntr_ld_nxt  ;

        if (Tx_FIFO_Push_i)
            Tx_Holding_Reg       <=  WBs_DAT_i                  ;

        Tx_Holding_Reg_Empty     <=  Tx_Holding_Reg_Empty_nxt   ;

        Tx_Shift_Reg             <=  Tx_Shift_Reg_nxt           ;
        Tx_Shift_Reg_ld          <=  Tx_Shift_Reg_ld_nxt        ;

    end  
end


// Determine when both:
//
//     - all of the Tx data has been retrieved
//     - all of the Tx data has been transmitted.
//
assign Tx_Logic_Empty_o   = Tx_Storage_Empty_o & (~Tx_Transfer_Busy);


// Select the Empty Flag to use
//
// Note: For FIFO operations, the FIFO Empty Flag is used. This is subject to flushing.
//       For non-FIFO operations, the Holding Register is tracked. It is not
//       subject to FIFO Flushing operations.
//
assign Tx_Storage_Empty_o = Tx_FIFO_Enable_i        ?  Tx_FIFO_Empty_i :  Tx_Holding_Reg_Empty;

// Determine the state of the Tx Holding Register
//
always @( Tx_FIFO_Push_i         or
          Tx_FIFO_Pop_o          or
          Tx_FIFO_Enable_i       or
		  Tx_Holding_Reg_Empty
        )
begin
    case(  {Tx_FIFO_Enable_i, Tx_FIFO_Push_i, Tx_FIFO_Pop_o})
    3'b000: Tx_Holding_Reg_Empty_nxt <= Tx_Holding_Reg_Empty ;
    3'b001: Tx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b010: Tx_Holding_Reg_Empty_nxt <= 1'b0                 ;
    3'b011: Tx_Holding_Reg_Empty_nxt <= 1'b0                 ;
    3'b100: Tx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b101: Tx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b110: Tx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b111: Tx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    endcase
end


// Determine the Clock Divider's Counter
//
// Note: This counter divides down the reference clock to a rate used for
//       serial communications.
//
always @(Tx_Baud_16x_cntr        or
         Tx_Baud_16x_cntr_tc     or
         Tx_Clock_Divisor_Load_i or
         Tx_Clock_Divisor_i
         )
begin
    case( Tx_Baud_16x_cntr_tc   |  Tx_Clock_Divisor_Load_i )
    1'b0: Tx_Baud_16x_cntr_nxt <=  Tx_Baud_16x_cntr - 1'b1; // Count down until the terminal count
    1'b1: Tx_Baud_16x_cntr_nxt <=  Tx_Clock_Divisor_i     ; // Load on the terminal count
    endcase
end


// Determine the Clock Divide counter's terminal count
//
always @(Tx_Baud_16x_cntr        or
         Tx_Baud_16x_cntr_tc     or
         Tx_Clock_Divisor_Load_i or
         Tx_Clock_Divisor_i
         )
begin
    case( Tx_Baud_16x_cntr_tc      |  Tx_Clock_Divisor_Load_i )
    1'b0: Tx_Baud_16x_cntr_tc_nxt <= (Tx_Baud_16x_cntr   == 16'h1)  // Determine when the count down is about to complete
                                   | (Tx_Clock_Divisor_i == 16'h0); // Check for the special case of a divisor equal to "0"
    1'b1: Tx_Baud_16x_cntr_tc_nxt <= (Tx_Clock_Divisor_i == 16'h0); // Load on the terminal count
    endcase
end


// Determine the Bit Time Counter
//
// Note: This counter determines the length of time for each bit in the serial 
//       stream. This is done by counting number of Baud_16x periods.
//
//       Start  - 16 Baud_16x periods
//       Data   - 16 Baud_16x periods per bit
//       Parity - 16 Baud_16x periods        
//       Stop   - 16 Baud_16x periods per bit  
//
always @(Tx_Bit_Time_cntr        or
         Tx_Bit_Time_cntr_tc     or
         Tx_Bit_Time_cntr_ld     or
         Tx_Baud_16x_cntr_tc
         )
begin
    case(  { Tx_Bit_Time_cntr_ld,     Tx_Bit_Time_cntr_tc, Tx_Baud_16x_cntr_tc} )
    3'b000:  Tx_Bit_Time_cntr_nxt <=  Tx_Bit_Time_cntr       ; // Hold
    3'b001:  Tx_Bit_Time_cntr_nxt <=  Tx_Bit_Time_cntr - 1'b1; // Count down until the terminal count
    3'b010:  Tx_Bit_Time_cntr_nxt <=  Tx_Bit_Time_cntr       ; // Hold
    default: Tx_Bit_Time_cntr_nxt <=  4'hF                   ; // Load on the terminal count
    endcase
end


// Determine the Bit Time counter's terminal count
//
always @(Tx_Bit_Time_cntr        or
         Tx_Bit_Time_cntr_tc     or
         Tx_Bit_Time_cntr_ld     or
         Tx_Baud_16x_cntr_tc
         )
begin
    case(   {Tx_Bit_Time_cntr_ld,        Tx_Baud_16x_cntr_tc} )
    2'b00:   Tx_Bit_Time_cntr_tc_nxt <=  Tx_Bit_Time_cntr_tc        ; // Hold
    2'b01:   Tx_Bit_Time_cntr_tc_nxt <= (Tx_Bit_Time_cntr ==  4'h1) ; // Check count down for terminal count
    default: Tx_Bit_Time_cntr_tc_nxt <=  1'b0                       ; // The terminal count is "0" during loads
    endcase
end


// Determine the Transfer Length Counter
//
// Note: This counter counts the number of bits that will be transferred in 
//       the serial stream.
//
//  Tx_Word_Length_Select_i[1:0]   Tx_Number_of_Stop_Bits_i;
//              ANY                          1'b0 : 1
//          2'b00 : 5 bits                   1'b1 : 1.5
//          2'b01 : 6 bits                   1'b1 : 2
//          2'b10 : 7 bits                   1'b1 : 2
//          2'b11 : 8 bits                   1'b1 : 2
//

always @(Tx_Xfr_Length_cntr         or
         Tx_Xfr_Length_cntr_tc      or
         Tx_Xfr_Length_cntr_ld      or

         Tx_Baud_16x_cntr_tc        or
         Tx_Bit_Time_cntr_tc        or

         Tx_Enable_Parity_i         or
		 Tx_Number_of_Stop_Bits_i   or
		 Tx_Word_Length_Select_i
         )
begin
    case(       {Tx_Xfr_Length_cntr_ld,     Tx_Xfr_Length_cntr_tc, Tx_Bit_Time_cntr_tc, Tx_Baud_16x_cntr_tc} )
    4'b0000:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    4'b0001:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    4'b0010:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    4'b0011:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr - 1'b1 ; // Count down until the terminal count
    4'b0100:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    4'b0101:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    4'b0110:     Tx_Xfr_Length_cntr_nxt <=  Tx_Xfr_Length_cntr        ; // Hold
    default:
    begin
        case (  {Tx_Enable_Parity_i,  Tx_Number_of_Stop_Bits_i, Tx_Word_Length_Select_i})
        4'b0000: Tx_Xfr_Length_cntr_nxt <=  4'h6                      ; // Start, 5 bits,         Stop bits -> 1
        4'b0001: Tx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 6 bits,         Stop bits -> 1
        4'b0010: Tx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 7 bits,         Stop bits -> 1
        4'b0011: Tx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 8 bits,         Stop bits -> 1

        4'b0100: Tx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 5 bits,         Stop bits -> 2 (Allowed)
        4'b0101: Tx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 6 bits,         Stop bits -> 2
        4'b0110: Tx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 7 bits,         Stop bits -> 2
        4'b0111: Tx_Xfr_Length_cntr_nxt <=  4'hA                      ; // Start, 8 bits,         Stop bits -> 2

        4'b1000: Tx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 5 bits, Parity  Stop bits -> 1
        4'b1001: Tx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 6 bits, Parity  Stop bits -> 1
        4'b1010: Tx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 7 bits, Parity  Stop bits -> 1
        4'b1011: Tx_Xfr_Length_cntr_nxt <=  4'hA                      ; // Start, 8 bits, Parity  Stop bits -> 1

        4'b1100: Tx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 5 bits, Parity, Stop bits -> 2 (Allowed)
        4'b1101: Tx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 6 bits, Parity, Stop bits -> 2
        4'b1110: Tx_Xfr_Length_cntr_nxt <=  4'hA                      ; // Start, 7 bits, Parity, Stop bits -> 2
        4'b1111: Tx_Xfr_Length_cntr_nxt <=  4'hB                      ; // Start, 8 bits, Parity, Stop bits -> 2
        endcase
    end
    endcase
end


// Determine the Transfer Length counter's terminal count
//
always @(Tx_Xfr_Length_cntr        or
         Tx_Xfr_Length_cntr_tc     or
         Tx_Xfr_Length_cntr_ld     or

         Tx_Baud_16x_cntr_tc       or
         Tx_Bit_Time_cntr_tc
         )
begin
    case(    {Tx_Xfr_Length_cntr_ld, Tx_Bit_Time_cntr_tc, Tx_Baud_16x_cntr_tc} )
    3'b000:   Tx_Xfr_Length_cntr_tc_nxt <=  Tx_Xfr_Length_cntr_tc        ; // Hold
    3'b001:   Tx_Xfr_Length_cntr_tc_nxt <=  Tx_Xfr_Length_cntr_tc        ; // Hold
    3'b010:   Tx_Xfr_Length_cntr_tc_nxt <=  Tx_Xfr_Length_cntr_tc        ; // Hold
    3'b011:   Tx_Xfr_Length_cntr_tc_nxt <= (Tx_Xfr_Length_cntr ==  4'h1) ; // Check count down for terminal count
    default:  Tx_Xfr_Length_cntr_tc_nxt <=  1'b0                         ; // The terminal count is "0" during loads
    endcase
end


// Select the Shift Register's Data Source
//
assign Tx_Shift_Reg_Data = Tx_FIFO_Enable_i ? Tx_FIFO_DAT_i : Tx_Holding_Reg;


// Determine Odd Parity
//
// Note: The bits used for the parity calculation will vary due to data field length
//
always @(Tx_Shift_Reg_Data        or
         Tx_Word_Length_Select_i
         )
begin

    case( {Tx_Word_Length_Select_i})
    2'b00: Tx_Parity_Odd <=  ^Tx_Shift_Reg_Data[4:0];
    2'b01: Tx_Parity_Odd <=  ^Tx_Shift_Reg_Data[5:0];
    2'b10: Tx_Parity_Odd <=  ^Tx_Shift_Reg_Data[6:0];
    2'b11: Tx_Parity_Odd <=  ^Tx_Shift_Reg_Data[7:0];
    endcase
end


// Determine the Final Parity
//
//        Tx_Sticky_Parity_i Tx_Even_Parity_Select_i  Tx_Enable_Parity_i
//
//              X                    X                     0                 No    Parity
//              0                    0                     1                 Odd   Parity
//              0                    1                     1                 Even  Parity
//              1                    0                     1                 Force Parity "1"
//              1                    1                     1                 Force Parity "0"
//
// Note: The Parity bit below is not used for "No Parity" operations
//
always @( Tx_Even_Parity_Select_i or
          Tx_Sticky_Parity_i      or
          Tx_Parity_Odd
         )
begin
    case({Tx_Sticky_Parity_i, Tx_Even_Parity_Select_i})
    2'b00: Tx_Parity <=  Tx_Parity_Odd ;
    2'b01: Tx_Parity <= ~Tx_Parity_Odd ;
    2'b10: Tx_Parity <=  1'b1          ;
    2'b11: Tx_Parity <=  1'b0          ;
    endcase
end


// Tie together the data values from above into the serial data stream.
//
// Note: Stop bits are not included since these are always "1". Instead, "1"
//       is shifted into the shift register during the transfer operation.
//
always @(Tx_Shift_Reg_Data        or
         Tx_Shift_Reg_ld          or
		 Tx_Shift_Reg             or

         Tx_Xfr_Length_cntr_tc    or
         Tx_Baud_16x_cntr_tc      or
         Tx_Bit_Time_cntr_tc      or

         Tx_Enable_Parity_i       or
		 Tx_Parity                or
         Tx_Word_Length_Select_i
         )
begin

    case(      {Tx_Shift_Reg_ld ,    Tx_Xfr_Length_cntr_tc, Tx_Bit_Time_cntr_tc, Tx_Baud_16x_cntr_tc } )
    4'b0000:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    4'b0001:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    4'b0010:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    4'b0011:    Tx_Shift_Reg_nxt <=  {1'b1, Tx_Shift_Reg[9:1]};  // Shift to LSB
    4'b0100:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    4'b0101:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    4'b0110:    Tx_Shift_Reg_nxt <=  Tx_Shift_Reg             ;  // Hold
    default:
    begin
        case( { Tx_Enable_Parity_i, Tx_Word_Length_Select_i } )
        3'b000: Tx_Shift_Reg_nxt <=  {4'hf,            Tx_Shift_Reg_Data[4:0], 1'b0};
        3'b001: Tx_Shift_Reg_nxt <=  {3'h7,            Tx_Shift_Reg_Data[5:0], 1'b0};
        3'b010: Tx_Shift_Reg_nxt <=  {2'h3,            Tx_Shift_Reg_Data[6:0], 1'b0};
        3'b011: Tx_Shift_Reg_nxt <=  {1'b1,            Tx_Shift_Reg_Data[7:0], 1'b0};
        3'b100: Tx_Shift_Reg_nxt <=  {3'h7, Tx_Parity, Tx_Shift_Reg_Data[4:0], 1'b0};
        3'b101: Tx_Shift_Reg_nxt <=  {2'h3, Tx_Parity, Tx_Shift_Reg_Data[5:0], 1'b0};
        3'b110: Tx_Shift_Reg_nxt <=  {1'b1, Tx_Parity, Tx_Shift_Reg_Data[6:0], 1'b0};
        3'b111: Tx_Shift_Reg_nxt <=  {      Tx_Parity, Tx_Shift_Reg_Data[7:0], 1'b0};
        endcase
    end
    endcase
end


// Define the Tx Statemachine
//
always @(Tx_State              or
         Tx_Baud_16x_cntr_tc   or
         Tx_Bit_Time_cntr_tc   or
	     Tx_Xfr_Length_cntr_tc or
         Tx_Break_Control_i    or
         Tx_Storage_Empty_o
        )
begin
    case(Tx_State)
    TX_STATE_IDLE:
    begin
        case( {Tx_Break_Control_i, Tx_Storage_Empty_o, Tx_Baud_16x_cntr_tc} )
		3'b001:
        begin
            Tx_FIFO_Pop_o_nxt         <=  1'b1;

            Tx_State_nxt              <= TX_STATE_TRANSFER;
            Tx_Transfer_Busy_nxt      <=  1'b1;

            Tx_Bit_Time_cntr_ld_nxt   <=  1'b0;
            Tx_Xfr_Length_cntr_ld_nxt <=  1'b0;
            Tx_Shift_Reg_ld_nxt       <=  1'b0;
        end
        default: 
        begin
            Tx_FIFO_Pop_o_nxt         <=  1'b0;

            Tx_State_nxt              <= TX_STATE_IDLE;
            Tx_Transfer_Busy_nxt      <=  1'b0;

            Tx_Bit_Time_cntr_ld_nxt   <=  1'b1;
            Tx_Xfr_Length_cntr_ld_nxt <=  1'b1;
            Tx_Shift_Reg_ld_nxt       <=  1'b1;
        end
        endcase
    end
    TX_STATE_TRANSFER:
    begin

	    case({Tx_Xfr_Length_cntr_tc, Tx_Baud_16x_cntr_tc , Tx_Bit_Time_cntr_tc} )
        3'b011:       // Continue to transfer bits
        begin
            Tx_FIFO_Pop_o_nxt             <=  1'b0;

            Tx_State_nxt                  <= TX_STATE_TRANSFER;
            Tx_Transfer_Busy_nxt          <=  1'b1;
 
            Tx_Bit_Time_cntr_ld_nxt       <=  1'b0;
            Tx_Xfr_Length_cntr_ld_nxt     <=  1'b0;
            Tx_Shift_Reg_ld_nxt           <=  1'b0;
        end
        3'b111:       // Transfer has completed, see if more data is in the Tx FIFO or Hold register
        begin
            case( {Tx_Break_Control_i, Tx_Storage_Empty_o} )
            2'b00:
            begin
                Tx_FIFO_Pop_o_nxt         <=  1'b1;

                Tx_State_nxt              <= TX_STATE_TRANSFER;
                Tx_Transfer_Busy_nxt      <=  1'b1;

                Tx_Bit_Time_cntr_ld_nxt   <=  1'b0;
                Tx_Xfr_Length_cntr_ld_nxt <=  1'b0;
                Tx_Shift_Reg_ld_nxt       <=  1'b0;
            end
			default:  // Either wait for the end of "Break" or for data to be written to the Tx FIFO
            begin
                Tx_FIFO_Pop_o_nxt         <=  1'b0;

                Tx_State_nxt              <= TX_STATE_IDLE;
                Tx_Transfer_Busy_nxt      <=  1'b0;

                Tx_Bit_Time_cntr_ld_nxt   <=  1'b1;
                Tx_Xfr_Length_cntr_ld_nxt <=  1'b1;
                Tx_Shift_Reg_ld_nxt       <=  1'b1;
            end
            endcase
        end  
        default:      // Continue to transfer bits
		begin
                Tx_FIFO_Pop_o_nxt         <=  1'b0;
			  	Tx_State_nxt              <= TX_STATE_TRANSFER;
                Tx_Transfer_Busy_nxt      <=  1'b1;

                Tx_Bit_Time_cntr_ld_nxt   <=  1'b0;
                Tx_Xfr_Length_cntr_ld_nxt <=  1'b0;
                Tx_Shift_Reg_ld_nxt       <=  1'b0;
		end
        endcase

    end
    default:
    begin
        Tx_FIFO_Pop_o_nxt         <=  1'b0;

        Tx_State_nxt              <= TX_STATE_IDLE;
        Tx_Transfer_Busy_nxt      <= 1'b0;

        Tx_Bit_Time_cntr_ld_nxt   <= 1'b1;
        Tx_Xfr_Length_cntr_ld_nxt <= 1'b1;
        Tx_Shift_Reg_ld_nxt       <= 1'b1;
    end
    endcase
end

endmodule
