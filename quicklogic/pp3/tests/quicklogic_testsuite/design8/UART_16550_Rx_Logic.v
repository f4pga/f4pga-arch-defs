// -----------------------------------------------------------------------------
// title          : UART 16550 Rx Logic Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550_Rx_Logic.v
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


module UART_16550_Rx_Logic( 


                            WBs_CLK_i,
                            WBs_RST_i,

                            SIN_i,

                            Rx_FIFO_Pop_i,
                            Rx_FIFO_Push_o,
                            Rx_DAT_o,

                            Rx_Data_Ready_o,

                            Rx_FIFO_Enable_i,

                            Rx_Parity_Error_o,
                            Rx_Framing_Error_o,
                            Rx_Break_Interrupt_o,
                            Rx_Overrun_Error_o,
				
				            Rx_FIFO_Empty_i,
				            Rx_FIFO_Full_i,

                            Rx_Word_Length_Select_i,
                            Rx_Number_of_Stop_Bits_i,
                            Rx_Enable_Parity_i,
                            Rx_Even_Parity_Select_i,
                            Rx_Sticky_Parity_i,

                            Rx_Tx_Loop_Back_i,

                            Tx_SOUT_i,
                            Tx_Baud_16x_i,

                            Rx_TimeOut_Clr_o

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


input                       SIN_i;


// Rx FIFO Signals
//
input                       Rx_FIFO_Pop_i;

output                      Rx_FIFO_Push_o;
output               [7:0]  Rx_DAT_o;

output                      Rx_Data_Ready_o;

input                       Rx_FIFO_Enable_i;

output                      Rx_Parity_Error_o;
output                      Rx_Framing_Error_o;
output                      Rx_Break_Interrupt_o;
output                      Rx_Overrun_Error_o;

input                       Rx_FIFO_Empty_i;
input                       Rx_FIFO_Full_i;

input                [1:0]  Rx_Word_Length_Select_i;
input                       Rx_Number_of_Stop_Bits_i;
input                       Rx_Enable_Parity_i;
input                       Rx_Even_Parity_Select_i;
input                       Rx_Sticky_Parity_i;

input                       Rx_Tx_Loop_Back_i;

input                       Tx_SOUT_i;
input                       Tx_Baud_16x_i;

output                      Rx_TimeOut_Clr_o;

// Fabric Global Signals
//
wire                        WBs_CLK_i;         // Wishbone Fabric Clock
wire                        WBs_RST_i;         // Wishbone Fabric Reset


// Serial Input Stream
//
wire                        SIN_i;
reg                         SIN_i_1ff;
reg                         SIN_i_2ff;
reg                         SIN_i_3ff;

// Rx FIFO Signals
//
wire                        Rx_FIFO_Pop_i;

reg                         Rx_FIFO_Push_o;
reg                         Rx_FIFO_Push_o_nxt;

wire                        Rx_Data_Ready_o;

reg                  [7:0]  Rx_DAT_o;               // Rx Holding Register
reg                  [7:0]  Rx_DAT_o_nxt;           // Rx Holding Register

wire                        Rx_FIFO_Enable_i;

reg                         Rx_Parity_Error_o;
reg                         Rx_Parity_Error_o_nxt;

reg                         Rx_Framing_Error_o;
reg                         Rx_Framing_Error_o_nxt;

reg                         Rx_Break_Interrupt_o;

reg                         Rx_Overrun_Error_o;
reg                         Rx_Overrun_Error_o_nxt;


// Count of FIFO contents
//
wire                        Rx_FIFO_Empty_i;
wire                        Rx_FIFO_Full_i;


// Rx Control Signals
//
wire                 [1:0]  Rx_Word_Length_Select_i;
wire                        Rx_Number_of_Stop_Bits_i;
wire                        Rx_Enable_Parity_i;
wire                        Rx_Even_Parity_Select_i;
wire                        Rx_Sticky_Parity_i;

wire                        Rx_Tx_Loop_Back_i;

wire                        Tx_SOUT_i;
wire                        Tx_Baud_16x_i;

reg                         Rx_TimeOut_Clr_o;
reg                         Rx_TimeOut_Clr_o_nxt;


//------Define Parameters--------------
//

parameter                   RX_STATE_WIDTH     = 2;

parameter                   RX_STATE_IDLE      = 0;
parameter                   RX_STATE_START     = 1;
parameter                   RX_STATE_TRANSFER  = 2;


//------Internal Signals---------------
//

reg                  [3:0]  Rx_Bit_Time_cntr;
reg                  [3:0]  Rx_Bit_Time_cntr_nxt;

reg                         Rx_Bit_Time_cntr_tc;
reg                         Rx_Bit_Time_cntr_tc_nxt;

reg                         Rx_Bit_Time_cntr_ld;
reg                         Rx_Bit_Time_cntr_ld_nxt;

reg                  [1:0]  Rx_Bit_Time_cntr_sel;
reg                  [1:0]  Rx_Bit_Time_cntr_sel_nxt;

reg                  [3:0]  Rx_Xfr_Length_cntr;
reg                  [3:0]  Rx_Xfr_Length_cntr_nxt;

reg                         Rx_Xfr_Length_cntr_tc;
reg                         Rx_Xfr_Length_cntr_tc_nxt;

reg                         Rx_Xfr_Length_cntr_ld;
reg                         Rx_Xfr_Length_cntr_ld_nxt;

reg                         Rx_Shift_Reg_ld;
reg                         Rx_Shift_Reg_ld_nxt;

reg                         Rx_Parity_Odd;
reg                         Rx_Parity;

reg   [RX_STATE_WIDTH-1:0]  Rx_State;
reg   [RX_STATE_WIDTH-1:0]  Rx_State_nxt;

reg                         Rx_Holding_Reg_Empty;
reg                         Rx_Holding_Reg_Empty_nxt;

reg                         Rx_Break_Detect_N;
reg                         Rx_Break_Detect_N_nxt;

reg                  [7:0]  Rx_Shift_Dat;
reg                  [7:0]  Rx_Shift_Dat_nxt;

reg                         Rx_Shift_Parity;
reg                         Rx_Shift_Parity_nxt;

reg                  [1:0]  Rx_Shift_Stop;
reg                  [1:0]  Rx_Shift_Stop_nxt;


//------Logic Operations---------------
//

// Choose between the external Rx and the internal Tx output
//
assign Rx_SIN = Rx_Tx_Loop_Back_i ? Tx_SOUT_i : SIN_i;


// Define the Fabric's Local Registers
//

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

        Rx_FIFO_Push_o           <=  1'b0;

        Rx_State                 <= RX_STATE_IDLE;

        Rx_Bit_Time_cntr         <=  4'h0;
        Rx_Bit_Time_cntr_tc      <=  1'b1;
        Rx_Bit_Time_cntr_ld      <=  1'b1;
        Rx_Bit_Time_cntr_sel     <=  2'h0;

		Rx_Xfr_Length_cntr       <=  4'h0;
		Rx_Xfr_Length_cntr_tc    <=  1'b0;
		Rx_Xfr_Length_cntr_ld    <=  1'b0;

        SIN_i_1ff                <=  1'b0;
        SIN_i_2ff                <=  1'b0;
        SIN_i_3ff                <=  1'b0;

        Rx_DAT_o                 <=  8'h0;
        Rx_Holding_Reg_Empty     <=  1'b1;

        Rx_Shift_Reg_ld          <=  1'b1;

        Rx_Shift_Dat             <=  8'h0;
        Rx_Shift_Parity          <=  1'b0;
        Rx_Shift_Stop            <=  2'h0;

        Rx_Parity_Error_o        <=  1'b0;
        Rx_Framing_Error_o       <=  1'b0;
        Rx_Break_Interrupt_o     <=  1'b0;
        Rx_Overrun_Error_o       <=  1'b0;

        Rx_Break_Detect_N        <=  1'b0;

        Rx_TimeOut_Clr_o         <=  1'b0;

    end  
    else
    begin

        Rx_FIFO_Push_o           <=  Rx_FIFO_Push_o_nxt         ;

        Rx_State                 <=  Rx_State_nxt               ;

        Rx_Bit_Time_cntr         <=  Rx_Bit_Time_cntr_nxt       ;
        Rx_Bit_Time_cntr_tc      <=  Rx_Bit_Time_cntr_tc_nxt    ;
        Rx_Bit_Time_cntr_ld      <=  Rx_Bit_Time_cntr_ld_nxt    ;
        Rx_Bit_Time_cntr_sel     <=  Rx_Bit_Time_cntr_sel_nxt   ;

		Rx_Xfr_Length_cntr       <=  Rx_Xfr_Length_cntr_nxt     ;
		Rx_Xfr_Length_cntr_tc    <=  Rx_Xfr_Length_cntr_tc_nxt  ;
		Rx_Xfr_Length_cntr_ld    <=  Rx_Xfr_Length_cntr_ld_nxt  ;

        SIN_i_1ff                <=  Rx_SIN                     ;
        SIN_i_2ff                <=  SIN_i_1ff                  ;
        SIN_i_3ff                <=  SIN_i_2ff                  ;

        if ( Rx_Xfr_Length_cntr_tc && Tx_Baud_16x_i && Rx_Bit_Time_cntr_tc )
        begin
            Rx_DAT_o             <=  Rx_DAT_o_nxt               ;
            Rx_Parity_Error_o    <=  Rx_Parity_Error_o_nxt      ;
            Rx_Framing_Error_o   <=  Rx_Framing_Error_o_nxt     ;
            Rx_Break_Interrupt_o <= ~Rx_Break_Detect_N_nxt      ;
        end

        Rx_Overrun_Error_o       <=  Rx_Overrun_Error_o_nxt     ;

        Rx_Holding_Reg_Empty     <=  Rx_Holding_Reg_Empty_nxt   ;

        Rx_Break_Detect_N        <=  Rx_Break_Detect_N_nxt      ;

        Rx_Shift_Reg_ld          <=  Rx_Shift_Reg_ld_nxt        ;

        Rx_Shift_Dat             <=  Rx_Shift_Dat_nxt           ;
        Rx_Shift_Parity          <=  Rx_Shift_Parity_nxt        ;
        Rx_Shift_Stop            <=  Rx_Shift_Stop_nxt          ;

        Rx_TimeOut_Clr_o         <=  Rx_TimeOut_Clr_o_nxt       ;
    end  
end


// Select the Empty Flag to use
//
// Note: For FIFO operations, the FIFO Empty Flag is used. This is subject to flushing.
//       For non-FIFO operations, the Holding Register is tracked. It is not
//       subject to FIFO Flushing operations.
//
assign Rx_Data_Ready_o = Rx_FIFO_Enable_i ? ~Rx_FIFO_Empty_i : ~Rx_Holding_Reg_Empty;


// Determine the state of the Rx Holding Register
//
always @( Rx_FIFO_Push_o         or
          Rx_FIFO_Pop_i          or
          Rx_FIFO_Enable_i       or
		  Rx_Holding_Reg_Empty   or
		  Rx_FIFO_Empty_i
        )
begin
    case(  {Rx_FIFO_Enable_i, Rx_FIFO_Push_o, Rx_FIFO_Pop_i})
    3'b000: Rx_Holding_Reg_Empty_nxt <= Rx_Holding_Reg_Empty ;
    3'b001: Rx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b010: Rx_Holding_Reg_Empty_nxt <= 1'b0                 ;
    3'b011: Rx_Holding_Reg_Empty_nxt <= 1'b0                 ;
    3'b100: Rx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b101: Rx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b110: Rx_Holding_Reg_Empty_nxt <= 1'b1                 ;
    3'b111: Rx_Holding_Reg_Empty_nxt <= 1'b1                 ;
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
always @(Rx_Bit_Time_cntr        or
         Rx_Bit_Time_cntr_tc     or
         Rx_Bit_Time_cntr_ld     or
         Rx_Bit_Time_cntr_sel    or
         Tx_Baud_16x_i         
         )
begin
    case(  { Rx_Bit_Time_cntr_ld,     Rx_Bit_Time_cntr_tc, Tx_Baud_16x_i} )
    3'b000:  Rx_Bit_Time_cntr_nxt <=  Rx_Bit_Time_cntr       ; // Hold
    3'b001:  Rx_Bit_Time_cntr_nxt <=  Rx_Bit_Time_cntr - 1'b1; // Count down until the terminal count
    3'b010:  Rx_Bit_Time_cntr_nxt <=  Rx_Bit_Time_cntr       ; // Hold
    default: 
    begin
        case(  Rx_Bit_Time_cntr_sel )
        2'h0: Rx_Bit_Time_cntr_nxt <=  4'h7                   ; // Load on the terminal count - Sync to Start
        2'h1: Rx_Bit_Time_cntr_nxt <=  4'hF                   ; // Load on the terminal count - Full Bit Time
        2'h2: Rx_Bit_Time_cntr_nxt <=  4'hB                   ; // Load on the terminal count - 0.75  Bit Time (Support for 1.5 Stop Bits)
        2'h3: Rx_Bit_Time_cntr_nxt <=  4'h7                   ; // Load on the terminal count - Sync to Start
        endcase
    end
    endcase
end


// Determine the Bit Time counter's terminal count
//
always @(Rx_Bit_Time_cntr        or
         Rx_Bit_Time_cntr_tc     or
         Rx_Bit_Time_cntr_ld     or
         Tx_Baud_16x_i
         )
begin
    case(   {Rx_Bit_Time_cntr_ld,        Tx_Baud_16x_i} )
    2'b00:   Rx_Bit_Time_cntr_tc_nxt <=  Rx_Bit_Time_cntr_tc        ; // Hold
    2'b01:   Rx_Bit_Time_cntr_tc_nxt <= (Rx_Bit_Time_cntr ==  4'h1) ; // Check count down for terminal count
    default: Rx_Bit_Time_cntr_tc_nxt <=  1'b0                       ; // The terminal count is "0" during loads
    endcase
