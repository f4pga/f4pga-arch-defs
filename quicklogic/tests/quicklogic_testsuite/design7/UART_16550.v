// -----------------------------------------------------------------------------
// title          : UART 16550 4 Wire Serial Interface Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550.v
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
// 2016/02/22      1.0        Glen Gomes     Initial Release
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module UART_16550 ( 

                // AHB-To_Fabric Bridge I/F
                //
                WBs_ADR_i,
                WBs_CYC_i,
                WBs_WE_i,
                WBs_STB_i,
                WBs_DAT_i,
                WBs_CLK_i,
                WBs_RST_i,
                WBs_DAT_o,
                WBs_ACK_o,

	            SIN_i,
	            SOUT_o,

	            INTR_o

                );


//------Port Parameters----------------
//

parameter       ADDRWIDTH                   =   4;
parameter       DATAWIDTH                   =   8;

parameter       UART_16550_RBR              =  4'h0; // Receiver    Buffer   Register -> Read  Only; DLAB = 0
parameter       UART_16550_THR              =  4'h0; // Transmitter Holding  Register -> Write Only; DLAB = 0
parameter       UART_16550_IER              =  4'h1; // Interrupt   Enable   Register -> R/W       ; DLAB = 0
parameter       UART_16550_IIR              =  4'h2; // Interrupt   ID       Register -> Read  Only; DLAB = x
parameter       UART_16550_FCR              =  4'h2; // FIFO        Control  Register -> Write Only; DLAB = x
parameter       UART_16550_LCR              =  4'h3; // Line        Control  Register -> R/W       ; DLAB = x
parameter       UART_16550_MCR              =  4'h4; // Modem       Control  Register -> R/W       ; DLAB = x
parameter       UART_16550_LSR              =  4'h5; // Line        Status   Register -> R         ; DLAB = x
parameter       UART_16550_MSR              =  4'h6; // Modem       Status   Register -> R         ; DLAB = x
parameter       UART_16550_SCR              =  4'h7; // Scratch              Register -> R/W       ; DLAB = x
parameter       UART_16550_DLL              =  4'h0; // Divisor     Latch LS Register -> R/W       ; DLAB = 1
parameter       UART_16550_DLM              =  4'h1; // Divisor     Latch MS Register -> R/W       ; DLAB = 1
parameter       UART_16550_RX_FIFO_LEVEL    =  4'h8; // Extended    Register Register -> R         ; DLAB = x
parameter       UART_16550_TX_FIFO_LEVEL    =  4'h9; // Extended    Register Register -> R         ; DLAB = x


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i;           // Address Bus                to   Fabric
input                    WBs_CYC_i;           // Cycle Chip Select          to   Fabric
input                    WBs_WE_i;            // Write Enable               to   Fabric
input                    WBs_STB_i;           // Strobe Signal              to   Fabric
input   [DATAWIDTH-1:0]  WBs_DAT_i;           // Write Data Bus             to   Fabric
input                    WBs_CLK_i;           // Fabric Clock               from Fabric
input                    WBs_RST_i;           // Fabric Reset               to   Fabric
output           [15:0]  WBs_DAT_o;           // Read Data Bus              from Fabric
output                   WBs_ACK_o;           // Transfer Cycle Acknowledge from Fabric

// Serial Port Signals
//
input                    SIN_i;
output                   SOUT_o;

output                   INTR_o;


// Fabric Global Signals
//
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i;        // Wishbone Address Bus
wire                     WBs_CYC_i;        // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire                     WBs_WE_i;         // Wishbone Write  Enable Strobe
wire                     WBs_STB_i;        // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i;        // Wishbone Write  Data Bus
 
wire             [15:0]  WBs_DAT_o;        // Wishbone Read   Data Bus

wire                     WBs_ACK_o;        // Wishbone Client Acknowledge


// Serial Port Signals
//
wire                     SIN_i;
wire                     SOUT_o;

wire                     INTR_o;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

// Tx
//
wire                     Tx_FIFO_Flush;
wire                     Tx_FIFO_Push;
wire                     Tx_FIFO_Pop;
wire              [7:0]  Tx_FIFO_DAT;

wire                     Tx_FIFO_Empty;

wire              [8:0]  Tx_FIFO_Level;

