// -----------------------------------------------------------------------------
// title          : UART 16550 Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : UART_16550_Registers.v
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


module UART_16550_Registers ( 

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

                         // Tx
                         //
                         Tx_FIFO_Flush_o,
                         Tx_FIFO_Push_o,
                         Tx_FIFO_Level_i,
                         Tx_Clock_Divisor_o,
                         Tx_Clock_Divisor_Load_o,
                         Tx_Storage_Empty_i,
                         Tx_Logic_Empty_i,
                         Tx_Break_Control_o,

                         // Rx
                         //
                         Rx_FIFO_Empty_i,
                         Rx_FIFO_Level_i,

                         Rx_FIFO_Flush_o,
                         Rx_FIFO_Push_i,
                         Rx_FIFO_Pop_o,
                         Rx_FIFO_DAT_i,
                         Rx_Data_Ready_i,

                         Rx_Overrun_Error_i,
                         Rx_Parity_Error_i,
                         Rx_Framing_Error_i,
                         Rx_Break_Interrupt_i,

                         Rx_Line_Status_Load_o,

                         // Rx & Tx Common Signals
                         //
                         Rx_Tx_FIFO_Enable_o,

                         Rx_Tx_Word_Length_Select_o,
                         Rx_Tx_Number_of_Stop_Bits_o,
                         Rx_Tx_Enable_Parity_o,
                         Rx_Tx_Even_Parity_Select_o,
                         Rx_Tx_Sticky_Parity_o,

                         Rx_Tx_Loop_Back_o,

                         // Interrupt
                         Rx_64_Byte_FIFO_Enable_o,
                         Rx_Trigger_o,

                         Interrupt_Pending_i,
                         Interrupt_Identification_i,

                         Enable_Rx_Data_Avail_Intr_o,
                         Enable_Tx_Holding_Reg_Empty_Intr_o,
                         Enable_Rx_Line_Status_Intr_o,

                         Line_Status_Intr_o,

                         UART_16550_IIR_Rd_o

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   4;   // Allow for up to 128 registers in the fabric
parameter                DATAWIDTH                   =   8;   // Allow for up to 128 registers in the fabric

parameter                UART_16550_RBR              =  4'h0; // Receiver    Buffer   Register -> Read  Only; DLAB = 0
parameter                UART_16550_THR              =  4'h0; // Transmitter Holding  Register -> Write Only; DLAB = 0
parameter                UART_16550_IER              =  4'h1; // Interrupt   Enable   Register -> R/W       ; DLAB = 0
parameter                UART_16550_IIR              =  4'h2; // Interrupt   ID       Register -> Read  Only; DLAB = x
parameter                UART_16550_FCR              =  4'h2; // FIFO        Control  Register -> Write Only; DLAB = x
parameter                UART_16550_LCR              =  4'h3; // Line        Control  Register -> R/W       ; DLAB = x
parameter                UART_16550_MCR              =  4'h4; // Modem       Control  Register -> R/W       ; DLAB = x
parameter                UART_16550_LSR              =  4'h5; // Line        Status   Register -> R         ; DLAB = x
parameter                UART_16550_MSR              =  4'h6; // Modem       Status   Register -> R         ; DLAB = x
parameter                UART_16550_SCR              =  4'h7; // Scratch              Register -> R/W       ; DLAB = x
parameter                UART_16550_DLL              =  4'h0; // Divisor     Latch LS Register -> R/W       ; DLAB = 1
parameter                UART_16550_DLM              =  4'h1; // Divisor     Latch MS Register -> R/W       ; DLAB = 1
parameter                UART_16550_RX_FIFO_LEVEL    =  4'h8; // Extended    Register Register -> R         ; DLAB = x
parameter                UART_16550_TX_FIFO_LEVEL    =  4'h9; // Extended    Register Register -> R         ; DLAB = x


parameter                UART_16550_IER_DEFAULT      =  8'h0; // Interrupt   Enable   Register -> R/W       ; DLAB = 0
parameter                UART_16550_FCR_DEFAULT      =  8'h0; // FIFO        Control  Register -> Write Only; DLAB = x
parameter                UART_16550_LCR_DEFAULT      =  8'h0; // Line        Control  Register -> R/W       ; DLAB = x
parameter                UART_16550_MCR_DEFAULT      =  8'h0; // Modem       Control  Register -> R/W       ; DLAB = x
parameter                UART_16550_SCR_DEFAULT      =  8'h0; // Scratch              Register -> R/W       ; DLAB = x
parameter                UART_16550_DLL_DEFAULT      =  8'h0; // Divisor     Latch LS Register -> R/W       ; DLAB = 1
parameter                UART_16550_DLM_DEFAULT      =  8'h0; // Divisor     Latch MS Register -> R/W       ; DLAB = 1


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

// Tx
//
output                   Tx_FIFO_Flush_o;
output                   Tx_FIFO_Push_o;
input             [8:0]  Tx_FIFO_Level_i;
output           [15:0]  Tx_Clock_Divisor_o;
output                   Tx_Clock_Divisor_Load_o;
input                    Tx_Storage_Empty_i;
input                    Tx_Logic_Empty_i;
output                   Tx_Break_Control_o;

// Rx
//
input                    Rx_FIFO_Empty_i;
input             [8:0]  Rx_FIFO_Level_i;

output                   Rx_FIFO_Flush_o;
input                    Rx_FIFO_Push_i;
output                   Rx_FIFO_Pop_o;
input             [7:0]  Rx_FIFO_DAT_i;
input                    Rx_Data_Ready_i;

input                    Rx_Overrun_Error_i;
input                    Rx_Parity_Error_i;
input                    Rx_Framing_Error_i;
input                    Rx_Break_Interrupt_i;

output                   Rx_Line_Status_Load_o;

// Common to Rx and Tx
//
output                   Rx_Tx_FIFO_Enable_o;

output            [1:0]  Rx_Tx_Word_Length_Select_o;
output                   Rx_Tx_Number_of_Stop_Bits_o;
output                   Rx_Tx_Enable_Parity_o;
output                   Rx_Tx_Even_Parity_Select_o;
output                   Rx_Tx_Sticky_Parity_o;

output                   Rx_Tx_Loop_Back_o;

// Interrupt
//
output                   Rx_64_Byte_FIFO_Enable_o;
output            [1:0]  Rx_Trigger_o;

input                    Interrupt_Pending_i;
input             [2:0]  Interrupt_Identification_i;

output                   Enable_Rx_Data_Avail_Intr_o;
output                   Enable_Tx_Holding_Reg_Empty_Intr_o;
output                   Enable_Rx_Line_Status_Intr_o;

output                   Line_Status_Intr_o;

output                   UART_16550_IIR_Rd_o;


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
 
reg              [15:0]  WBs_DAT_o;        // Wishbone Read   Data Bus

reg                      WBs_ACK_o;        // Wishbone Client Acknowledge


// Tx
//
wire                     Tx_FIFO_Flush_o;
wire                     Tx_FIFO_Push_o;
wire              [8:0]  Tx_FIFO_Level_i;

wire             [15:0]  Tx_Clock_Divisor_o;

reg                      Tx_Clock_Divisor_Load_o;
wire                     Tx_Clock_Divisor_Load_o_nxt;

wire                     Tx_Storage_Empty_i;
wire                     Tx_Logic_Empty_i;
wire                     Tx_Break_Control_o;

// Rx
//
wire                     Rx_FIFO_Empty_i;
wire              [8:0]  Rx_FIFO_Level_i;

wire                     Rx_FIFO_Flush_o;
wire                     Rx_FIFO_Push_i;
reg                      Rx_FIFO_Pop_o;           // Receiver Buffer      Register -> Read  Only; DLAB = 0
wire              [7:0]  Rx_FIFO_DAT_i;
wire                     Rx_Data_Ready_i;

wire                     Rx_Overrun_Error_i;
wire                     Rx_Parity_Error_i;
wire                     Rx_Framing_Error_i;
wire                     Rx_Break_Interrupt_i;

reg                      Rx_Line_Status_Load_o;
reg                      Rx_Line_Status_Load_o_prop_dly;
wire                     Rx_Line_Status_Load_o_nxt;

// Common to Rx and Tx
//
wire                     Rx_Tx_FIFO_Enable_o;

wire              [1:0]  Rx_Tx_Word_Length_Select_o;
wire                     Rx_Tx_Number_of_Stop_Bits_o;
wire                     Rx_Tx_Enable_Parity_o;
wire                     Rx_Tx_Even_Parity_Select_o;
wire                     Rx_Tx_Sticky_Parity_o;

wire                     Rx_Tx_Loop_Back_o;

// Interrupt
//
wire                     Rx_64_Byte_FIFO_Enable_o;
wire              [1:0]  Rx_Trigger_o;

wire                     Interrupt_Pending_i;
wire              [2:0]  Interrupt_Identification_i;

wire                     Enable_Rx_Data_Avail_Intr_o;
wire                     Enable_Tx_Holding_Reg_Empty_Intr_o;
wire                     Enable_Rx_Line_Status_Intr_o;

wire                     Line_Status_Intr_o;

reg                      UART_16550_IIR_Rd_o;


//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//

wire                     UART_16550_RBR_Rd_Dcd;   // Receiver Buffer      Register -> Read  Only; DLAB = 0

wire                     UART_16550_LSR_Rd_Dcd;   // Modem Status         Register -> Read  Only; DLAB = 0

wire                     UART_16550_IIR_Rd_Dcd;   // Interrupt   ID       Register -> Read  Only; DLAB = x

wire                     UART_16550_THR_Wr_Dcd;   // Transmitter Holding  Register -> Write Only; DLAB = 0
wire                     UART_16550_IER_Wr_Dcd;   // Interrupt   Enable   Register -> R/W       ; DLAB = 0
wire                     UART_16550_FCR_Wr_Dcd;   // FIFO        Control  Register -> Write Only; DLAB = x
wire                     UART_16550_LCR_Wr_Dcd;   // Line        Control  Register -> R/W       ; DLAB = x
wire                     UART_16550_MCR_Wr_Dcd;   // Modem       Control  Register -> R/W       ; DLAB = x
wire                     UART_16550_SCR_Wr_Dcd;   // Scratch              Register -> R/W       ; DLAB = x
wire                     UART_16550_DLL_Wr_Dcd;   // Divisor     Latch LS Register -> R/W       ; DLAB = 1
wire                     UART_16550_DLM_Wr_Dcd;   // Divisor     Latch MS Register -> R/W       ; DLAB = 1


// Interrupt Enable Register
//
reg                      IER_Enable_Rx_Data_Avail_Intr;
reg                      IER_Enable_Tx_Holding_Reg_Empty_Intr;
reg                      IER_Enable_Rx_Line_Status_Intr;


// Interrupt Identification Register
//
wire                     IIR_Interrupt_Pending;
wire              [2:0]  IIR_Interrupt_Identification;


// FIFO Control Register
//
reg                      FCR_Enable_FIFO;

reg                      FCR_Rx_FIFO_Rst;
wire                     FCR_Rx_FIFO_Rst_nxt;

reg                      FCR_Tx_FIFO_Rst;
wire                     FCR_Tx_FIFO_Rst_nxt;

reg                      FCR_64_Byte_FIFO_Enable; // Reserved bit

reg               [1:0]  FCR_Rx_Trigger;


// Line Control Register
//
reg               [1:0]  LCR_Word_Length_Select;
reg                      LCR_Number_of_Stop_Bits;
reg                      LCR_Enable_Parity;
reg                      LCR_Even_Parity_Select;
reg                      LCR_Sticky_Parity;
reg                      LCR_Break_Control;
reg                      LCR_Divisor_Latch_Access_Bit;

wire              [7:0]  LCR_DLAB_Adr0_Sel;
wire              [7:0]  LCR_DLAB_Adr1_Sel;


// Modem Control Register
//
reg                      MCR_Loop_Back;


// Line Status Register
//
wire                     LSR_Rx_Data_Ready;

reg                      LSR_Rx_Overrun_Error;
wire                     LSR_Rx_Overrun_Error_nxt;

reg                      LSR_Rx_Parity_Error;
wire                     LSR_Rx_Parity_Error_nxt;

reg                      LSR_Rx_Framing_Error;
wire                     LSR_Rx_Framing_Error_nxt;

reg                      LSR_Rx_Break_Interrupt;
wire                     LSR_Rx_Break_Interrupt_nxt;

wire                     LSR_Tx_Storage_Empty;
wire                     LSR_Tx_Logic_Empty;
wire                     LSR_Rx_FIFO_Data_Error;


// Scratch Register
//
reg               [7:0]  SCR_Scratch_Reg;


// Divisor Registers
//
reg               [7:0]  DLL_Divisor_LSB_Reg;
reg               [7:0]  DLM_Divisor_MSB_Reg;


//------Logic Operations---------------
//

// Determine each register decode
//
assign UART_16550_RBR_Rd_Dcd = ( WBs_ADR_i == UART_16550_RBR) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i)  & ( WBs_ACK_o)                                   ;
assign UART_16550_LSR_Rd_Dcd = ( WBs_ADR_i == UART_16550_LSR) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i)  & ( WBs_ACK_o)                                   ;
assign UART_16550_IIR_Rd_Dcd = ( WBs_ADR_i == UART_16550_IIR) & WBs_CYC_i & WBs_STB_i & (~WBs_WE_i)  & ( WBs_ACK_o)                                   ;