end


// Determine the Transfer Length Counter
//
// Note: This counter counts the number of bits that will be transferred in 
//       the serial stream.
//
//  Rx_Word_Length_Select_i[1:0]   Rx_Number_of_Stop_Bits_i;
//              ANY                          1'b0 : 1
//          2'b00 : 5 bits                   1'b1 : 1.5
//          2'b01 : 6 bits                   1'b1 : 2
//          2'b10 : 7 bits                   1'b1 : 2
//          2'b11 : 8 bits                   1'b1 : 2
//

always @(Rx_Xfr_Length_cntr         or
         Rx_Xfr_Length_cntr_tc      or
         Rx_Xfr_Length_cntr_ld      or

         Tx_Baud_16x_i              or
         Rx_Bit_Time_cntr_tc        or

         Rx_Enable_Parity_i         or
		 Rx_Number_of_Stop_Bits_i   or
		 Rx_Word_Length_Select_i
         )
begin
    case(       {Rx_Xfr_Length_cntr_ld,     Rx_Xfr_Length_cntr_tc, Rx_Bit_Time_cntr_tc, Tx_Baud_16x_i} )
    4'b0000:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    4'b0001:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    4'b0010:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    4'b0011:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr - 1'b1 ; // Count down until the terminal count
    4'b0100:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    4'b0101:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    4'b0110:     Rx_Xfr_Length_cntr_nxt <=  Rx_Xfr_Length_cntr        ; // Hold
    default:
    begin
        case (  {Rx_Enable_Parity_i,  Rx_Number_of_Stop_Bits_i, Rx_Word_Length_Select_i})
        4'b0000: Rx_Xfr_Length_cntr_nxt <=  4'h5                      ; // Start, 5 bits,         Stop bits -> 1
        4'b0001: Rx_Xfr_Length_cntr_nxt <=  4'h6                      ; // Start, 6 bits,         Stop bits -> 1
        4'b0010: Rx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 7 bits,         Stop bits -> 1
        4'b0011: Rx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 8 bits,         Stop bits -> 1

        4'b0100: Rx_Xfr_Length_cntr_nxt <=  4'h6                      ; // Start, 5 bits,         Stop bits -> 2 (Allowed)
        4'b0101: Rx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 6 bits,         Stop bits -> 2
        4'b0110: Rx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 7 bits,         Stop bits -> 2
        4'b0111: Rx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 8 bits,         Stop bits -> 2

        4'b1000: Rx_Xfr_Length_cntr_nxt <=  4'h6                      ; // Start, 5 bits, Parity  Stop bits -> 1
        4'b1001: Rx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 6 bits, Parity  Stop bits -> 1
        4'b1010: Rx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 7 bits, Parity  Stop bits -> 1
        4'b1011: Rx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 8 bits, Parity  Stop bits -> 1

        4'b1100: Rx_Xfr_Length_cntr_nxt <=  4'h7                      ; // Start, 5 bits, Parity, Stop bits -> 2 (Allowed)
        4'b1101: Rx_Xfr_Length_cntr_nxt <=  4'h8                      ; // Start, 6 bits, Parity, Stop bits -> 2
        4'b1110: Rx_Xfr_Length_cntr_nxt <=  4'h9                      ; // Start, 7 bits, Parity, Stop bits -> 2
        4'b1111: Rx_Xfr_Length_cntr_nxt <=  4'hA                      ; // Start, 8 bits, Parity, Stop bits -> 2
        endcase
    end
    endcase