wire                     Tx_Storage_Empty;
wire                     Tx_Logic_Empty;

wire                     Tx_Break_Control;

wire             [15:0]  Tx_Clock_Divisor;
wire                     Tx_Clock_Divisor_Load;

wire                     Tx_Baud_16x;

wire                     Tx_SOUT;

// Rx
//
wire                     Rx_FIFO_Flush;
wire                     Rx_FIFO_Push;

wire              [7:0]  Rx_FIFO_DAT;
wire              [7:0]  Rx_DAT;

wire                     Rx_Data_Ready;

wire              [8:0]  Rx_FIFO_Level;
wire                     Rx_FIFO_Empty;
wire                     Rx_FIFO_Full;

wire                     Rx_FIFO_Parity_Error;
wire                     Rx_FIFO_Framing_Error;
wire                     Rx_FIFO_Break_Interrupt;
wire                     Rx_Overrun_Error;

wire                     Rx_Parity_Error;
wire                     Rx_Framing_Error;
wire                     Rx_Break_Interrupt;

wire                     Rx_Line_Status_Load;


// Rx & Tx
//
wire                     Rx_Tx_FIFO_Enable;

wire              [1:0]  Rx_Tx_Word_Length_Select;
wire                     Rx_Tx_Number_of_Stop_Bits;
wire                     Rx_Tx_Enable_Parity;
wire                     Rx_Tx_Even_Parity_Select;
wire                     Rx_Tx_Sticky_Parity;

wire                     Rx_Tx_Loop_Back;

// Interrupt
//
wire                     Rx_64_Byte_FIFO_Enable;
wire              [1:0]  Rx_Trigger;

wire                     Interrupt_Pending;
wire              [2:0]  Interrupt_Identification;

wire                     Enable_Rx_Data_Avail_Intr;
wire                     Enable_Tx_Holding_Reg_Empty_Intr;
wire                     Enable_Rx_Line_Status_Intr;

wire                     Line_Status_Intr;

wire                     UART_16550_IIR_Rd;

wire                     Rx_TimeOut_Clr;


//------Logic Operations---------------
//

//
// None at this time
//

//------Instantiate Modules------------
//