assign UART_16550_THR_Wr_Dcd = ( WBs_ADR_i == UART_16550_THR) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o) & (~LCR_Divisor_Latch_Access_Bit) ;
assign UART_16550_IER_Wr_Dcd = ( WBs_ADR_i == UART_16550_IER) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o) & (~LCR_Divisor_Latch_Access_Bit) ;
assign UART_16550_FCR_Wr_Dcd = ( WBs_ADR_i == UART_16550_FCR) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o)                                   ;
assign UART_16550_LCR_Wr_Dcd = ( WBs_ADR_i == UART_16550_LCR) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o)                                   ;
assign UART_16550_MCR_Wr_Dcd = ( WBs_ADR_i == UART_16550_MCR) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o)                                   ;
assign UART_16550_SCR_Wr_Dcd = ( WBs_ADR_i == UART_16550_SCR) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o)                                   ;
assign UART_16550_DLL_Wr_Dcd = ( WBs_ADR_i == UART_16550_DLL) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o) &   LCR_Divisor_Latch_Access_Bit  ;
assign UART_16550_DLM_Wr_Dcd = ( WBs_ADR_i == UART_16550_DLM) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & (~WBs_ACK_o) &   LCR_Divisor_Latch_Access_Bit  ;


// Detemine when to load the Divisor into the Baud 16x counter of the Tx Logic
//
assign Tx_Clock_Divisor_Load_o_nxt = (( WBs_ADR_i == UART_16550_DLL)
                                   |  ( WBs_ADR_i == UART_16550_DLM)) & WBs_CYC_i & WBs_STB_i &   WBs_WE_i   & ( WBs_ACK_o) & LCR_Divisor_Latch_Access_Bit;


// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt         =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Determine the FIFO "Flush" bits
//
// Note: These bits are self clearing after flushing the target FIFO(s)
//
assign FCR_Rx_FIFO_Rst_nxt   =   (UART_16550_FCR_Wr_Dcd) & WBs_DAT_i[1];
assign FCR_Tx_FIFO_Rst_nxt   =   (UART_16550_FCR_Wr_Dcd) & WBs_DAT_i[2];


// Define the Fabric's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin

        Rx_FIFO_Pop_o                        <=  1'b0;

        // Interrupt Enable Register
        //
        IER_Enable_Rx_Data_Avail_Intr        <= UART_16550_IER_DEFAULT[0]  ;
        IER_Enable_Tx_Holding_Reg_Empty_Intr <= UART_16550_IER_DEFAULT[1]  ;
        IER_Enable_Rx_Line_Status_Intr       <= UART_16550_IER_DEFAULT[2]  ;

        // FIFO Control Register
        //
        FCR_Enable_FIFO                      <= UART_16550_FCR_DEFAULT[0]  ;
        FCR_Rx_FIFO_Rst                      <= UART_16550_FCR_DEFAULT[1]  ;
        FCR_Tx_FIFO_Rst                      <= UART_16550_FCR_DEFAULT[2]  ;
        FCR_64_Byte_FIFO_Enable              <= UART_16550_FCR_DEFAULT[5]  ; // Reserved bit
        FCR_Rx_Trigger                       <= UART_16550_FCR_DEFAULT[7:6];

        // Line Control Register
        //
        LCR_Word_Length_Select               <= UART_16550_LCR_DEFAULT[1:0];
        LCR_Number_of_Stop_Bits              <= UART_16550_LCR_DEFAULT[2]  ;
        LCR_Enable_Parity                    <= UART_16550_LCR_DEFAULT[3]  ;
        LCR_Even_Parity_Select               <= UART_16550_LCR_DEFAULT[4]  ;
        LCR_Sticky_Parity                    <= UART_16550_LCR_DEFAULT[5]  ;
        LCR_Break_Control                    <= UART_16550_LCR_DEFAULT[6]  ;
        LCR_Divisor_Latch_Access_Bit         <= UART_16550_LCR_DEFAULT[7]  ;

        // Modem Control Register
        //
        MCR_Loop_Back                        <= UART_16550_MCR_DEFAULT[4]  ;

        // Line Status Register
        LSR_Rx_Overrun_Error                 <=  1'b0;
        LSR_Rx_Parity_Error                  <=  1'b0;
        LSR_Rx_Framing_Error                 <=  1'b0;
        LSR_Rx_Break_Interrupt               <=  1'b0;

        Rx_Line_Status_Load_o                <=  1'b0;
        Rx_Line_Status_Load_o_prop_dly       <=  1'b0;

        // Scratch Register
        //
        SCR_Scratch_Reg                      <= UART_16550_SCR_DEFAULT;

        // Divisor Registers
        //
        DLL_Divisor_LSB_Reg                  <= UART_16550_DLL_DEFAULT;
        DLM_Divisor_MSB_Reg                  <= UART_16550_DLM_DEFAULT;

        Tx_Clock_Divisor_Load_o              <=  1'b0;
		
        UART_16550_IIR_Rd_o                  <=  1'b0;

        WBs_ACK_o                            <=  1'b0;
    end  
    else
    begin

	    // Delay this clock enable by one cycle past ACK to guarantee hold
		// time into the ASSP during the read operation.
		//
        Rx_FIFO_Pop_o                            <=  UART_16550_RBR_Rd_Dcd;

        // Interrupt Enable Register
        //
        if (UART_16550_IER_Wr_Dcd)
        begin
            IER_Enable_Rx_Data_Avail_Intr        <=  WBs_DAT_i[0];
            IER_Enable_Tx_Holding_Reg_Empty_Intr <=  WBs_DAT_i[1];
            IER_Enable_Rx_Line_Status_Intr       <=  WBs_DAT_i[2];
        end

        // FIFO Control Register
        //
        if (UART_16550_FCR_Wr_Dcd)
        begin
            FCR_Enable_FIFO                      <=  WBs_DAT_i[0];
            FCR_64_Byte_FIFO_Enable              <=  WBs_DAT_i[5]; // Reserved bit
            FCR_Rx_Trigger                       <=  WBs_DAT_i[7:6];
        end

        // These bits should be self clearing after "Flushing" the FIFO(s)
        //
        FCR_Rx_FIFO_Rst                          <=  FCR_Rx_FIFO_Rst_nxt;
        FCR_Tx_FIFO_Rst                          <=  FCR_Tx_FIFO_Rst_nxt;

        // Line Control Register
        //
        if (UART_16550_LCR_Wr_Dcd)
        begin
            LCR_Word_Length_Select               <=  WBs_DAT_i[1:0];
            LCR_Number_of_Stop_Bits              <=  WBs_DAT_i[2];
            LCR_Enable_Parity                    <=  WBs_DAT_i[3];
            LCR_Even_Parity_Select               <=  WBs_DAT_i[4];
            LCR_Sticky_Parity                    <=  WBs_DAT_i[5];
            LCR_Break_Control                    <=  WBs_DAT_i[6];
            LCR_Divisor_Latch_Access_Bit         <=  WBs_DAT_i[7];
        end

        // Modem Control Register
        //
        if (UART_16550_MCR_Wr_Dcd)
        begin
            MCR_Loop_Back                        <=  WBs_DAT_i[4];
        end

        // Line Status Register
        //
        // Note: These registers are cleared by a read from the LSR
        //
        LSR_Rx_Overrun_Error                     <=  LSR_Rx_Overrun_Error_nxt  ;
        LSR_Rx_Parity_Error                      <=  LSR_Rx_Parity_Error_nxt   ;
        LSR_Rx_Framing_Error                     <=  LSR_Rx_Framing_Error_nxt  ;
        LSR_Rx_Break_Interrupt                   <=  LSR_Rx_Break_Interrupt_nxt;

        Rx_Line_Status_Load_o                    <=  Rx_Line_Status_Load_o_prop_dly ;
        Rx_Line_Status_Load_o_prop_dly           <=  Rx_Line_Status_Load_o_nxt      ;

        // Define the Scratch Register 
        //
        if(UART_16550_SCR_Wr_Dcd)
			SCR_Scratch_Reg                      <=  WBs_DAT_i;

        // Divisor Registers
        //
        if(UART_16550_DLL_Wr_Dcd)
            DLL_Divisor_LSB_Reg                  <=  WBs_DAT_i;
 
        if(UART_16550_DLM_Wr_Dcd)
            DLM_Divisor_MSB_Reg                  <=  WBs_DAT_i;

        Tx_Clock_Divisor_Load_o                  <=  Tx_Clock_Divisor_Load_o_nxt;


	    // Delay this clock enable by one cycle past ACK to guarantee hold
		// time into the ASSP during the read operation.
		//
        UART_16550_IIR_Rd_o                      <=  UART_16550_IIR_Rd_Dcd;

        WBs_ACK_o                                <=  WBs_ACK_o_nxt;
    end  