end


// Determine the Transfer Length counter's terminal count
//
always @(Rx_Xfr_Length_cntr        or
         Rx_Xfr_Length_cntr_tc     or
         Rx_Xfr_Length_cntr_ld     or

         Tx_Baud_16x_i             or
         Rx_Bit_Time_cntr_tc
         )
begin
    case( Rx_Xfr_Length_cntr_ld) 
	1'b0:
    begin
        case(  { Rx_Bit_Time_cntr_tc,          Tx_Baud_16x_i } )
        2'b11:   Rx_Xfr_Length_cntr_tc_nxt <= (Rx_Xfr_Length_cntr ==  4'h1) ; // Check count down for terminal count
        default: Rx_Xfr_Length_cntr_tc_nxt <=  Rx_Xfr_Length_cntr_tc        ; // Hold
        endcase
     end
    1'b1:        Rx_Xfr_Length_cntr_tc_nxt <=  1'b0                         ; // The terminal count is "0" during loads
    endcase
end


// Shift input serial data bit into the Rx Data Shift Register
//
//
always @(Rx_Shift_Reg_ld          or
		 Rx_Shift_Dat             or

         Tx_Baud_16x_i            or
         Rx_Bit_Time_cntr_tc      or

         Rx_Shift_Parity          or
         Rx_Shift_Stop            or

         Rx_Enable_Parity_i
         )
