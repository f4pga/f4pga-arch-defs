// -----------------------------------------------------------------------------
// title          : I2C Master with Command Queue Statemachine Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_CmdQueue_StateMachine.v
// author         : Glen Gomes
// company        : QuickLogic Corp
// created        : 2016/03/11	
// last update    : 2016/03/11
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The I2C Master with Command Queue is designed for use in the 
//              fabric of the AL4S3B. The only AL4S3B specific portion is the 
//              Tx FIFO. This design takes the existing I2C Master and adds a 
//              Tx FIFO. This helps to releave the processor from monitoring 
//              each I2C bus transfer.
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/03/11      1.0        Glen Gomes     created
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module I2C_Master_w_CmdQueue_StateMachine (

                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_CQ_o,
                         WBs_CYC_CQ_o,
                         WBs_STB_CQ_o,
                         WBs_WE_CQ_o,

			             WBs_DAT_CQ_Sel_o,

                         WBs_BYTE_STB_i,

                         Tx_FIFO_Flush_i,
                         Tx_FIFO_Empty_i,
                         Tx_FIFO_Pop_o,

                         WBs_ACK_i2c_i,

                         stop_i2c_i,
                         read_i2c_i,
                         write_i2c_i,

                         tip_i2c_i,

                         CQ_Single_Step_i,
                         CQ_Enable_i,
                         CQ_Busy_o

                         );
  

//------Port Parameters----------------
//

//
// None at this time
//

//-----Port Signals--------------------
//  

input                    WBs_CLK_i;           // Fabric Clock               from Fabric
input                    WBs_RST_i;           // Fabric Reset               to   Fabric

output            [2:0]  WBs_ADR_CQ_o;
output                   WBs_CYC_CQ_o;
output                   WBs_STB_CQ_o;
output                   WBs_WE_CQ_o;

output            [1:0]  WBs_DAT_CQ_Sel_o;

input                    WBs_BYTE_STB_i;

input                    Tx_FIFO_Flush_i;
input                    Tx_FIFO_Empty_i;
output                   Tx_FIFO_Pop_o;

input                    WBs_ACK_i2c_i;

input                    stop_i2c_i;
input                    read_i2c_i;
input                    write_i2c_i;

input                    tip_i2c_i;

input                    CQ_Single_Step_i;
input                    CQ_Enable_i;
output                   CQ_Busy_o;


wire                     WBs_CLK_i;
wire                     WBs_RST_i;

reg               [2:0]  WBs_ADR_CQ_o;
wire              [2:0]  WBs_ADR_CQ_o_nxt;

reg                      WBs_CYC_CQ_o;
reg                      WBs_CYC_CQ_o_nxt;

reg                      WBs_STB_CQ_o;
reg                      WBs_STB_CQ_o_nxt;

reg                      WBs_WE_CQ_o;
reg                      WBs_WE_CQ_o_nxt;

reg               [1:0]  WBs_DAT_CQ_Sel_o;
reg               [1:0]  WBs_DAT_CQ_Sel_o_nxt;

wire                     WBs_BYTE_STB_i;

wire                     Tx_FIFO_Flush_i;
wire                     Tx_FIFO_Empty_i;

reg                      Tx_FIFO_Pop_o;
reg                      Tx_FIFO_Pop_o_nxt;

wire                     WBs_ACK_i2c_i;

wire                     stop_i2c_i;
wire                     read_i2c_i;
wire                     write_i2c_i;

wire                     tip_i2c_i;

wire                     CQ_Single_Step_i;

wire                     CQ_Enable_i;

reg                      CQ_Busy_o;
reg                      CQ_Busy_o_nxt;


//------Define Parameters---------
//

//
// Define the Command Queue Statemachine States
//
// Note: These states are chosen to allow for overlap of various signals
//       during operation. This overlap should help reduce timing
//       dependancies.
//

