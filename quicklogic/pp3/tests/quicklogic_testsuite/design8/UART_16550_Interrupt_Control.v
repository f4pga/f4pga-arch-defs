// -----------------------------------------------------------------------------
// title          : UART 16550 Interrupt Control Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550_Interrupt_Control.v
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


module UART_16550_Interrupt_Control( 


                         WBs_CLK_i,
                         WBs_RST_i,

                         Enable_Rx_Data_Avail_Intr_i,
                         Enable_Tx_Holding_Reg_Empty_Intr_i,
                         Enable_Rx_Line_Status_Intr_i,

                         Rx_FIFO_Push_i,
                         Rx_FIFO_Pop_i,
                         Rx_FIFO_Empty_i,
                         Rx_FIFO_Level_i,
                         Rx_Data_Ready_i,
                         Rx_Line_Status_Load_i,
                         Rx_Overrun_Error_i,

                         Rx_FIFO_Enable_i,
                         Rx_64_Byte_FIFO_Enable_i,
                         Rx_Trigger_i,

				         Tx_Storage_Empty_i,

                         Interrupt_Pending_o,
                         Interrupt_Identification_o,

                         Line_Status_Intr_i,

                         UART_16550_IIR_Rd_i,

                         Rx_TimeOut_Clr_i,

                         Tx_Baud_16x_i,

                         Tx_Enable_Parity_i,
                         Tx_Number_of_Stop_Bits_i,
                         Tx_Word_Length_Select_i,

                         INTR_o

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

input                    Enable_Rx_Data_Avail_Intr_i;
input                    Enable_Tx_Holding_Reg_Empty_Intr_i;
input                    Enable_Rx_Line_Status_Intr_i;

input                    Rx_FIFO_Push_i;
input                    Rx_FIFO_Pop_i;
input                    Rx_FIFO_Empty_i;
input             [8:0]  Rx_FIFO_Level_i;
input                    Rx_Data_Ready_i;
input                    Rx_Line_Status_Load_i;
input                    Rx_Overrun_Error_i;

input                    Rx_FIFO_Enable_i;
input                    Rx_64_Byte_FIFO_Enable_i;
input             [1:0]  Rx_Trigger_i;

input                    Tx_Storage_Empty_i;

output                   Interrupt_Pending_o;
output            [2:0]  Interrupt_Identification_o;

input                    Line_Status_Intr_i;

input                    UART_16550_IIR_Rd_i;

input                    Rx_TimeOut_Clr_i;

input                    Tx_Baud_16x_i;

input             [1:0]  Tx_Word_Length_Select_i;
input                    Tx_Number_of_Stop_Bits_i;
input                    Tx_Enable_Parity_i;

output                   INTR_o;

// Fabric Global Signals
//
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset

wire                     Enable_Rx_Data_Avail_Intr_i;
wire                     Enable_Tx_Holding_Reg_Empty_Intr_i;
wire                     Enable_Rx_Line_Status_Intr_i;

wire                     Rx_FIFO_Push_i;
wire                     Rx_FIFO_Pop_i;
wire                     Rx_FIFO_Empty_i;
wire              [8:0]  Rx_FIFO_Level_i;
wire                     Rx_Data_Ready_i;
wire                     Rx_Line_Status_Load_i;
wire                     Rx_Overrun_Error_i;

wire                     Rx_FIFO_Enable_i;
wire                     Rx_64_Byte_FIFO_Enable_i;
wire              [1:0]  Rx_Trigger_i;

wire                     Tx_Storage_Empty_i;

reg                      Interrupt_Pending_o;
reg               [2:0]  Interrupt_Identification_o;

wire                     Line_Status_Intr_i;

wire                     UART_16550_IIR_Rd_i;

wire                     Rx_TimeOut_Clr_i;

wire                     Tx_Baud_16x_i;

wire              [1:0]  Tx_Word_Length_Select_i;
wire                     Tx_Number_of_Stop_Bits_i;
wire                     Tx_Enable_Parity_i;

reg                      INTR_o;
wire                     INTR_o_nxt;



//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

reg                      Tx_Storage_Empty_1ff        ;

reg                      Line_Status_Intr_Mask       ;
reg                      Line_Status_Intr_Mask_nxt   ;

wire                     Line_Status_Intr_Mask_clr   ;

reg                      Rx_Overrun_Error            ;
reg                      Rx_Line_Status_Load         ;

reg                      Rx_Data_Avail_Intr          ;
reg                      Rx_Data_Avail_Intr_nxt      ;

reg                      Rx_Data_Ready               ; 
wire                     Rx_Data_Ready_nxt           ; 

reg                      Rx_Data_Ready_Mask          ;
reg                      Rx_Data_Ready_Mask_nxt      ;
    
reg                      Rx_Data_Ready_load          ;
wire                     Rx_Data_Ready_load_nxt      ;

wire                     Rx_Data_Ready_Mask_clr      ;

reg                      Tx_Storage_Empty_State      ;
reg                      Tx_Storage_Empty_State_nxt  ;

wire                     Tx_Storage_Empty_State_clr  ;

reg               [9:0]  Timeout_cntr                ;
reg               [9:0]  Timeout_cntr_nxt            ;

reg                      Timeout_cntr_tc             ;
reg                      Timeout_cntr_tc_nxt         ;

reg                      Timeout_cntr_ld             ;
wire                     Timeout_cntr_ld_nxt         ;

reg                      Timeout_Intr_State          ;
reg                      Timeout_Intr_State_nxt      ;

wire                     Timeout_Intr_State_clr      ;



//------Logic Operations---------------
//


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        INTR_o                   <=  1'b0;
        Interrupt_Pending_o      <=  1'b1;

        Rx_Overrun_Error         <=  1'b0;
        Rx_Line_Status_Load      <=  1'b0;
        Tx_Storage_Empty_1ff     <=  1'b1;

        Line_Status_Intr_Mask    <=  1'b1;
        Rx_Data_Ready_Mask       <=  1'b1;
        Tx_Storage_Empty_State   <=  1'b0;

        Rx_Data_Avail_Intr       <=  1'b0;

        Rx_Data_Ready            <=  1'b0; 
        Rx_Data_Ready_load       <=  1'b0;

        Timeout_cntr             <= 10'h0;
        Timeout_cntr_tc          <=  1'b0;
        Timeout_cntr_ld          <=  1'b0;

        Timeout_Intr_State       <=  1'b0;

    end  
    else
    begin
        INTR_o                   <=  INTR_o_nxt                  ;
        Interrupt_Pending_o      <= ~INTR_o_nxt                  ;

        Rx_Overrun_Error         <=  Rx_Overrun_Error_i          ;
        Rx_Line_Status_Load      <=  Rx_Line_Status_Load_i       ;
        Tx_Storage_Empty_1ff     <=  Tx_Storage_Empty_i          ;

        Line_Status_Intr_Mask    <=  Line_Status_Intr_Mask_nxt   ;
        Rx_Data_Ready_Mask       <=  Rx_Data_Ready_Mask_nxt      ;
        Tx_Storage_Empty_State   <=  Tx_Storage_Empty_State_nxt  ;

        Rx_Data_Avail_Intr       <=  Rx_Data_Avail_Intr_nxt      ;

        Rx_Data_Ready            <=  Rx_Data_Ready_nxt           ; 
        Rx_Data_Ready_load       <=  Rx_Data_Ready_load_nxt      ;

        Timeout_cntr             <=  Timeout_cntr_nxt            ;
        Timeout_cntr_tc          <=  Timeout_cntr_tc_nxt         ;
        Timeout_cntr_ld          <=  Timeout_cntr_ld_nxt         ;

        Timeout_Intr_State       <=  Timeout_Intr_State_nxt      ;

    end  
end


// Determine the FIFO full/empty threshold levels for interrupts, etc.
//
// Note: The legacy 16550 levels are maintained for backward compatibility.
//       The "16750" levels have been updated to reflect the larger Fabric FIFO.
//       Regardless of level, the Rx and Tx FIFOs are 512 entries deep.
//
always @( Rx_FIFO_Level_i          or
          Rx_64_Byte_FIFO_Enable_i or
          Rx_Trigger_i
        )
begin
    case({Rx_64_Byte_FIFO_Enable_i, Rx_Trigger_i} )
    3'b000: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[8:0]            ; // Triggered at Level >   1
    3'b001: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[8:2]            ; // Triggered at Level >   4
    3'b010: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[8:3]            ; // Triggered at Level >   8
    3'b011: Rx_Data_Avail_Intr_nxt <= (|Rx_FIFO_Level_i[8:4]          ) 
                                    | ( Rx_FIFO_Level_i[3:1] == 3'h7  ) ; // Triggered at Level >  14 
    3'b100: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[8:0]            ; // Triggered at Level >   1
    3'b101: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[8:7]            ; // Triggered at Level > 128
    3'b110: Rx_Data_Avail_Intr_nxt <=  |Rx_FIFO_Level_i[  8]            ; // Triggered at Level > 256
    3'b111: Rx_Data_Avail_Intr_nxt <= ( Rx_FIFO_Level_i[8:4] == 5'h1F ) ; // Triggered at Level > 496
    endcase
end


// Determine the Interrupt Identification Value
//
// Note: This does not include the Rx Data Time-Out function
//
always @( Rx_Data_Ready            or
          Rx_Data_Ready_Mask       or
		  Timeout_Intr_State       or
          Tx_Storage_Empty_State   or
		  Line_Status_Intr_i       or
		  Line_Status_Intr_Mask  
        )
begin
    case({ (Line_Status_Intr_i  & (~ Line_Status_Intr_Mask ))  ,
           (Rx_Data_Ready       & (~    Rx_Data_Ready_Mask ))  ,
		                                 Timeout_Intr_State    ,
                                     Tx_Storage_Empty_State   })
    4'b0000: Interrupt_Identification_o <= 3'b000;
    4'b0001: Interrupt_Identification_o <= 3'b001;
    4'b0010: Interrupt_Identification_o <= 3'b110;
    4'b0011: Interrupt_Identification_o <= 3'b110;
    4'b0100: Interrupt_Identification_o <= 3'b010;
    4'b0101: Interrupt_Identification_o <= 3'b010;
    4'b0110: Interrupt_Identification_o <= 3'b010;
    4'b0111: Interrupt_Identification_o <= 3'b010;
    default: Interrupt_Identification_o <= 3'b011;
    endcase
end


// Combine all of the interrupt sources and their enables
//
assign INTR_o_nxt                  = ( Line_Status_Intr_i        & (~ Line_Status_Intr_Mask ))
                                   | ( Rx_Data_Ready             & (~    Rx_Data_Ready_Mask ))
		                           | ( Timeout_Intr_State                                    ) 
                                   | ( Tx_Storage_Empty_State                                );


//
// Determine which interrupt to clear when the Interrupt ID Register is read
//
// Note: Only the highest priority interrupt should be cleared.
//

// Determine the Rx Line State Clear operation
//
assign Line_Status_Intr_Mask_clr   =  UART_16550_IIR_Rd_i  &  (Interrupt_Identification_o == 3'b011)  ;

// Determine the Rx Data Ready clear operation
//
assign Rx_Data_Ready_Mask_clr      =  UART_16550_IIR_Rd_i  &  (Interrupt_Identification_o == 3'b010)  ;

// Determine the Rx Data Ready clear operation
//
assign Timeout_Intr_State_clr      =  UART_16550_IIR_Rd_i  &  (Interrupt_Identification_o == 3'b110)  ;

// Determine the Tx Data Ready clear operation
//
assign Tx_Storage_Empty_State_clr  =  UART_16550_IIR_Rd_i  &  (Interrupt_Identification_o == 3'b001)  ;


//
// Determine the "State" of the interrupt
//
// Note: This helps to track when the interrupt has been serviced.
//       Specifically, once serviced, the interrupt will not happen again 
//       until there has been an update to the Line Status Register due 
//       to fetching a new value from the Receive Holding Register and/or 
//       the Rx FIFO.
//
//       If the source is updated, this bit will be cleared, allowing a new
//       interrupt to pass if generated.
//
//       This does not clear the interrupt source. This should be done with
//       the proper I/O to the corresponding register.
//
//       Clearing the interrupt source will also clear this interrupt.
//

// Determine Rx Line Status Interrupt state
//
always @( Line_Status_Intr_i          or
          Rx_Line_Status_Load         or
          Rx_Overrun_Error            or
          Line_Status_Intr_Mask_clr   or
          Line_Status_Intr_Mask       or
          Enable_Rx_Line_Status_Intr_i
        )
begin
    case( Enable_Rx_Line_Status_Intr_i     )
    1'b0:         Line_Status_Intr_Mask_nxt <= 1'b1;
    1'b1:
    begin
        case({    Line_Status_Intr_Mask_clr, 
                  Rx_Line_Status_Load       ,
                  Rx_Overrun_Error          })
        3'b000:   Line_Status_Intr_Mask_nxt <= Line_Status_Intr_Mask  ;
        3'b001:   Line_Status_Intr_Mask_nxt <= 1'b0                   ;
        3'b010:   Line_Status_Intr_Mask_nxt <= 1'b0                   ;
        3'b011:   Line_Status_Intr_Mask_nxt <= 1'b0                   ;
		default:  Line_Status_Intr_Mask_nxt <= 1'b1                   ;
        endcase
    end
    endcase
end

// Determine where to get "Data Ready" from
//
// Note: this had combinatorial elements that can cause glitching on the
//       interrupt output. Therefore, this signal should be register prior 
//       to use.
//
assign Rx_Data_Ready_nxt      = Rx_FIFO_Enable_i ?  Rx_Data_Avail_Intr : Rx_Data_Ready_i;


// Determine when to enable the "Data Ready" interrupt when the Receive Hold
// Register and/or the FIFO is updated.
//
assign Rx_Data_Ready_load_nxt = Rx_FIFO_Push_i   |  Rx_FIFO_Pop_i;


// Determine Rx Data Ready Status Interrupt state
//
// Note: This interrupt can be set or cleared by the source.
//
//       The state of the interrupt service operation will be captured below.
//       Specifically, once the interrupt is serviced, the interrupt will not
//       happen again until there is a change to either the Receive Holding
//       Register and/or the Rx FIFO.
//
//       If the source is updated, this bit will be cleared, allowing a new
//       interrupt to pass if generated.
//
//       This does not clear the interrupt source. This should be done with
//       the proper I/O to the corresponding register.
//
//       Clearing the interrupt source will also clear this interrupt.
//
always @( Rx_Data_Ready_load          or
          Rx_Data_Ready_Mask_clr      or
          Rx_Data_Ready_Mask          or
          Enable_Rx_Data_Avail_Intr_i
        )
begin
    case(  Enable_Rx_Data_Avail_Intr_i   )
    1'b0:         Rx_Data_Ready_Mask_nxt <= 1'b1;
    1'b1:
    begin
        case({    Rx_Data_Ready_Mask_clr, 
                  Rx_Data_Ready_load     })
        2'b00:    Rx_Data_Ready_Mask_nxt <= Rx_Data_Ready_Mask  ;
        2'b01:    Rx_Data_Ready_Mask_nxt <= 1'b0                ;
		default:  Rx_Data_Ready_Mask_nxt <= 1'b1                ;
        endcase
    end
    endcase
end



// Determine Rx Data Timeout Status Interrupt state
//
always @( Timeout_cntr_tc              or
          Timeout_Intr_State_clr       or
          Timeout_Intr_State           or
          Enable_Rx_Data_Avail_Intr_i
        )
begin
    case(  Enable_Rx_Data_Avail_Intr_i   )
    1'b0:         Timeout_Intr_State_nxt <= 1'b0;
    1'b1:
    begin
        case({    Timeout_Intr_State_clr, 
                  Timeout_cntr_tc       })
        2'b00:    Timeout_Intr_State_nxt <= Timeout_Intr_State   ;
        2'b01:    Timeout_Intr_State_nxt <= 1'b1                 ;
		default:  Timeout_Intr_State_nxt <= 1'b0                 ;
        endcase
    end
    endcase
end


// Determine Tx Data Ready Status Interrupt state
//
// Note: This interrupt captures the transition of the Tx Holding Register
//       from "not empty" to "empty". This prevents constantly generating an
//       interrupt whent the Tx Holding Register and/or Tx FIFO is empty.
//
//       An example use case is the transmittion of "Hello World" into the Tx
//       FIFO. The CPU should only be interrupted after the "d" has been sent.
//       In between transmittions, there should be no interrupt.
//
//       New writes to the Tx Holding Register and/or Tx FIFO will clear this
//       interrupt's input. If not already serviced, the CPU interrupt will be
//       de-asserted.
//
always @( Tx_Storage_Empty_i           or
          Tx_Storage_Empty_1ff         or
          Tx_Storage_Empty_State_clr   or
          Tx_Storage_Empty_State       or
          Enable_Tx_Holding_Reg_Empty_Intr_i 
        )
begin
    case(  Enable_Tx_Holding_Reg_Empty_Intr_i )
    1'b0:         Tx_Storage_Empty_State_nxt <= 1'b0;
    1'b1:
    begin
        case({    Tx_Storage_Empty_State_clr, 
                  Tx_Storage_Empty_i        ,
                  Tx_Storage_Empty_1ff    })
        3'b000:   Tx_Storage_Empty_State_nxt <= 1'b0                    ;
        3'b001:   Tx_Storage_Empty_State_nxt <= 1'b0                    ;
        3'b010:   Tx_Storage_Empty_State_nxt <= 1'b1                    ;
        3'b011:   Tx_Storage_Empty_State_nxt <= Tx_Storage_Empty_State  ;
		default:  Tx_Storage_Empty_State_nxt <= 1'b0                    ;
        endcase
    end
    endcase
end


// Determine the Timeout Counter
//
// Note: This counter counts 4x the number of bits expected in the serial stream.
//       More specifically, this counter will multiply the number of expected
//       symbols per character by 16 to emulate the baud rate time period. 
//       Furthermore, the timeout should happen when the time period for 4 full 
//       characters has elapsed.
//
//  Tx_Word_Length_Select_i[1:0]   Tx_Number_of_Stop_Bits_i;
//              ANY                          1'b0 : 1
//          2'b00 : 5 bits                   1'b1 : 1.5
//          2'b01 : 6 bits                   1'b1 : 2
//          2'b10 : 7 bits                   1'b1 : 2
//          2'b11 : 8 bits                   1'b1 : 2
//

always @(Timeout_cntr               or
         Timeout_cntr_tc            or
         Timeout_cntr_ld            or

         Tx_Baud_16x_i              or

         Tx_Enable_Parity_i         or
		 Tx_Number_of_Stop_Bits_i   or
		 Tx_Word_Length_Select_i
         )
begin
    case(       {Timeout_cntr_ld,     Timeout_cntr_tc, Tx_Baud_16x_i} )
    3'b000:      Timeout_cntr_nxt <=  Timeout_cntr        ; // Hold
    3'b001:      Timeout_cntr_nxt <=  Timeout_cntr - 1'b1 ; // Count down until the terminal count
    3'b010:      Timeout_cntr_nxt <=  Timeout_cntr        ; // Hold
    default:
    begin
        case (  {Tx_Enable_Parity_i,  Tx_Number_of_Stop_Bits_i, Tx_Word_Length_Select_i})
        4'b0000: Timeout_cntr_nxt <=  10'h180             ; // Start, 5 bits,         Stop bits -> 1
        4'b0001: Timeout_cntr_nxt <=  10'h1C0             ; // Start, 6 bits,         Stop bits -> 1
        4'b0010: Timeout_cntr_nxt <=  10'h200             ; // Start, 7 bits,         Stop bits -> 1
        4'b0011: Timeout_cntr_nxt <=  10'h240             ; // Start, 8 bits,         Stop bits -> 1

        4'b0100: Timeout_cntr_nxt <=  10'h1C0             ; // Start, 5 bits,         Stop bits -> 2 (Allowed)
        4'b0101: Timeout_cntr_nxt <=  10'h200             ; // Start, 6 bits,         Stop bits -> 2
        4'b0110: Timeout_cntr_nxt <=  10'h240             ; // Start, 7 bits,         Stop bits -> 2
        4'b0111: Timeout_cntr_nxt <=  10'h280             ; // Start, 8 bits,         Stop bits -> 2

        4'b1000: Timeout_cntr_nxt <=  10'h1C0             ; // Start, 5 bits, Parity  Stop bits -> 1
        4'b1001: Timeout_cntr_nxt <=  10'h200             ; // Start, 6 bits, Parity  Stop bits -> 1
        4'b1010: Timeout_cntr_nxt <=  10'h240             ; // Start, 7 bits, Parity  Stop bits -> 1
        4'b1011: Timeout_cntr_nxt <=  10'h280             ; // Start, 8 bits, Parity  Stop bits -> 1

        4'b1100: Timeout_cntr_nxt <=  10'h200             ; // Start, 5 bits, Parity, Stop bits -> 2 (Allowed)
        4'b1101: Timeout_cntr_nxt <=  10'h240             ; // Start, 6 bits, Parity, Stop bits -> 2
        4'b1110: Timeout_cntr_nxt <=  10'h280             ; // Start, 7 bits, Parity, Stop bits -> 2
        4'b1111: Timeout_cntr_nxt <=  10'h2C0             ; // Start, 8 bits, Parity, Stop bits -> 2
        endcase
    end
    endcase
end


// Determine the Timeout counter's terminal count
//
always @(Timeout_cntr        or
         Timeout_cntr_tc     or
         Timeout_cntr_ld     or

         Tx_Baud_16x_i
         )
begin
    case(    {Timeout_cntr_ld,        Tx_Baud_16x_i} )
    2'b00:    Timeout_cntr_tc_nxt <=  Timeout_cntr_tc        ; // Hold
    2'b01:    Timeout_cntr_tc_nxt <= (Timeout_cntr == 10'h1) ; // Check count down for terminal count
    default:  Timeout_cntr_tc_nxt <=  1'b0                   ; // The terminal count is "0" during loads
    endcase
end


// Determine when the Timeout Counter is reset (i.e. loaded/re-loaded)
//
assign Timeout_cntr_ld_nxt = (~Enable_Rx_Data_Avail_Intr_i  )
                           |   Rx_FIFO_Empty_i 
					       |   Rx_TimeOut_Clr_i
                           |   Rx_FIFO_Pop_i                 ;
                  


endmodule