begin

    case( Rx_Shift_Reg_ld ) 
    1'b0:
    begin
        case (   { Rx_Bit_Time_cntr_tc,  Tx_Baud_16x_i } )
        2'b11:                                                                  // Shift to LSB
        begin
            case ( Rx_Enable_Parity_i)
            1'b0:  Rx_Shift_Dat_nxt <= { Rx_Shift_Stop[0], Rx_Shift_Dat[7:1] };
            1'b1:  Rx_Shift_Dat_nxt <= { Rx_Shift_Parity , Rx_Shift_Dat[7:1] };
            endcase
        end
        default:   Rx_Shift_Dat_nxt <=   Rx_Shift_Dat                         ; // Hold
        endcase
	end
    1'b1:          Rx_Shift_Dat_nxt <=   8'h0                                 ; // Clear
    endcase
end


// Determine Rx Holding Register Value
//
// Note: The bits used for the output data will vary due to data field length
//
always @(Rx_Word_Length_Select_i or
         Rx_Shift_Dat_nxt
        )
begin
    case (Rx_Word_Length_Select_i)
    2'b00: Rx_DAT_o_nxt <= {3'h0, Rx_Shift_Dat_nxt[7:3]};
    2'b01: Rx_DAT_o_nxt <= {2'h0, Rx_Shift_Dat_nxt[7:2]};
    2'b10: Rx_DAT_o_nxt <= {1'b0, Rx_Shift_Dat_nxt[7:1]};
    2'b11: Rx_DAT_o_nxt <=        Rx_Shift_Dat_nxt[7:0] ;
    endcase