parameter CQ_IDLE              = 3'h0;
parameter CQ_EVAL              = 3'h1;
parameter CQ_INCR              = 3'h2;
parameter CQ_WB_XFR            = 3'h3;
parameter CQ_WAIT_TIP_ON       = 3'h4;
parameter CQ_WAIT_TIP_OFF      = 3'h5;

parameter I2C_COMMAND_REG_ADR  = 3'h4;
parameter I2C_TRANSMIT_REG_ADR = 3'h3;


//-----Internal Signals--------------------
//


//
// Define the Statemachine registers
//
reg               [3:0]  CQ_State            ;
reg               [3:0]  CQ_State_nxt        ;

reg                      CQ_CMD_Phase        ;
reg                      CQ_CMD_Phase_nxt    ;

wire                     CQ_State_Single_Step;

wire                     CQ_State_Enable     ;

wire                     bus_cycle_i2c       ;


//------Logic Operations----------
//


// Define the registers associated with the Command Queue Statemachine
//
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        CQ_State           <= CQ_IDLE;
        CQ_Busy_o          <=  1'b0  ;
        CQ_CMD_Phase       <=  1'b0  ;

		WBs_ADR_CQ_o       <=  3'h0  ;
		WBs_CYC_CQ_o       <=  1'b0  ;
        WBs_STB_CQ_o       <=  1'b0  ;
        WBs_WE_CQ_o        <=  1'b0  ;

        WBs_DAT_CQ_Sel_o   <=  2'h0  ;

        Tx_FIFO_Pop_o      <=  1'b0  ;
    end
    else 
    begin  
        CQ_State           <=  CQ_State_nxt        ;
        CQ_Busy_o          <=  CQ_Busy_o_nxt       ;
        CQ_CMD_Phase       <=  CQ_CMD_Phase_nxt    ;

		WBs_ADR_CQ_o       <=  WBs_ADR_CQ_o_nxt    ;
		WBs_CYC_CQ_o       <=  WBs_CYC_CQ_o_nxt    ;
        WBs_STB_CQ_o       <=  WBs_STB_CQ_o_nxt    ;
        WBs_WE_CQ_o        <=  WBs_WE_CQ_o_nxt     ;

        WBs_DAT_CQ_Sel_o   <=  WBs_DAT_CQ_Sel_o_nxt;

        Tx_FIFO_Pop_o      <=  Tx_FIFO_Pop_o_nxt   ;
 	end
end   


// Define the conditions for starting the Command Queue Statemachine
//
assign CQ_State_Enable      = (~Tx_FIFO_Empty_i) & (~Tx_FIFO_Flush_i) & CQ_Enable_i ;


// Define the "Single Step" Operation
//
// Note: "Single Step" allows byte writes to the Tx FIFO to work correctly.
//
assign CQ_State_Single_Step = (CQ_Single_Step_i) & (~Tx_FIFO_Flush_i) & CQ_Enable_i ;


// Determine the target I2C Address for each I/O to the I2C Master
//
assign WBs_ADR_CQ_o_nxt     =  CQ_CMD_Phase ?  I2C_COMMAND_REG_ADR : I2C_TRANSMIT_REG_ADR;


// Define the condition when the I2C Master will generate bus traffic on the
// external I2C bus.
//
assign bus_cycle_i2c        = stop_i2c_i
                            | read_i2c_i
                            | write_i2c_i;


// Define the Command Queue Statemachine
//
always @( CQ_State             or
          CQ_State_Enable      or

          CQ_State_Single_Step or

          CQ_CMD_Phase         or

          Tx_FIFO_Flush_i      or
          Tx_FIFO_Empty_i      or

          WBs_DAT_CQ_Sel_o     or
          WBs_BYTE_STB_i       or

		  WBs_ACK_i2c_i        or
          bus_cycle_i2c        or
          tip_i2c_i
         )