// Define the Storage elements of the UART
//
// Note: This includes all of the data registers.
//
UART_16550_Registers                   #( 

    .ADDRWIDTH                          ( ADDRWIDTH                       ),
    .DATAWIDTH                          ( DATAWIDTH                       ),

    .UART_16550_RBR                     ( UART_16550_RBR                  ),
    .UART_16550_THR                     ( UART_16550_THR                  ),
    .UART_16550_IER                     ( UART_16550_IER                  ),
    .UART_16550_IIR                     ( UART_16550_IIR                  ),
    .UART_16550_FCR                     ( UART_16550_FCR                  ),
    .UART_16550_LCR                     ( UART_16550_LCR                  ),
    .UART_16550_MCR                     ( UART_16550_MCR                  ),
    .UART_16550_LSR                     ( UART_16550_LSR                  ),
    .UART_16550_MSR                     ( UART_16550_MSR                  ),
    .UART_16550_SCR                     ( UART_16550_SCR                  ),
    .UART_16550_DLL                     ( UART_16550_DLL                  ),
    .UART_16550_DLM                     ( UART_16550_DLM                  ),
    .UART_16550_RX_FIFO_LEVEL           ( UART_16550_RX_FIFO_LEVEL        ),
    .UART_16550_TX_FIFO_LEVEL           ( UART_16550_TX_FIFO_LEVEL        )

	                                                                      )
     u_UART_16550_Registers    
	                                    ( 
    // AHB-To_Fabric Bridge I/F
    //
    .WBs_ADR_i                          ( WBs_ADR_i                       ),
    .WBs_CYC_i                          ( WBs_CYC_i                       ),
    .WBs_WE_i                           ( WBs_WE_i                        ),
    .WBs_STB_i                          ( WBs_STB_i                       ),
    .WBs_DAT_i                          ( WBs_DAT_i                       ),
    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),
    .WBs_DAT_o                          ( WBs_DAT_o                       ),
    .WBs_ACK_o                          ( WBs_ACK_o                       ),

    // TX
    .Tx_FIFO_Flush_o                    ( Tx_FIFO_Flush                   ),
    .Tx_FIFO_Push_o                     ( Tx_FIFO_Push                    ),
	.Tx_FIFO_Level_i                    ( Tx_FIFO_Level                   ),
    .Tx_Clock_Divisor_o                 ( Tx_Clock_Divisor                ),
    .Tx_Clock_Divisor_Load_o            ( Tx_Clock_Divisor_Load           ),
    .Tx_Storage_Empty_i                 ( Tx_Storage_Empty                ),
    .Tx_Logic_Empty_i                   ( Tx_Logic_Empty                  ),
    .Tx_Break_Control_o                 ( Tx_Break_Control                ),

    // RX
    .Rx_FIFO_Empty_i                    ( Rx_FIFO_Empty                   ),
    .Rx_FIFO_Level_i                    ( Rx_FIFO_Level                   ),

    .Rx_FIFO_Flush_o                    ( Rx_FIFO_Flush                   ),
    .Rx_FIFO_Push_i                     ( Rx_FIFO_Push                    ),
    .Rx_FIFO_Pop_o                      ( Rx_FIFO_Pop                     ),
    .Rx_FIFO_DAT_i                      ( Rx_FIFO_DAT                     ),
    .Rx_Data_Ready_i                    ( Rx_Data_Ready                   ),

    .Rx_Overrun_Error_i                 ( Rx_Overrun_Error                ),
    .Rx_Parity_Error_i                  ( Rx_FIFO_Parity_Error            ),
    .Rx_Framing_Error_i                 ( Rx_FIFO_Framing_Error           ),
    .Rx_Break_Interrupt_i               ( Rx_FIFO_Break_Interrupt         ),

    .Rx_Line_Status_Load_o              ( Rx_Line_Status_Load             ),

    // Rx & TX
    .Rx_Tx_FIFO_Enable_o                ( Rx_Tx_FIFO_Enable               ),

    .Rx_Tx_Word_Length_Select_o         ( Rx_Tx_Word_Length_Select        ),
    .Rx_Tx_Number_of_Stop_Bits_o        ( Rx_Tx_Number_of_Stop_Bits       ),
    .Rx_Tx_Enable_Parity_o              ( Rx_Tx_Enable_Parity             ),
    .Rx_Tx_Even_Parity_Select_o         ( Rx_Tx_Even_Parity_Select        ),
    .Rx_Tx_Sticky_Parity_o              ( Rx_Tx_Sticky_Parity             ),

    .Rx_Tx_Loop_Back_o                  ( Rx_Tx_Loop_Back                 ),

     // Interrupt
    .Rx_64_Byte_FIFO_Enable_o           ( Rx_64_Byte_FIFO_Enable          ),
    .Rx_Trigger_o                       ( Rx_Trigger                      ),

    .Interrupt_Pending_i                ( Interrupt_Pending               ),
    .Interrupt_Identification_i         ( Interrupt_Identification        ),

    .Enable_Rx_Data_Avail_Intr_o        ( Enable_Rx_Data_Avail_Intr       ),
    .Enable_Tx_Holding_Reg_Empty_Intr_o ( Enable_Tx_Holding_Reg_Empty_Intr),
    .Enable_Rx_Line_Status_Intr_o       ( Enable_Rx_Line_Status_Intr      ),

    .Line_Status_Intr_o                 ( Line_Status_Intr                ),

    .UART_16550_IIR_Rd_o                ( UART_16550_IIR_Rd               )

                                                                          );

// Tx - Transmit FIFO and FIFO tracking logic
//
UART_16550_Tx_FIFO                        u_UART_16550_Tx_FIFO
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_DAT_i                          ( WBs_DAT_i                       ),

    .Tx_FIFO_Flush_i                    ( Tx_FIFO_Flush                   ),

    .Tx_FIFO_Push_i                     ( Tx_FIFO_Push                    ),

    .Tx_FIFO_Pop_i                      ( Tx_FIFO_Pop                     ),
    .Tx_FIFO_DAT_o                      ( Tx_FIFO_DAT                     ),

    .Tx_FIFO_Empty_o                    ( Tx_FIFO_Empty                   ),
    .Tx_FIFO_Level_o                    ( Tx_FIFO_Level                   )

                                                                          );