end


// Shift input serial data bit into the Rx Parity Bit Shift Register
//
// Note: When Parity is disabled, the Parity bit is not used for shift operations.
// 
always @(Rx_Shift_Reg_ld          or
		 Rx_Shift_Parity          or

         Tx_Baud_16x_i            or
         Rx_Bit_Time_cntr_tc      or

         Rx_Shift_Stop
         )
begin

    case( Rx_Shift_Reg_ld )
    1'b0:
    begin
        case(  { Rx_Bit_Time_cntr_tc,    Tx_Baud_16x_i} )
        2'b11:   Rx_Shift_Parity_nxt <=  Rx_Shift_Stop[0] ; // Start, 5 bits, Parity  Stop bits -> 1
        default: Rx_Shift_Parity_nxt <=  Rx_Shift_Parity  ; // Hold
        endcase
    end
    1'b1:        Rx_Shift_Parity_nxt <=  1'b0             ; // Clear
    endcase
end


// Determine the Expected Odd Parity
//
// Note: The bits used for the parity calculation will vary due to data field length
//
always @(Rx_Shift_Dat_nxt         or
         Rx_Word_Length_Select_i
         )
begin

    case(  Rx_Word_Length_Select_i )
    2'b00: Rx_Parity_Odd <=  ^Rx_Shift_Dat_nxt[7:3];
    2'b01: Rx_Parity_Odd <=  ^Rx_Shift_Dat_nxt[7:2];
    2'b10: Rx_Parity_Odd <=  ^Rx_Shift_Dat_nxt[7:1];
    2'b11: Rx_Parity_Odd <=  ^Rx_Shift_Dat_nxt[7:0];
    endcase