end


// Select the correct data source for the Divisor Latch Access Bit (DLAB)
//
assign LCR_DLAB_Adr0_Sel = LCR_Divisor_Latch_Access_Bit ?          DLL_Divisor_LSB_Reg
		                                                :          Rx_FIFO_DAT_i                         ;

assign LCR_DLAB_Adr1_Sel = LCR_Divisor_Latch_Access_Bit ?          DLM_Divisor_MSB_Reg                        
		                                                : {  5'h0, IER_Enable_Rx_Line_Status_Intr        ,
                                                                   IER_Enable_Tx_Holding_Reg_Empty_Intr  ,
                                                                   IER_Enable_Rx_Data_Avail_Intr        };

// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i                     or
         FCR_Enable_FIFO               or
         FCR_64_Byte_FIFO_Enable       or
         IIR_Interrupt_Pending         or
         IIR_Interrupt_Identification  or
         LCR_DLAB_Adr0_Sel             or 
         LCR_DLAB_Adr1_Sel             or
         LCR_Divisor_Latch_Access_Bit  or
         LCR_Break_Control             or 
         LCR_Sticky_Parity             or 
         LCR_Even_Parity_Select        or 
         LCR_Enable_Parity             or 
         LCR_Number_of_Stop_Bits       or
         LCR_Word_Length_Select        or
         MCR_Loop_Back                 or 
         LSR_Rx_FIFO_Data_Error        or
         LSR_Tx_Logic_Empty            or
         LSR_Tx_Storage_Empty          or
         LSR_Rx_Break_Interrupt        or
         LSR_Rx_Framing_Error          or
         LSR_Rx_Parity_Error           or
         LSR_Rx_Overrun_Error          or
         LSR_Rx_Data_Ready             or
		 SCR_Scratch_Reg               or
         Rx_FIFO_Level_i               or
         Tx_FIFO_Level_i
 )
 begin
    case(WBs_ADR_i[3:0])
	4'h0                     : WBs_DAT_o  <= { 8'h0, LCR_DLAB_Adr0_Sel             }; // Controlled by the DLAB bit
	4'h1                     : WBs_DAT_o  <= { 8'h0, LCR_DLAB_Adr1_Sel             }; // Controlled by the DLAB bit
    UART_16550_IIR           : WBs_DAT_o  <= { 8'h0, FCR_Enable_FIFO                ,
                                                     FCR_Enable_FIFO                ,
                                                     FCR_64_Byte_FIFO_Enable        ,
                                               1'b0, IIR_Interrupt_Identification   ,
                                                     IIR_Interrupt_Pending         };
    UART_16550_LCR           : WBs_DAT_o  <= { 8'h0, LCR_Divisor_Latch_Access_Bit   ,
                                                     LCR_Break_Control              ,
                                                     LCR_Sticky_Parity              ,
                                                     LCR_Even_Parity_Select         ,
                                                     LCR_Enable_Parity              ,
                                                     LCR_Number_of_Stop_Bits        ,
                                                     LCR_Word_Length_Select        };
    UART_16550_MCR           : WBs_DAT_o  <= {11'h0, MCR_Loop_Back                  ,
                                               4'h0                                }; 
    UART_16550_LSR           : WBs_DAT_o  <= { 8'h0, LSR_Rx_FIFO_Data_Error         ,
                                                     LSR_Tx_Logic_Empty             ,
                                                     LSR_Tx_Storage_Empty           ,
                                                     LSR_Rx_Break_Interrupt         ,
                                                     LSR_Rx_Framing_Error           ,
                                                     LSR_Rx_Parity_Error            ,
                                                     LSR_Rx_Overrun_Error           ,
                                                     LSR_Rx_Data_Ready             };
    UART_16550_MSR           : WBs_DAT_o  <=  16'h0                                 ;
    UART_16550_SCR           : WBs_DAT_o  <= { 8'h0, SCR_Scratch_Reg               }; 
    UART_16550_RX_FIFO_LEVEL : WBs_DAT_o  <= { 7'h0, Rx_FIFO_Level_i               }; // Extended Register 
    UART_16550_TX_FIFO_LEVEL : WBs_DAT_o  <= { 7'h0, Tx_FIFO_Level_i               }; // Extended Register 
	default                  : WBs_DAT_o  <=  16'h0                                 ;
	endcase
end


// Determine when to Push data into the Transmit FIFO
//
assign Tx_FIFO_Push_o                     =   UART_16550_THR_Wr_Dcd                ;


//
// Determine the Interrupt Controller Logic
//

assign IIR_Interrupt_Pending              =   Interrupt_Pending_i                  ;
assign IIR_Interrupt_Identification       =   Interrupt_Identification_i           ;

assign Enable_Rx_Data_Avail_Intr_o        =   IER_Enable_Rx_Data_Avail_Intr        ;
assign Enable_Tx_Holding_Reg_Empty_Intr_o =   IER_Enable_Tx_Holding_Reg_Empty_Intr ;
assign Enable_Rx_Line_Status_Intr_o       =   IER_Enable_Rx_Line_Status_Intr       ;

//
// FIFO Control Logic
//
assign Rx_Tx_FIFO_Enable_o                =   FCR_Enable_FIFO                      ;
assign Rx_FIFO_Flush_o                    = (~FCR_Enable_FIFO) | FCR_Rx_FIFO_Rst   ;
assign Tx_FIFO_Flush_o                    = (~FCR_Enable_FIFO) | FCR_Tx_FIFO_Rst   ;
assign Rx_Trigger_o                       =   FCR_Rx_Trigger                       ;
assign Rx_64_Byte_FIFO_Enable_o           =   FCR_64_Byte_FIFO_Enable              ;


//
// Line Control
//
assign Rx_Tx_Word_Length_Select_o         =   LCR_Word_Length_Select  ;
assign Rx_Tx_Number_of_Stop_Bits_o        =   LCR_Number_of_Stop_Bits ;
assign Rx_Tx_Enable_Parity_o              =   LCR_Enable_Parity       ;
assign Rx_Tx_Even_Parity_Select_o         =   LCR_Even_Parity_Select  ;
assign Rx_Tx_Sticky_Parity_o              =   LCR_Sticky_Parity       ;
assign Tx_Break_Control_o                 =   LCR_Break_Control       ; // Determine when to force a "Break" output (i.e. hold Tx low)


//
// Modem Control
//
assign Rx_Tx_Loop_Back_o                  =   MCR_Loop_Back           ;


//
// Capture various Line Status Error conditions
//
// Note: Each error condition should be updated on each new Serial Stream capture.
//
//       The value should be held until read. When read, the value is cleared.
//
assign  LSR_Rx_Overrun_Error_nxt          =  (     Rx_Overrun_Error_i                               )
                                          |  ( LSR_Rx_Overrun_Error                                   & (~UART_16550_LSR_Rd_Dcd ));

assign  LSR_Rx_Parity_Error_nxt           =  (      Rx_Parity_Error_i     &   Rx_Line_Status_Load_o )  
                                          |  (  LSR_Rx_Parity_Error       & (~Rx_Line_Status_Load_o ) & (~UART_16550_LSR_Rd_Dcd ));

assign  LSR_Rx_Framing_Error_nxt          =  (     Rx_Framing_Error_i     &   Rx_Line_Status_Load_o )
                                          |  ( LSR_Rx_Framing_Error       & (~Rx_Line_Status_Load_o ) & (~UART_16550_LSR_Rd_Dcd ));

assign  LSR_Rx_Break_Interrupt_nxt        =  (     Rx_Break_Interrupt_i   &   Rx_Line_Status_Load_o )
                                          |  ( LSR_Rx_Break_Interrupt     & (~Rx_Line_Status_Load_o ) & (~UART_16550_LSR_Rd_Dcd ));

assign Rx_Line_Status_Load_o_nxt          =        Rx_Tx_FIFO_Enable_o    ? (  Rx_FIFO_Empty_i        &   Rx_FIFO_Push_i         )
                                                                          | ((~Rx_FIFO_Empty_i)       &   Rx_FIFO_Pop_o          )
													                      :                               Rx_FIFO_Push_i          ;

//
// Line Status
//
assign LSR_Rx_Data_Ready                  =   Rx_Data_Ready_i         ;
assign LSR_Tx_Storage_Empty               =   Tx_Storage_Empty_i      ;
assign LSR_Tx_Logic_Empty                 =   Tx_Logic_Empty_i        ;
assign LSR_Rx_FIFO_Data_Error             =   FCR_Enable_FIFO
                                          & ( LSR_Rx_Parity_Error 
                                          |   LSR_Rx_Framing_Error 
										  |   LSR_Rx_Break_Interrupt );

//
// Define the Line Status Register Interrupt
//
// Note: This line should be pulsed every time a new value becomes available.
//       This makes sure that the corresponding interrupt is updated.
//       Specifically, if there are several bad serial streams in a row that
//       have errors, the interrupt bit should be update for each value;
//       otherwise, the first will be capture and cleared (at the interrupt
//       controller) but the next values are not captured and cleared (at the 
//       interrupt controller). The interrupt controller would see a constant
//       value on the interrupt line and not know that the error re-occurs in 
//       multiple serial streams.
//
assign Line_Status_Intr_o                 =   LSR_Rx_Overrun_Error 
                                          |   LSR_Rx_Parity_Error 
                                          |   LSR_Rx_Framing_Error 
										  |   LSR_Rx_Break_Interrupt  ;


// Determine the System Clock Divider
//
// Note: This sets the base BAUDx16 clock rate.
//
//       A value of "0" means no scaling.
//
assign Tx_Clock_Divisor_o                 = { DLM_Divisor_MSB_Reg, 
                                              DLL_Divisor_LSB_Reg    };



endmodule