// Tx - Tranmit Logic Block
//
UART_16550_Tx_Logic                       u_UART_16550_Tx_Logic
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .WBs_DAT_i                          ( WBs_DAT_i                       ),

    .SOUT_o                             ( SOUT_o                          ),

    .Tx_FIFO_Push_i                     ( Tx_FIFO_Push                    ),
    .Tx_FIFO_Pop_o                      ( Tx_FIFO_Pop                     ),
    .Tx_FIFO_DAT_i                      ( Tx_FIFO_DAT                     ),

    .Tx_FIFO_Empty_i                    ( Tx_FIFO_Empty                   ),

    .Tx_FIFO_Enable_i                   ( Rx_Tx_FIFO_Enable               ),

    .Tx_Word_Length_Select_i            ( Rx_Tx_Word_Length_Select        ),
    .Tx_Number_of_Stop_Bits_i           ( Rx_Tx_Number_of_Stop_Bits       ),
    .Tx_Enable_Parity_i                 ( Rx_Tx_Enable_Parity             ),
    .Tx_Even_Parity_Select_i            ( Rx_Tx_Even_Parity_Select        ),
    .Tx_Sticky_Parity_i                 ( Rx_Tx_Sticky_Parity             ),

    .Tx_Break_Control_i                 ( Tx_Break_Control                ),

    .Rx_Tx_Loop_Back_i                  ( Rx_Tx_Loop_Back                 ),

    .Tx_Clock_Divisor_i                 ( Tx_Clock_Divisor                ),
    .Tx_Clock_Divisor_Load_i            ( Tx_Clock_Divisor_Load           ),
    .Tx_Baud_16x_o                      ( Tx_Baud_16x                     ),

    .Tx_Storage_Empty_o                 ( Tx_Storage_Empty                ),
    .Tx_Logic_Empty_o                   ( Tx_Logic_Empty                  ),

    .Tx_SOUT_o                          ( Tx_SOUT                         )
                                                                          );


// Rx - Receive FIFO and FIFO tracking logic
//
UART_16550_Rx_FIFO                        u_UART_16550_Rx_FIFO
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .Rx_FIFO_Enable_i                   ( Rx_Tx_FIFO_Enable               ),
    .Rx_FIFO_Flush_i                    ( Rx_FIFO_Flush                   ),

    .Rx_FIFO_Push_i                     ( Rx_FIFO_Push                    ), // From Rx   Logic for FIFO
    .Rx_FIFO_DAT_i                      ( Rx_DAT                          ), // From Rx   Logic for FIFO

    .Rx_Parity_Error_i                  ( Rx_Parity_Error                 ), // From Rx   Logic for FIFO
    .Rx_Framing_Error_i                 ( Rx_Framing_Error                ), // From Rx   Logic for FIFO
    .Rx_Break_Interrupt_i               ( Rx_Break_Interrupt              ), // From Rx   Logic for FIFO

    .Rx_FIFO_Pop_i                      ( Rx_FIFO_Pop                     ), // From FIFO Logic for Register Logic
    .Rx_FIFO_DAT_o                      ( Rx_FIFO_DAT                     ), // From FIFO Logic for Register Logic

    .Rx_Parity_Error_o                  ( Rx_FIFO_Parity_Error            ), // From FIFO Logic for Register Logic
    .Rx_Framing_Error_o                 ( Rx_FIFO_Framing_Error           ), // From FIFO Logic for Register Logic
    .Rx_Break_Interrupt_o               ( Rx_FIFO_Break_Interrupt         ), // From FIFO Logic for Register Logic

    .Rx_FIFO_Level_o                    ( Rx_FIFO_Level                   ),
    .Rx_FIFO_Empty_o                    ( Rx_FIFO_Empty                   ),
    .Rx_FIFO_Full_o                     ( Rx_FIFO_Full                    )

                                                                          );