end


// Determine the Final Expected Parity
//
//        Rx_Sticky_Parity_i Rx_Even_Parity_Select_i  Rx_Enable_Parity_i
//
//              X                    X                     0                 No    Parity
//              0                    0                     1                 Odd   Parity
//              0                    1                     1                 Even  Parity
//              1                    0                     1                 Force Parity "1"
//              1                    1                     1                 Force Parity "0"
//
// Note: The Parity bit below is not used for "No Parity" operations
//
always @( Rx_Even_Parity_Select_i or
          Rx_Sticky_Parity_i      or
          Rx_Parity_Odd
         )
begin
    case({Rx_Sticky_Parity_i, Rx_Even_Parity_Select_i})
    2'b00: Rx_Parity <=  Rx_Parity_Odd ;
    2'b01: Rx_Parity <= ~Rx_Parity_Odd ;
    2'b10: Rx_Parity <=  1'b1          ;
    2'b11: Rx_Parity <=  1'b0          ;
    endcase
end


// Determine if there is a Parity Error
//
always @(Rx_Shift_Parity_nxt       or
         Rx_Enable_Parity_i        or
	     Rx_Break_Detect_N_nxt     or
         Rx_Parity
         )
begin
    case( {Rx_Break_Detect_N_nxt, Rx_Enable_Parity_i})
    2'b11:    Rx_Parity_Error_o_nxt <= (Rx_Shift_Parity_nxt == Rx_Parity) ? 1'b0 : 1'b1; // Compare Parity bits
	default:  Rx_Parity_Error_o_nxt <=  1'b0                                           ; // Parity Disabled or "Break" Condition
    endcase
end


// Shift the input serial stream into the Rx Stop Bit(s) Shift Register
//
//
always @(Rx_Shift_Reg_ld          or
		 Rx_Shift_Stop            or

         Tx_Baud_16x_i            or
         Rx_Bit_Time_cntr_tc      or

         SIN_i_3ff                or

         Rx_Number_of_Stop_Bits_i
         )
begin

    case( Rx_Shift_Reg_ld )
    1'b0:
    begin
        case( { Rx_Bit_Time_cntr_tc, Tx_Baud_16x_i } )
        2'b11:                                                                 // Shift to LSB
        begin
            case ( Rx_Number_of_Stop_Bits_i )
            1'b0:  Rx_Shift_Stop_nxt <= { 1'b1, SIN_i_3ff                   }; // Stop bits -> 1
            1'b1:  Rx_Shift_Stop_nxt <= {       SIN_i_3ff, Rx_Shift_Stop[1] }; // Stop bits -> 1.5 or 2
            endcase
        end
        default:   Rx_Shift_Stop_nxt <=  Rx_Shift_Stop                       ; // Hold
        endcase
    end  
    1'b1:          Rx_Shift_Stop_nxt <=  2'b11                               ; // Clear the Stop Bits
    endcase
end



// Detemine if there is a Framing Error
//
always @(Rx_Shift_Stop_nxt        or
         Rx_Break_Detect_N_nxt
         )
begin
	case(Rx_Break_Detect_N_nxt)
    1'b0:  Rx_Framing_Error_o_nxt <=  1'b0                                    ; // "Break" Condition
    1'b1:  Rx_Framing_Error_o_nxt <=  Rx_Shift_Stop_nxt == 2'b11 ? 1'b0 : 1'b1; //  Check the Stop bits for framing errors
    endcase
end


// Detemine if there is a "Break" condition
//
// Note: A "Break" condition is "0" in each bit location
//
always @(Rx_Shift_Reg_ld          or

         Tx_Baud_16x_i            or
         Rx_Bit_Time_cntr_tc      or

         SIN_i_3ff                or

		 Rx_Break_Detect_N 

         )
begin
    case( Rx_Shift_Reg_ld )
    1'b0:
    begin
        case(  { Rx_Bit_Time_cntr_tc,    Tx_Baud_16x_i} )
        2'b11:   Rx_Break_Detect_N_nxt  <= Rx_Break_Detect_N | SIN_i_3ff ; // Determine if there has been a "1" in the serial stream
        default: Rx_Break_Detect_N_nxt  <= Rx_Break_Detect_N             ; // Hold the current value
        endcase
    end
    1'b1:        Rx_Break_Detect_N_nxt  <= 1'b0                          ; // Clear the seral stream "Break" detect bit
    endcase
