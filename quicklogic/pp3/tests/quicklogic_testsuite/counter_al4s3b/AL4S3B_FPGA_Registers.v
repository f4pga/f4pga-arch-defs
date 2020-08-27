`timescale 1ns / 10ps
module AL4S3B_FPGA_Registers ( 

                         // AHB-To_FPGA Bridge I/F
                         //
                         WBs_ADR_i,
                         WBs_CYC_i,
                         WBs_BYTE_STB_i,
                         WBs_WE_i,
                         WBs_STB_i,
                         WBs_DAT_i,
                         WBs_CLK_i,
                         WBs_RST_i,
                         WBs_DAT_o,
                         WBs_ACK_o,

                         Device_ID_o,
						 	 
				         count
                         );


//------Port Parameters----------------
//

parameter                ADDRWIDTH                   =   7  ;   // Allow for up to 128 registers in the FPGA
parameter                DATAWIDTH                   =  32  ;   // Allow for up to 128 registers in the FPGA

parameter      			 FPGA_REG_ID_VALUE_ADR     	 =  7'h0; 
parameter      			 FPGA_REV_NUM_ADR          	 =  7'h1; 
parameter      			 FPGA_CNT_SET_RST_REG_ADR  	 =  7'h2; 
parameter      			 FPGA_CNT_EN_REG_ADR       	 =  7'h3;
parameter      			 FPGA_CNT_ERR_STS_ADR      	 =  7'h4; 
parameter      			 FPGA_CNT_VAL_REG_ADR      	 =  7'h5;

parameter                AL4S3B_DEVICE_ID            = 16'h0;
parameter                AL4S3B_REV_LEVEL            = 32'h0;

parameter                AL4S3B_DEF_REG_VALUE        = 32'hFAB_DEF_AC;


//------Port Signals-------------------
//

// AHB-To_FPGA Bridge I/F
//
input   [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Address Bus                to   FPGA
input                    WBs_CYC_i     ;  // Cycle Chip Select          to   FPGA
input             [3:0]  WBs_BYTE_STB_i;  // Byte Select                to   FPGA
input                    WBs_WE_i      ;  // Write Enable               to   FPGA
input                    WBs_STB_i     ;  // Strobe Signal              to   FPGA
input   [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Write Data Bus             to   FPGA
input                    WBs_CLK_i     ;  // FPGA Clock               from FPGA
input                    WBs_RST_i     ;  // FPGA Reset               to   FPGA
output  [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Read Data Bus              from FPGA
output                   WBs_ACK_o     ;  // Transfer Cycle Acknowledge from FPGA

//
// Misc
//
output           [31:0]  Device_ID_o   ;

output           [15:0]  count    ;


// FPGA Global Signals
//
wire                     WBs_CLK_i     ;  // Wishbone FPGA Clock
wire                     WBs_RST_i     ;  // Wishbone FPGA Reset

// Wishbone Bus Signals
//
wire    [ADDRWIDTH-1:0]  WBs_ADR_i     ;  // Wishbone Address Bus
wire                     WBs_CYC_i     ;  // Wishbone Client Cycle  Strobe (i.e. Chip Select)
wire              [3:0]  WBs_BYTE_STB_i;  // Wishbone Byte   Enables
wire                     WBs_WE_i      ;  // Wishbone Write  Enable Strobe
wire                     WBs_STB_i     ;  // Wishbone Transfer      Strobe
wire    [DATAWIDTH-1:0]  WBs_DAT_i     ;  // Wishbone Write  Data Bus
 
reg     [DATAWIDTH-1:0]  WBs_DAT_o     ;  // Wishbone Read   Data Bus

reg                      WBs_ACK_o     ;  // Wishbone Client Acknowledge

// Misc
//
wire               [31:0]  Device_ID_o   ;
wire               [15:0]  Rev_No        ;

reg                [15:0]  count_r    ; 
reg                [15:0]  count_chk  ;
reg 					   cntr_set, cntr_rst, cntr_en,cntr_chk_en;
wire 					   cntr_sts;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//
wire                     FPGA_CNT_SET_RST_Dcd    ;
wire                     FPGA_CNT_EN_REG_Dcd ;

wire					 WBs_ACK_o_nxt;

//------Logic Operations---------------
//

assign count = count_r;
// Define the FPGA's local register write enables
//
assign FPGA_CNT_SET_RST_Dcd    = ( WBs_ADR_i == FPGA_CNT_SET_RST_REG_ADR    ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);
assign FPGA_CNT_EN_REG_Dcd     = ( WBs_ADR_i == FPGA_CNT_EN_REG_ADR     ) & WBs_CYC_i & WBs_STB_i & WBs_WE_i   & (~WBs_ACK_o);

// Define the Acknowledge back to the host for registers
//
assign WBs_ACK_o_nxt          =   WBs_CYC_i & WBs_STB_i & (~WBs_ACK_o);


// Define the FPGA's Local Registers
//
always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        cntr_set         <= 1'b0     ; 
        cntr_rst         <= 1'b0     ;
		cntr_en          <= 1'b0     ;
		cntr_chk_en      <= 1'b0     ;
        WBs_ACK_o        <= 1'b0     ;
    end  
    else
    begin
        // Define the GPIO Register 
        //
        if(FPGA_CNT_SET_RST_Dcd && WBs_BYTE_STB_i[0]) begin
			cntr_rst         <= WBs_DAT_i[0]  ;
			cntr_set         <= WBs_DAT_i[4]  ;
        end
		else begin
			cntr_set         <= 1'b0     ;
			cntr_rst         <= 1'b0     ;
		end

        if(FPGA_CNT_EN_REG_Dcd && WBs_BYTE_STB_i[0]) begin
			cntr_en          <= WBs_DAT_i[0]  ;
			cntr_chk_en      <= WBs_DAT_i[1]  ;
        end

        WBs_ACK_o                   <=  WBs_ACK_o_nxt  ;
    end  
end


always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        count_r          <= 16'h0     ;
    end  
    else
    begin
         if (cntr_rst)
			count_r <= 16'h0;
		 else if (cntr_set)
			count_r <= 16'hFFFF;
		 else if (cntr_en)
            count_r <= count_r + 1;
         else
            count_r <= count_r;
    end  
end

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        count_chk          <= 16'h0     ;
    end  
    else
    begin
         if (cntr_rst)
			count_chk <= 16'h0;
		 else if (cntr_set)
			count_chk <= 16'hFFFF;
		 else if (cntr_chk_en)
            count_chk <= count_chk + 1;
         else
            count_chk <= count_chk;
    end  
end

assign cntr_sts = (count_r != count_chk);

// Define the how to read the local registers and memory
//
assign Device_ID_o = 32'h12340C16 ;
assign Rev_No = 16'h100 ;
always @(
         WBs_ADR_i         or
         Device_ID_o       or
         Rev_No  		   or
         cntr_set          or
         cntr_rst          or
		 cntr_en           or
		 cntr_sts          or
         count_r                
 )
 begin
    case(WBs_ADR_i[ADDRWIDTH-1:0])
		FPGA_REG_ID_VALUE_ADR     : WBs_DAT_o <= Device_ID_o;
		FPGA_REV_NUM_ADR          : WBs_DAT_o <= { 16'h0, Rev_No };  
		FPGA_CNT_SET_RST_REG_ADR  : WBs_DAT_o <= { 27'h0,cntr_set,3'h0,cntr_rst};
		FPGA_CNT_EN_REG_ADR       : WBs_DAT_o <= { 30'h0,cntr_chk_en,cntr_en};
		FPGA_CNT_ERR_STS_ADR      : WBs_DAT_o <= { 31'h0, cntr_sts }; 
		FPGA_CNT_VAL_REG_ADR      : WBs_DAT_o <= { 16'h0, count_r };
		default                   : WBs_DAT_o <= AL4S3B_DEF_REG_VALUE;
	endcase
end

endmodule