begin
    case(CQ_State)
    CQ_IDLE:
	begin

        case(CQ_State_Single_Step)
        1'b0: CQ_CMD_Phase_nxt    <= 1'b0             ;  // 1st phase is data
        1'b1: CQ_CMD_Phase_nxt    <= CQ_CMD_Phase     ;  // Hold the current Command/Data phase
        endcase

		WBs_CYC_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_CQ_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle
 
        WBs_DAT_CQ_Sel_o_nxt      <= 2'h0             ;  // Point to the first byte out of the FIFO

        Tx_FIFO_Pop_o_nxt         <= 1'b0             ;  // Hold the FIFO

		case(CQ_State_Enable)
		1'b0:    // No Activity
		begin
            CQ_State_nxt          <= CQ_IDLE          ;
		    CQ_Busy_o_nxt         <= 1'b0             ;
        end
		1'b1:    // Start at the Command Queue Processing
		begin
            CQ_State_nxt          <= CQ_EVAL          ;
		    CQ_Busy_o_nxt         <= 1'b1             ;
        end
        endcase

	end
	CQ_EVAL:
    begin
        case( {CQ_State_Enable, WBs_BYTE_STB_i} )
        2'b10:                                           // Invalid Byte in the FIFO
        begin
            case( WBs_DAT_CQ_Sel_o)
            2'b11:                                       // Need to get a new 32-bit value
            begin
                CQ_State_nxt      <= CQ_INCR          ;  // Get a new 32-bit value from the FIFO
                Tx_FIFO_Pop_o_nxt <= 1'b1             ;  // Increment the FIFO
            end
            default:                                     // Continue to check the current 32-bit value
            begin
                CQ_State_nxt      <= CQ_EVAL          ;  // Check for valid Command/Data
                Tx_FIFO_Pop_o_nxt <= 1'b0             ;  // Hold the FIFO
            end
            endcase

		    CQ_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
            CQ_CMD_Phase_nxt      <= CQ_CMD_Phase     ;  // Hold the current Command/Data phase

		    WBs_CYC_CQ_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_STB_CQ_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_WE_CQ_o_nxt       <= 1'b0             ;  // Wishbone bus to I2C is Idle

            WBs_DAT_CQ_Sel_o_nxt  <= WBs_DAT_CQ_Sel_o + 1'b1; // Increment the byte selection
        end
        2'b11:                                           // Valid Byte in the FIFO
        begin
            CQ_State_nxt          <= CQ_WB_XFR        ;  // Write the Byte to the I2C Master
		    CQ_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
            CQ_CMD_Phase_nxt      <= CQ_CMD_Phase     ;  // Hold the current Command/Data phase

		    WBs_CYC_CQ_o_nxt      <= 1'b1             ;  // Begin Wishbone bus to I2C Master transfer
		    WBs_STB_CQ_o_nxt      <= 1'b1             ;  // Begin Wishbone bus to I2C Master transfer
		    WBs_WE_CQ_o_nxt       <= 1'b1             ;  // Begin Wishbone bus to I2C Master transfer

            WBs_DAT_CQ_Sel_o_nxt  <= WBs_DAT_CQ_Sel_o ;  // Hold the current byte selection

            Tx_FIFO_Pop_o_nxt     <= 1'b0             ;  // Hold the FIFO
        end
        default:
        begin
            CQ_State_nxt          <= CQ_IDLE          ;  // No more data to process
		    CQ_Busy_o_nxt         <= 1'b0             ;  // Command Queue is done with transfers

            case(CQ_State_Single_Step)
            1'b0: CQ_CMD_Phase_nxt <= 1'b0            ;  // 1st phase is data
            1'b1: CQ_CMD_Phase_nxt <= CQ_CMD_Phase    ;  // Hold the current Command/Data phase
            endcase

		    WBs_CYC_CQ_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_STB_CQ_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_WE_CQ_o_nxt       <= 1'b0             ;  // Wishbone bus to I2C is Idle

            WBs_DAT_CQ_Sel_o_nxt  <= 3'h0             ;  // Hold the current byte selection

            Tx_FIFO_Pop_o_nxt     <= 1'b0             ;  // Hold the FIFO
        end
        endcase
    end
	CQ_INCR:
    begin
        CQ_State_nxt              <= CQ_EVAL          ;
		CQ_Busy_o_nxt             <= 1'b1             ;  // Command Queue Busy with transfers
        CQ_CMD_Phase_nxt          <= CQ_CMD_Phase     ;  // Hold the current Command/Data phase

		WBs_CYC_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_CQ_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle

        WBs_DAT_CQ_Sel_o_nxt      <= WBs_DAT_CQ_Sel_o ;  // Hold the current byte selection

        Tx_FIFO_Pop_o_nxt         <= 1'b0             ;  // Hold the FIFO
    end
	CQ_WB_XFR:
    begin
        case( {WBs_ACK_i2c_i,  CQ_CMD_Phase} )
        2'b10: 
        begin
            // Check if a new 32-bit word needs to be read from the FIFO
            //
            case(WBs_DAT_CQ_Sel_o)
            2'b11: 
            begin
                CQ_State_nxt      <= CQ_INCR                ; // Wishbone Acknowledge received
                Tx_FIFO_Pop_o_nxt <= 1'b1                   ; // Get the next value from the FIFO
            end
            default: 
            begin
                CQ_State_nxt      <= CQ_EVAL                ; // Wishbone Acknowledge received
                Tx_FIFO_Pop_o_nxt <= 1'b0                   ; // Hold the FIFO
            end
            endcase

            CQ_CMD_Phase_nxt      <= ~CQ_CMD_Phase          ; // Switch to the next command/data phase
		    WBs_CYC_CQ_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_STB_CQ_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_WE_CQ_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Idle
            WBs_DAT_CQ_Sel_o_nxt  <= WBs_DAT_CQ_Sel_o + 1'b1; // Increment the byte selection
        end
        2'b11: 
        begin
            case(bus_cycle_i2c)
            1'b0:                                             // No I2C Bus Transfer
            begin
                // Check if a new 32-bit word needs to be read from the FIFO
                //
                case(WBs_DAT_CQ_Sel_o)
                2'b11:   
                begin
                    CQ_State_nxt      <= CQ_INCR            ; // Wishbone Acknowledge received
                    Tx_FIFO_Pop_o_nxt <= 1'b1               ; // Get the next value from the FIFO
                end
                default: 
                begin
                    CQ_State_nxt      <= CQ_EVAL            ; // Wishbone Acknowledge received
                    Tx_FIFO_Pop_o_nxt <= 1'b0               ; // Hold the FIFO
                end
                endcase
            end
            1'b1:                                             // I2C Bus Transfer
            begin
                CQ_State_nxt      <= CQ_WAIT_TIP_ON         ; // Wishbone Acknowledge received

                // Check if a new 32-bit word needs to be read from the FIFO
                //
                case(WBs_DAT_CQ_Sel_o)
                2'b11:   Tx_FIFO_Pop_o_nxt <= 1'b1          ; // Get the next value from the FIFO
                default: Tx_FIFO_Pop_o_nxt <= 1'b0          ; // Hold the FIFO
                endcase
            end
            endcase

            CQ_CMD_Phase_nxt      <= ~CQ_CMD_Phase          ; // Switch to the next command/data phase
		    WBs_CYC_CQ_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_STB_CQ_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_WE_CQ_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Idle
            WBs_DAT_CQ_Sel_o_nxt  <= WBs_DAT_CQ_Sel_o + 1'b1; // Increment the byte selection

        end
        default:
        begin
            CQ_State_nxt          <= CQ_WB_XFR              ; // Wait for the Wishbone Acknowledge
            CQ_CMD_Phase_nxt      <= CQ_CMD_Phase           ; // Hold the current data phase
		    WBs_CYC_CQ_o_nxt      <= 1'b1                   ; // Wishbone bus to I2C is Active
		    WBs_STB_CQ_o_nxt      <= 1'b1                   ; // Wishbone bus to I2C is Active
		    WBs_WE_CQ_o_nxt       <= 1'b1                   ; // Wishbone bus to I2C is Active
            WBs_DAT_CQ_Sel_o_nxt  <= WBs_DAT_CQ_Sel_o       ; // Hold the current byte selection
            Tx_FIFO_Pop_o_nxt     <= 1'b0                   ; // Hold the FIFO
        end
        endcase

		CQ_Busy_o_nxt             <= 1'b1                   ; // Command Queue Busy with transfers
    end
	CQ_WAIT_TIP_ON:
    begin
        // Wait for the I2C Master to begin its I2C bus transfer
        //
        case( tip_i2c_i )
        1'b0: CQ_State_nxt        <= CQ_WAIT_TIP_ON   ;  // Wait for the I2C Master to start its I2C Bus transfers
        1'b1: CQ_State_nxt        <= CQ_WAIT_TIP_OFF  ;  // The I2C Master began its I2C Bus transfers
        endcase

        CQ_Busy_o_nxt             <= 1'b1             ;  // Command Queue Busy with transfers
        CQ_CMD_Phase_nxt          <= CQ_CMD_Phase     ;  // Hold Phase Selections

		WBs_CYC_CQ_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_STB_CQ_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_WE_CQ_o_nxt           <= 1'b0             ;  // Between Wishbone Transfers

        WBs_DAT_CQ_Sel_o_nxt      <= WBs_DAT_CQ_Sel_o ;  // Hold the current selection

        Tx_FIFO_Pop_o_nxt         <= 1'b0             ;  // Hold the FIFO
    end
	CQ_WAIT_TIP_OFF:
    begin
        // Wait for the I2C Master to begin its I2C bus transfer
        //
        case( {CQ_State_Enable, tip_i2c_i}  )
        2'b00: 
        begin
            CQ_State_nxt          <= CQ_IDLE          ;  // Processing complete
		    CQ_Busy_o_nxt         <= 1'b0             ;  // Command Queue is not Busy with transfers
        end
        2'b01: 
        begin
            CQ_State_nxt          <= CQ_WAIT_TIP_OFF  ;  // Wait for the current I2C Bus transfer to complete before ending CQ processing
		    CQ_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
        end
        2'b10: 
        begin
            CQ_State_nxt          <= CQ_EVAL          ;  // Look to the next transfer
		    CQ_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
        end
        2'b11: 
        begin
            CQ_State_nxt          <= CQ_WAIT_TIP_OFF  ;  // Wait for the current I2C Bus transfer to complete
		    CQ_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
        end
        endcase

        CQ_CMD_Phase_nxt          <= CQ_CMD_Phase     ;  // Hold Phase Selections

		WBs_CYC_CQ_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_STB_CQ_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_WE_CQ_o_nxt           <= 1'b0             ;  // Between Wishbone Transfers

        WBs_DAT_CQ_Sel_o_nxt      <= WBs_DAT_CQ_Sel_o ;  // Hold the current byte selection

        Tx_FIFO_Pop_o_nxt         <= 1'b0             ;  // Hold the FIFO
    end
	default:
    begin
        CQ_State_nxt              <= CQ_IDLE          ;  // Waiting for the start of processing
		CQ_Busy_o_nxt             <= 1'b0             ;  // Command Queue is not busy with transfers
        CQ_CMD_Phase_nxt          <= 1'b0             ;  // 1st phase is data

		WBs_CYC_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_CQ_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_CQ_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle

        WBs_DAT_CQ_Sel_o_nxt      <= 2'h0             ;  // Point to the first byte out of the FIFO

        Tx_FIFO_Pop_o_nxt         <= 1'b0             ;  // Hold the FIFO
    end
	endcase
end	


endmodule