end


// Define the Rx Statemachine
//
always @(Rx_State                 or
         Tx_Baud_16x_i            or
         Rx_Bit_Time_cntr_tc      or
	     Rx_Xfr_Length_cntr_tc    or
	     Rx_Xfr_Length_cntr       or
         Rx_Number_of_Stop_Bits_i or
		 Rx_Word_Length_Select_i  or
         Rx_FIFO_Full_i           or
         Rx_FIFO_Enable_i         or
         Rx_Holding_Reg_Empty     or
         SIN_i_2ff                or
         SIN_i_3ff             
        )
begin
    case(Rx_State)
    RX_STATE_IDLE:
    begin
        Rx_FIFO_Push_o_nxt                <=  1'b0;             // Waiting for end of the transfer

        Rx_Bit_Time_cntr_sel_nxt          <=  2'h0;             // Select the "Start" Re-sync period

        Rx_Xfr_Length_cntr_ld_nxt         <=  1'b1;             // Waiting for the start of transfer
        Rx_Shift_Reg_ld_nxt               <=  1'b1;             // Waiting for the start of transfer

        Rx_Overrun_Error_o_nxt            <=  1'b0;             // No Overrun prior to the current transfer

        Rx_TimeOut_Clr_o_nxt              <=  1'b0;             // Waiting for a serial transfer

        case( { SIN_i_2ff, SIN_i_3ff } )
		2'b01:
        begin
            Rx_State_nxt                  <= RX_STATE_START;    // Begin Transfer with Re-sync operation

            Rx_Bit_Time_cntr_ld_nxt       <=  1'b0;             // Begin counting the bit time interval
        end
        default:  // Wait for "Start" bit
        begin
            Rx_State_nxt                  <= RX_STATE_IDLE;     // Wait for the begining of the serial stream

			Rx_Bit_Time_cntr_ld_nxt       <=  1'b1;             // Load the intial period value prior to the start of the serial stream
        end
        endcase
    end
    RX_STATE_START:  // Re-sync operation
    begin
        Rx_FIFO_Push_o_nxt                <=  1'b0;             // Waiting for the end of transfer

        Rx_Overrun_Error_o_nxt            <=  1'b0;             // No Overrun prior to the current transfer

        Rx_TimeOut_Clr_o_nxt              <=  1'b0;             // Waiting for a serial transfer

        case( {Rx_Bit_Time_cntr_tc, Tx_Baud_16x_i} )
		2'b11:
        begin
            case( {SIN_i_2ff, SIN_i_3ff} )
            2'b00:     // Valid "Start" operation
            begin
                Rx_State_nxt              <= RX_STATE_TRANSFER;

                Rx_Bit_Time_cntr_ld_nxt   <=  1'b0;             // Continue counting the bit interval
                Rx_Bit_Time_cntr_sel_nxt  <=  2'h1;             // Select the full bit time interval for the next count

                Rx_Xfr_Length_cntr_ld_nxt <=  1'b0;             // First valid data period; Start counting bits
                Rx_Shift_Reg_ld_nxt       <=  1'b0;             // First valid data period; Start load and shift
            end
            default:   // False "Start" Detection
            begin
                Rx_State_nxt              <= RX_STATE_IDLE;

			    Rx_Bit_Time_cntr_ld_nxt   <=  1'b1;             // Load the intial period value prior to the start of the serial stream
                Rx_Bit_Time_cntr_sel_nxt  <=  2'h0;             // Select the "Start" Re-sync period

                Rx_Xfr_Length_cntr_ld_nxt <=  1'b1;             // First valid data period; Start counting bits
                Rx_Shift_Reg_ld_nxt       <=  1'b1;             // First valid data period; Start load and shift
            end
            endcase
        end
        default:
        begin
            Rx_State_nxt                  <= RX_STATE_START;

            Rx_Bit_Time_cntr_ld_nxt       <=  1'b0;             // Continue counting the bit interval
            Rx_Bit_Time_cntr_sel_nxt      <=  2'h1;             // Select the full bit time interval for the next count

            Rx_Xfr_Length_cntr_ld_nxt     <=  1'b1;             // Waiting for the first valid data period
            Rx_Shift_Reg_ld_nxt           <=  1'b1;             // Waiting for the first valid data period
        end
        endcase
    end
    RX_STATE_TRANSFER:
    begin

	    case({Rx_Xfr_Length_cntr_tc, Rx_Bit_Time_cntr_tc, Tx_Baud_16x_i } )
        3'b111:       // Transfer has completed, return to Idle and wait for the next Re-Sync condition
        begin
            Rx_State_nxt                  <= RX_STATE_IDLE;     // Wait for the next serial stream

            Rx_Bit_Time_cntr_ld_nxt       <=  1'b1;             // Load the selected bit time intervalue value
            Rx_Bit_Time_cntr_sel_nxt      <=  2'h0;             // Select the "Start" bit time interval for the next count

            Rx_Xfr_Length_cntr_ld_nxt     <=  1'b1;             // Re-load the expected serial stream length
            Rx_Shift_Reg_ld_nxt           <=  1'b1;             // Hold the current Shift Register values

            Rx_TimeOut_Clr_o_nxt          <=  1'b1;             // Last Stop Bit found -> Clear the Timeout Counter

            // Determine if an overflow happend
            //
            // Note: This can happen in both Non-FIFO, and FIFO modes
            //
            case( Rx_FIFO_Enable_i)
            1'b0: 
            begin
                Rx_FIFO_Push_o_nxt            <=  1'b1;         // The Rx Holding Register is updated regardless

                case( Rx_Holding_Reg_Empty )
                1'b1: Rx_Overrun_Error_o_nxt  <=  1'b0;         // No Overrun detected  
			    1'b0: Rx_Overrun_Error_o_nxt  <=  1'b1;         // An Overrun was detected
                endcase
            end
            1'b1: 
            begin
                case( Rx_FIFO_Full_i )
                1'b0:
                begin
                    Rx_FIFO_Push_o_nxt        <=  1'b1;         // The FIFO is not full; therefore, write the new value
			        Rx_Overrun_Error_o_nxt    <=  1'b0;         // No Overrun detected  

                end
			    1'b1: 
                begin
                    Rx_FIFO_Push_o_nxt        <=  1'b0;         // The FIFO is full; therefore, do not write
			        Rx_Overrun_Error_o_nxt    <=  1'b1;         // An Overrun was detected
                end
                endcase
            end
            endcase
        end  
        default:       // Continue to transfer bits
        begin
            Rx_FIFO_Push_o_nxt            <=  1'b0;             // Wait for the end of the transfer to store the final values

            Rx_State_nxt                  <= RX_STATE_TRANSFER; // Continue receiving the serial stream
 
            // Support 1.5 stop bits by waiting only 0.75 of a bit time rather than 1.00
            //
			if ( (Rx_Xfr_Length_cntr       == 4'h1 )  && 
		         (Rx_Word_Length_Select_i  == 2'b00)  &&
                  Rx_Number_of_Stop_Bits_i           
		       )     
                Rx_Bit_Time_cntr_sel_nxt  <=  2'h2;             // Select the 0.75 bit time interval for the next count
            else
                Rx_Bit_Time_cntr_sel_nxt  <=  2'h1;             // Select the full bit time interval for the next count

            Rx_Bit_Time_cntr_ld_nxt       <=  1'b0;             // Continue to count bit times

            Rx_Xfr_Length_cntr_ld_nxt     <=  1'b0;             // Continue to count bits
            Rx_Shift_Reg_ld_nxt           <=  1'b0;             // Continue to load and shift

			Rx_Overrun_Error_o_nxt        <=  1'b0;             // No Overrun detection until the end of transfer

            Rx_TimeOut_Clr_o_nxt          <=  1'b0;             // Wait for the last Stop Bit
        end
        endcase

    end
    default:
    begin
		Rx_FIFO_Push_o_nxt                <=  1'b0;             // Pushes only happend at the end of transfers

        Rx_State_nxt                      <= RX_STATE_IDLE;     // Waiting for the start of a serial stream

        Rx_Bit_Time_cntr_ld_nxt           <=  1'b1;             // Bit Time counter loading with the initial interval value
        Rx_Bit_Time_cntr_sel_nxt          <=  2'h0;             // Bit Time counter interval for "Start" re-synch operation

        Rx_Xfr_Length_cntr_ld_nxt         <=  1'b1;             // Rx Transfer length counter loading with the expected serial stream length
        Rx_Shift_Reg_ld_nxt               <=  1'b1;             // Rx Shift register 

        Rx_Overrun_Error_o_nxt            <=  1'b0;             // No Overrun detection between transfers

        Rx_TimeOut_Clr_o_nxt              <=  1'b0;             // Wait for the last Stop Bit
    end
    endcase
end

endmodule