// Rx - Receive Logic Block
//
UART_16550_Rx_Logic                       u_UART_16550_Rx_Logic
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .SIN_i                              ( SIN_i                           ),

    .Rx_FIFO_Pop_i                      ( Rx_FIFO_Pop                     ),
    .Rx_FIFO_Push_o                     ( Rx_FIFO_Push                    ),
    .Rx_DAT_o                           ( Rx_DAT                          ),

    .Rx_Data_Ready_o                    ( Rx_Data_Ready                   ),

    .Rx_FIFO_Enable_i                   ( Rx_Tx_FIFO_Enable               ),

    .Rx_Parity_Error_o                  ( Rx_Parity_Error                 ),
    .Rx_Framing_Error_o                 ( Rx_Framing_Error                ),
    .Rx_Break_Interrupt_o               ( Rx_Break_Interrupt              ),
    .Rx_Overrun_Error_o                 ( Rx_Overrun_Error                ),
				
    .Rx_FIFO_Empty_i                    ( Rx_FIFO_Empty                   ),
    .Rx_FIFO_Full_i                     ( Rx_FIFO_Full                    ),

    .Rx_Word_Length_Select_i            ( Rx_Tx_Word_Length_Select        ),
    .Rx_Number_of_Stop_Bits_i           ( Rx_Tx_Number_of_Stop_Bits       ),
    .Rx_Enable_Parity_i                 ( Rx_Tx_Enable_Parity             ),
    .Rx_Even_Parity_Select_i            ( Rx_Tx_Even_Parity_Select        ),
    .Rx_Sticky_Parity_i                 ( Rx_Tx_Sticky_Parity             ),

    .Rx_Tx_Loop_Back_i                  ( Rx_Tx_Loop_Back                 ),
	
    .Tx_SOUT_i                          ( Tx_SOUT                         ),
    .Tx_Baud_16x_i                      ( Tx_Baud_16x                     ),

    .Rx_TimeOut_Clr_o                   ( Rx_TimeOut_Clr                  )
                                                                          );


// Interrupt Logic Block
//
UART_16550_Interrupt_Control              u_UART_16550_Interrupt_Control
                                        ( 

    .WBs_CLK_i                          ( WBs_CLK_i                       ),
    .WBs_RST_i                          ( WBs_RST_i                       ),

    .Enable_Rx_Data_Avail_Intr_i        ( Enable_Rx_Data_Avail_Intr       ),
    .Enable_Tx_Holding_Reg_Empty_Intr_i ( Enable_Tx_Holding_Reg_Empty_Intr),
    .Enable_Rx_Line_Status_Intr_i       ( Enable_Rx_Line_Status_Intr      ),

    .Rx_FIFO_Push_i                     ( Rx_FIFO_Push                    ),
    .Rx_FIFO_Pop_i                      ( Rx_FIFO_Pop                     ),
    .Rx_FIFO_Empty_i                    ( Rx_FIFO_Empty                   ),
    .Rx_FIFO_Level_i                    ( Rx_FIFO_Level                   ),
    .Rx_Data_Ready_i                    ( Rx_Data_Ready                   ),
    .Rx_Line_Status_Load_i              ( Rx_Line_Status_Load             ),
    .Rx_Overrun_Error_i                 ( Rx_Overrun_Error                ),

    .Rx_FIFO_Enable_i                   ( Rx_Tx_FIFO_Enable               ),
    .Rx_64_Byte_FIFO_Enable_i           ( Rx_64_Byte_FIFO_Enable          ),
    .Rx_Trigger_i                       ( Rx_Trigger                      ),

    .Tx_Storage_Empty_i                 ( Tx_Storage_Empty                ),

    .Interrupt_Pending_o                ( Interrupt_Pending               ),
    .Interrupt_Identification_o         ( Interrupt_Identification        ),

    .Line_Status_Intr_i                 ( Line_Status_Intr                ),

    .UART_16550_IIR_Rd_i                ( UART_16550_IIR_Rd               ),

    .Rx_TimeOut_Clr_i                   ( Rx_TimeOut_Clr                  ),

    .Tx_Baud_16x_i                      ( Tx_Baud_16x                     ),

    .Tx_Word_Length_Select_i            ( Rx_Tx_Word_Length_Select        ),
    .Tx_Number_of_Stop_Bits_i           ( Rx_Tx_Number_of_Stop_Bits       ),
    .Tx_Enable_Parity_i                 ( Rx_Tx_Enable_Parity             ),

    .INTR_o                             ( INTR_o                          )
                                                                          );


endmodule
