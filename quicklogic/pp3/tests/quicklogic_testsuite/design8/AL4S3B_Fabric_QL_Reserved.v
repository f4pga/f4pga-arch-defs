// -----------------------------------------------------------------------------
// title          : AL4S3B Example Fabric Register Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : AL4S3B_Fabric_QL_Reserved.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2016/02/03	
// last update    : 2016/02/03
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: The Fabric example IP design contains the essential logic for
//              interfacing the ASSP of the AL4S3B to QuickLogic reserved registers 
//              and memory located in the programmable fabric.
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


module AL4S3B_Fabric_QL_Reserved ( 

                         // AHB-To_Fabric Bridge I/F
                         //
                         WBs_ADR_i            ,
                         WBs_CYC_QL_Reserved_i,
                         WBs_CYC_i            ,
                         WBs_STB_i            ,
                         WBs_CLK_i            ,
                         WBs_RST_i            ,
                         WBs_DAT_o            ,
                         WBs_ACK_i            ,
                         WBs_ACK_o

                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7           ;   // Allow for up to 128 registers in the fabric
parameter                DATAWIDTH                   =  32           ;   // Allow for up to 128 registers in the fabric

parameter                QL_RESERVED_CUST_PROD_ADR   =  7'h7E        ;
parameter                QL_RESERVED_REVISIONS_ADR   =  7'h7F        ;

parameter                QL_RESERVED_CUSTOMER_ID     =  8'h01        ;  
parameter                QL_RESERVED_PRODUCT_ID      =  8'h00        ;
parameter                QL_RESERVED_MAJOR_REV       = 16'h0001      ; 
parameter                QL_RESERVED_MINOR_REV       = 16'h0000      ;

parameter                QL_RESERVED_DEF_REG_VALUE   = 32'hDEF_FAB_AC; // Distinguish access to undefined area

parameter                DEFAULT_CNTR_WIDTH          =  3            ;
parameter                DEFAULT_CNTR_TIMEOUT        =  7            ;


//------Port Signals-------------------
//

// AHB-To_Fabric Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i            ; // Address Bus                to   Fabric
input                    WBs_CYC_QL_Reserved_i; // Cycle Chip Select          to   Fabric
input                    WBs_CYC_i            ; // Cycle Chip Select          to   Fabric
input                    WBs_STB_i            ; // Strobe Signal              to   Fabric
input                    WBs_CLK_i            ; // Fabric Clock               from Fabric
input                    WBs_RST_i            ; // Fabric Reset               to   Fabric
output  [DATAWIDTH-1:0]  WBs_DAT_o            ; // Read Data Bus              from Fabric
input                    WBs_ACK_i            ;
output                   WBs_ACK_o            ; // Transfer Cycle Acknowledge from Fabric


// Fabric Global Signals
//
wire                     WBs_CLK_i            ; // Wishbone Fabric Clock
wire                     WBs_RST_i            ; // Wishbone Fabric Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i            ; // Wishbone Address Bus
wire                     WBs_CYC_QL_Reserved_i; // Cycle Chip Select          to   Fabric
wire                     WBs_CYC_i            ; // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire                     WBs_STB_i            ; // Wishbone Transfer      Strobe
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o            ; // Wishbone Read   Data Bus

wire                     WBs_ACK_i            ;

reg                      WBs_ACK_o            ; // Wishbone Client Acknowledge
wire                     WBs_ACK_o_nxt        ; // Wishbone Client Acknowledge


//------Define Parameters--------------
//

// Default I/O timeout statemachine
//
parameter                DEFAULT_IDLE   =  0  ;
parameter                DEFAULT_COUNT  =  1  ;


//------Internal Signals---------------
//

// Wishbone Bus Signals - Default acknowledge
//
reg                            Default_State      ;
reg                            Default_State_nxt  ;

reg  [DEFAULT_CNTR_WIDTH-1:0]  Default_Cntr       ;
reg  [DEFAULT_CNTR_WIDTH-1:0]  Default_Cntr_nxt   ;

reg                            WBs_ACK_Default_nxt;        // Wishbone Client Acknowledge


//------Logic Operations---------------
//


// Define the Default Acknowledge Statemachine's register
//
// Note: The Default Acknowledge statemachine will acknowledge any accesss to
//       the fabric after a fixed timeout period. The timeout period is long
//       enough to allow any instantiated IP to acknowledge the incomming
//       transfer cycle. If a timeout happens, this means that the AHB access
//       is not going to an address occupied by one of the Fabric IPs. By
//       acknowledging these accesses, the AHB bus is not left to wait
//       indefinitly for a Wishbone bus acknowledge that never comes.
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        Default_State      <=  DEFAULT_IDLE        ;
        Default_Cntr       <=  DEFAULT_CNTR_TIMEOUT;
        WBs_ACK_o          <=  1'b0                ;
    end  
    else
    begin
        Default_State      <=  Default_State_nxt   ;
        Default_Cntr       <=  Default_Cntr_nxt    ;
        WBs_ACK_o          <=  WBs_ACK_o_nxt 
                            |  WBs_ACK_Default_nxt ;
    end  
end


// Define the Wishbone bus transfer default acknowledge
//
// Note: This acknowledge prevents access to the fabric from locking the AHB
//       bus due to I/O to unassigned fabric aperture addresses.
//
always @(WBs_CYC_i     or
         WBs_STB_i     or
         WBs_ACK_i     or
         Default_State or
         Default_Cntr
        )
begin
    case(Default_State)
    DEFAULT_IDLE:  // Wait for a transfer in the Fabric memory aperture
    begin
        Default_Cntr_nxt           <= DEFAULT_CNTR_TIMEOUT ;
        WBs_ACK_Default_nxt        <= 1'b0                 ;

        case({WBs_CYC_i, WBs_STB_i})
        default: Default_State_nxt <= DEFAULT_IDLE         ;
        2'b11  : Default_State_nxt <= DEFAULT_COUNT        ;
        endcase
    end
    DEFAULT_COUNT: // Check if one of the fabric IP's has responded before the timeout period
    begin
        Default_Cntr_nxt           <= Default_Cntr - 1'b1  ; 

        case(WBs_ACK_i)
        1'b0: Default_State_nxt    <= DEFAULT_COUNT        ;
        1'b1: Default_State_nxt    <= DEFAULT_IDLE         ;
        endcase

        if (Default_Cntr == {{(DEFAULT_CNTR_WIDTH-1){1'b0}}, 1'b1}) 
            WBs_ACK_Default_nxt    <= 1'b1                 ;
        else
            WBs_ACK_Default_nxt    <= 1'b0                 ;
    end
    default:       // Something unexpected happend, return to "Idle".
    begin
        Default_State_nxt          <=  DEFAULT_IDLE        ;
        Default_Cntr_nxt           <=  DEFAULT_CNTR_TIMEOUT;
        WBs_ACK_Default_nxt        <=  1'b0                ;
    end
    endcase
end


// Define the Acknowledge back to the host for the "reserved" registers
//
assign WBs_ACK_o_nxt = WBs_CYC_QL_Reserved_i & WBs_STB_i & (~WBs_ACK_o);


// Define the how to read the local registers and memory
//
always @(
         WBs_ADR_i
        )
begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
    QL_RESERVED_CUST_PROD_ADR   : WBs_DAT_o <= { 16'h0, QL_RESERVED_CUSTOMER_ID, QL_RESERVED_PRODUCT_ID };
    QL_RESERVED_REVISIONS_ADR   : WBs_DAT_o <= {        QL_RESERVED_MAJOR_REV  , QL_RESERVED_MINOR_REV  };
	default                     : WBs_DAT_o <=          QL_RESERVED_DEF_REG_VALUE                        ;
	endcase
end

endmodule
