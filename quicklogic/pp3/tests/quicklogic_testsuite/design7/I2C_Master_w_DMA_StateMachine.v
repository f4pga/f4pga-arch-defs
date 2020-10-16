// -----------------------------------------------------------------------------
// title          : HRM DMA Controler State machine Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : I2C_Master_w_DMA_StateMachine.v
// author         : Rakesh M
// company        : QuickLogic Corp
// created        : 2016/05/23	
// last update    : 2016/05/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: HRM DMA controller
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/05/11      1.0        Rakesh. M         created / Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module I2C_Master_w_DMA_StateMachine (

                         WBs_CLK_i,
                         WBs_RST_i,

                         WBs_ADR_DMA_o,
                         WBs_CYC_DMA_o,
                         WBs_STB_DMA_o,
                         WBs_WE_DMA_o,
						 
						 WBs_DAT_DMA_o,
						 
						 WBs_DAT_I2C_i,
						 
						 I2C_SEN_DATA1_o,

						 SEL_16BIT_i,
						 SLV_REG_ADR_i,
						 DMA_Clr_o,
						 
						 DMA_REQ_o,
						 DMA_DONE_o,
						 DMA_Active_i,
						 DMA_Active_o,

                         WBs_ACK_i2c_i,

                         tip_i2c_i,
						 rx_ack_i,
						 DMA_I2C_NACK_o,

                         DMA_Enable_i,
                         DMA_Busy_o

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

output            [2:0]  WBs_ADR_DMA_o;
output                   WBs_CYC_DMA_o;
output                   WBs_STB_DMA_o;
output                   WBs_WE_DMA_o;

input                    WBs_ACK_i2c_i;

input                    tip_i2c_i;
input                    rx_ack_i;

input					 SEL_16BIT_i;

input                    DMA_Enable_i;
output                   DMA_Busy_o;

output    				 DMA_Clr_o;

output [7:0]             WBs_DAT_DMA_o;

input [7:0]              WBs_DAT_I2C_i;

output [23:0]            I2C_SEN_DATA1_o;

output					 DMA_REQ_o; 
output					 DMA_DONE_o;
input				     DMA_Active_i;
output				     DMA_Active_o;

input [15:0]             SLV_REG_ADR_i;

output					DMA_I2C_NACK_o;


wire                     WBs_CLK_i;
wire                     WBs_RST_i;

reg               [2:0]  WBs_ADR_DMA_o;
wire              [2:0]  WBs_ADR_DMA_o_nxt;

reg                      WBs_CYC_DMA_o;
reg                      WBs_CYC_DMA_o_nxt;

reg                      WBs_STB_DMA_o;
reg                      WBs_STB_DMA_o_nxt;

reg                      WBs_WE_DMA_o;
reg                      WBs_WE_DMA_o_nxt;

wire                     WBs_ACK_i2c_i;

wire                     tip_i2c_i;
wire                     rx_ack_i;

reg [7:0]             WBs_DAT_DMA_o;


wire                     DMA_Enable_i;

reg                      DMA_Busy_o;
reg                      DMA_Busy_o_nxt;

reg 					 DMA_REQ_o;
reg						 dma_req_nxt;

reg 					 DMA_DONE_o;
reg 					 dma_done_nxt;

reg            	dma_active_i_1ff;
reg            	dma_active_i_2ff;

reg            [2:0]  i2c_trnfr_cnt;
reg            [2:0]  i2c_trnfr_cnt_nxt;

reg            	DMA_Clr_o;
reg             dma_clr_o_nxt;

reg            [7:0]  sen_dat_byte11;
reg            [7:0]  sen_dat_byte12;
reg            [7:0]  sen_dat_byte13;

reg 				i2c_rd_en;
wire		  [7:0]	sen_reg_adr; 

reg					DMA_I2C_NACK_o;

wire 		[7:0] stp_rd_cmd;

//------Define Parameters---------
//

//
// Define the Command Queue Statemachine States
//
// Note: These states are chosen to allow for overlap of various signals
//       during operation. This overlap should help reduce timing
//       dependancies.
//
parameter DMA_IDLE              = 3'h0;
parameter DMA_EVAL              = 3'h1;
parameter DMA_I2C_TR_Done       = 3'h2;
parameter DMA_WB_XFR            = 3'h3;
parameter DMA_WAIT_TIP_ON       = 3'h4;
parameter DMA_WAIT_TIP_OFF      = 3'h5;
parameter SDMA_Start_st		    = 3'h6; 
parameter SDMA_Done_st		    = 3'h7;

parameter I2C_COMMAND_REG_ADR  = 3'h4;
parameter I2C_TRANSMIT_REG_ADR = 3'h3;


//-----Internal Signals--------------------
//
// Define the Statemachine registers
//
reg               [3:0]  DMA_State            ;
reg               [3:0]  DMA_State_nxt        ;

reg                      DMA_CMD_Phase        ;
reg                      DMA_CMD_Phase_nxt    ;



//------Logic Operations----------
//


// Define the registers associated with the Command Queue Statemachine
//
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        DMA_State           <= DMA_IDLE;
        DMA_Busy_o          <=  1'b0  ;
        DMA_CMD_Phase       <=  1'b0  ;
		DMA_Clr_o	        <=  1'b0  ;
		DMA_REQ_o			<=  1'b0  ;
		DMA_DONE_o			<=  1'b0  ;

		WBs_ADR_DMA_o       <=  3'b0  ;
		WBs_CYC_DMA_o       <=  1'b0  ;
        WBs_STB_DMA_o       <=  1'b0  ;
        WBs_WE_DMA_o        <=  1'b0  ;

		i2c_trnfr_cnt		<=  3'b0  ;
		
		dma_active_i_1ff	<=  1'b0  ;
		dma_active_i_2ff	<=  1'b0  ;

    end
    else 
    begin  
        DMA_State           <=  DMA_State_nxt        ;
        DMA_Busy_o          <=  DMA_Busy_o_nxt       ;
        DMA_CMD_Phase       <=  DMA_CMD_Phase_nxt    ;
		DMA_Clr_o           <=  dma_clr_o_nxt       ;

		WBs_ADR_DMA_o       <=  WBs_ADR_DMA_o_nxt    ;
		WBs_CYC_DMA_o       <=  WBs_CYC_DMA_o_nxt    ;
        WBs_STB_DMA_o       <=  WBs_STB_DMA_o_nxt    ;
        WBs_WE_DMA_o        <=  WBs_WE_DMA_o_nxt     ;

       	i2c_trnfr_cnt    <=  i2c_trnfr_cnt_nxt;
		
		DMA_REQ_o			<=  dma_req_nxt  ; 
		DMA_DONE_o			<=  dma_done_nxt  ;
		
		dma_active_i_1ff	<= DMA_Active_i;
		dma_active_i_2ff	<= dma_active_i_1ff;

 	end
end  

always @(posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
    if (WBs_RST_i)
    begin
        DMA_I2C_NACK_o		<=  1'b0  ;
    end
    else 
    begin  
		if ((DMA_State == DMA_IDLE) & (DMA_Enable_i == 1'b1))
			DMA_I2C_NACK_o		<=  1'b0  ;
		else if ((DMA_State == DMA_WAIT_TIP_OFF) & (tip_i2c_i == 1'b0) & (~i2c_rd_en))
			DMA_I2C_NACK_o       <=  rx_ack_i | DMA_I2C_NACK_o ;
		else 
			DMA_I2C_NACK_o		<=  DMA_I2C_NACK_o ;
 	end
end 

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        i2c_rd_en           <=  1'b0  ;
    end
    else 
    begin  
		if (i2c_trnfr_cnt == 3'h3)
		   i2c_rd_en           <=  1'b1  ;
		else if (DMA_State == DMA_I2C_TR_Done)
		   i2c_rd_en           <=  1'b0  ;
 	end
end 
  
assign sen_reg_adr = SLV_REG_ADR_i[15:8];

assign stp_rd_cmd = (SEL_16BIT_i)? 8'h68: 8'h20;

always @(
         i2c_trnfr_cnt          or
		 DMA_CMD_Phase          or
		 SLV_REG_ADR_i          or
		 stp_rd_cmd				or
		 sen_reg_adr
		 )
 begin
    case({i2c_trnfr_cnt,DMA_CMD_Phase})
    4'b0000    : WBs_DAT_DMA_o <= { SLV_REG_ADR_i[6:0],1'b0};
    4'b0001    : WBs_DAT_DMA_o <= 8'h90;
    4'b0010    : WBs_DAT_DMA_o <= sen_reg_adr;
	4'b0011    : WBs_DAT_DMA_o <= 8'h10;
	4'b0100    : WBs_DAT_DMA_o <= { SLV_REG_ADR_i[6:0],1'b1};
	4'b0101    : WBs_DAT_DMA_o <= 8'h90;
	4'b1001    : WBs_DAT_DMA_o <= stp_rd_cmd;
	4'b1011    : WBs_DAT_DMA_o <= 8'h68;
	default    : WBs_DAT_DMA_o <= 8'h20;
	endcase
end

assign DMA_Active_o = dma_active_i_2ff;

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        sen_dat_byte11  <=  8'h0  ;
    end
    else 
    begin  
		if (WBs_ACK_i2c_i & (~DMA_CMD_Phase) & (i2c_trnfr_cnt == 3'b100))
		    sen_dat_byte11  <=  WBs_DAT_I2C_i;
		else
			sen_dat_byte11  <=  sen_dat_byte11;
 	end
end 

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        sen_dat_byte12  <=  8'h0  ;
    end
    else 
    begin  
		if (WBs_ACK_i2c_i & (~DMA_CMD_Phase) & (i2c_trnfr_cnt == 3'b101))
		    sen_dat_byte12  <=  WBs_DAT_I2C_i;
		else
			sen_dat_byte12  <=  sen_dat_byte12;
 	end
end 

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        sen_dat_byte13  <=  8'h0  ;
    end
    else 
    begin  
		if (DMA_State == DMA_I2C_TR_Done)
		    sen_dat_byte13  <=  WBs_DAT_I2C_i;
		else
			sen_dat_byte13  <=  sen_dat_byte13;
 	end
end 

assign I2C_SEN_DATA1_o = (SEL_16BIT_i)? {8'h00, sen_dat_byte11, sen_dat_byte13} :{sen_dat_byte11, sen_dat_byte12, sen_dat_byte13};


// Determine the target I2C Address for each I/O to the I2C Master
//
assign WBs_ADR_DMA_o_nxt     =  DMA_CMD_Phase ?  I2C_COMMAND_REG_ADR : I2C_TRANSMIT_REG_ADR;


// Define the DMA State machine
//
always @( DMA_State          	or
          DMA_Enable_i      	or
          DMA_CMD_Phase         or
          i2c_trnfr_cnt      	or
		  SEL_16BIT_i		    or
		  WBs_ACK_i2c_i        	or
          dma_active_i_2ff      or
          tip_i2c_i				or
		  i2c_rd_en
         )
begin
    case(DMA_State)
    DMA_IDLE:
	begin

		WBs_CYC_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_DMA_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle
		dma_clr_o_nxt	           <= 1'b0             ;
		DMA_CMD_Phase_nxt    	   <= 1'b0             ;  // 1st phase is data
		i2c_trnfr_cnt_nxt  		   <= 3'b000           ; 
		dma_req_nxt			       <= 1'b0             ;
		dma_done_nxt			   <= 1'b0             ;
		
		
		case(DMA_Enable_i)
		1'b0:    // No Activity
		begin
            DMA_State_nxt          <= DMA_IDLE          ;
		    DMA_Busy_o_nxt         <= 1'b0             ;
        end
		1'b1:    // Start at the Command Queue Processing
		begin
            DMA_State_nxt          <= DMA_EVAL          ;
		    DMA_Busy_o_nxt         <= 1'b1             ;
        end
        endcase

	end
	DMA_EVAL:
    begin
        case(DMA_Enable_i )
        1'b1:                                           
        begin
            DMA_State_nxt      	   <= DMA_WB_XFR          ;  
			DMA_Busy_o_nxt         <= 1'b1             ;
			DMA_CMD_Phase_nxt      <= DMA_CMD_Phase     		   ;
			WBs_CYC_DMA_o_nxt      <= 1'b1             ;
			WBs_STB_DMA_o_nxt      <= 1'b1             ;
			dma_clr_o_nxt	       <= 1'b0             ;
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt;
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0     ;
			case( {i2c_rd_en, DMA_CMD_Phase})
			2'b10:
				begin 
					WBs_WE_DMA_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Active
				end 
			default:
				begin 
					WBs_WE_DMA_o_nxt       <= 1'b1                   ; // Wishbone bus to I2C is Active
				end 
			endcase
        end
        default:
        begin
            DMA_State_nxt          <= DMA_IDLE          ;  // No more data to process
		    DMA_Busy_o_nxt         <= 1'b0             ;  // Command Queue is done with transfers
		    WBs_CYC_DMA_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_STB_DMA_o_nxt      <= 1'b0             ;  // Wishbone bus to I2C is Idle
		    WBs_WE_DMA_o_nxt       <= 1'b0             ;  // Wishbone bus to I2C is Idle
			dma_clr_o_nxt	       <= 1'b0             ;
            DMA_CMD_Phase_nxt      <= DMA_CMD_Phase     ;
            i2c_trnfr_cnt_nxt  	   <= 3'h0        ;  
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0     ;
        end
        endcase
    end
	DMA_I2C_TR_Done:
    begin
        DMA_State_nxt              <= SDMA_Start_st     ;
		DMA_Busy_o_nxt             <= 1'b1             ;  // Command Queue Busy with transfers
        DMA_CMD_Phase_nxt          <= 1'b0     ;  //  Data phase

		WBs_CYC_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_DMA_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle
		
		i2c_trnfr_cnt_nxt  		   <= 3'h0        ;
		dma_req_nxt			   	   <= 1'b1             ;
		dma_done_nxt		   	   <= 1'b0     ;
		dma_clr_o_nxt	           <= 1'b1             ;
	end
	DMA_WB_XFR:
    begin
        case( {WBs_ACK_i2c_i,  DMA_CMD_Phase} )
        2'b10: 
        begin
			case( {SEL_16BIT_i,i2c_trnfr_cnt})
			4'h6:
			begin 
				DMA_CMD_Phase_nxt  <= DMA_CMD_Phase          ;
				DMA_State_nxt      <= DMA_I2C_TR_Done                ;
			end 
			4'hd:
			begin 
				DMA_CMD_Phase_nxt  <= DMA_CMD_Phase          ;
				DMA_State_nxt      <= DMA_I2C_TR_Done                ;
			end 
			default:
			begin 
				DMA_CMD_Phase_nxt      <= ~DMA_CMD_Phase          ;
				DMA_State_nxt      <= DMA_EVAL                ;
			end 
			endcase
		
		    WBs_CYC_DMA_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_STB_DMA_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_WE_DMA_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Idle
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0     ;
			dma_clr_o_nxt	       <= 1'b0             ;
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt        ;
        end
        2'b11: 
        begin
	
			case( i2c_trnfr_cnt)
			3'h2:
			begin 
				DMA_CMD_Phase_nxt      <= DMA_CMD_Phase          ;
			end 
			default:
			begin 
				DMA_CMD_Phase_nxt      <= ~DMA_CMD_Phase          ;
			end 
			endcase

			DMA_State_nxt      <= DMA_WAIT_TIP_ON         ;
		    WBs_CYC_DMA_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_STB_DMA_o_nxt      <= 1'b0                   ; // Wishbone bus to I2C is Idle
		    WBs_WE_DMA_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Idle
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0     ;
			dma_clr_o_nxt	       <= 1'b0             ;
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt        ;
        end
        default:
        begin
            DMA_State_nxt          <= DMA_WB_XFR              ; // Wait for the Wishbone Acknowledge
            DMA_CMD_Phase_nxt      <= DMA_CMD_Phase           ; // Hold the current data phase
		    WBs_CYC_DMA_o_nxt      <= 1'b1                   ; // Wishbone bus to I2C is Active
		    WBs_STB_DMA_o_nxt      <= 1'b1                   ; // Wishbone bus to I2C is Active
		    			
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0     ;
			dma_clr_o_nxt	       <= 1'b0             ;
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt        ;
		
			case( {i2c_rd_en, DMA_CMD_Phase})
			2'b10:
			begin 
				WBs_WE_DMA_o_nxt       <= 1'b0                   ; // Wishbone bus to I2C is Active
			end 
			default:
			begin 
				WBs_WE_DMA_o_nxt       <= 1'b1                   ; // Wishbone bus to I2C is Active
			end 
			endcase
			
        end
        endcase

		DMA_Busy_o_nxt             <= 1'b1                   ; // DMA Busy with transfers
    end
	DMA_WAIT_TIP_ON:
    begin
        // Wait for the I2C Master to begin its I2C bus transfer
        //
        case( tip_i2c_i )
        1'b0: DMA_State_nxt        <= DMA_WAIT_TIP_ON   ;  // Wait for the I2C Master to start its I2C Bus transfers
        1'b1: DMA_State_nxt        <= DMA_WAIT_TIP_OFF  ;  // The I2C Master began its I2C Bus transfers
        endcase

        DMA_Busy_o_nxt             <= 1'b1             ;  // Command Queue Busy with transfers
        DMA_CMD_Phase_nxt          <= DMA_CMD_Phase     ;  // Hold Phase Selections

		WBs_CYC_DMA_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_STB_DMA_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_WE_DMA_o_nxt           <= 1'b0             ;  // Between Wishbone Transfers
		
		dma_req_nxt			   <= 1'b0             ;
		dma_done_nxt		   <= 1'b0     ;
		dma_clr_o_nxt	       <= 1'b0             ;
		i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt        ;


    end
	DMA_WAIT_TIP_OFF:
    begin
        // Wait for the I2C Master to begin its I2C bus transfer
        //
        case( {DMA_Enable_i, tip_i2c_i}  )
        2'b00: 
        begin
            DMA_State_nxt          <= DMA_IDLE          ;  // Processing complete
		    DMA_Busy_o_nxt         <= 1'b0             ;  // Command Queue is not Busy with transfers
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt;
        end
        2'b01: 
        begin
            DMA_State_nxt          <= DMA_WAIT_TIP_OFF  ;  // Wait for the current I2C Bus transfer to complete before ending CQ processing
		    DMA_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt;
        end
        2'b10: 
        begin
            DMA_State_nxt          <= DMA_EVAL          ;  // Look to the next transfer
		    DMA_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt + 1'b1;
        end
        2'b11: 
        begin
            DMA_State_nxt          <= DMA_WAIT_TIP_OFF  ;  // Wait for the current I2C Bus transfer to complete
		    DMA_Busy_o_nxt         <= 1'b1             ;  // Command Queue Busy with transfers
			i2c_trnfr_cnt_nxt  	   <= i2c_trnfr_cnt;
        end
        endcase

        DMA_CMD_Phase_nxt          <= DMA_CMD_Phase     ;  // Hold Phase Selections

		WBs_CYC_DMA_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_STB_DMA_o_nxt          <= 1'b0             ;  // Between Wishbone Transfers
		WBs_WE_DMA_o_nxt           <= 1'b0             ;  // Between Wishbone Transfers
		
		dma_req_nxt			   <= 1'b0             ;
		dma_done_nxt		   <= 1'b0     ;
		dma_clr_o_nxt	       <= 1'b0             ;
    end
	
	SDMA_Start_st:
	begin
		DMA_Busy_o_nxt         <= 1'b1             ;
		DMA_CMD_Phase_nxt      <= 1'b0     ;
		WBs_CYC_DMA_o_nxt      <= 1'b0             ;
		WBs_STB_DMA_o_nxt      <= 1'b0             ;
		WBs_WE_DMA_o_nxt       <= 1'b0             ;
		i2c_trnfr_cnt_nxt  	   <= 3'h0        ;
		dma_clr_o_nxt	       <= 1'b0             ;
		dma_done_nxt		   <= 1'b0             ;
				
		case( dma_active_i_2ff)
		1'h1:
		begin 
			dma_req_nxt			   <= 1'b0            ;
			DMA_State_nxt      <= SDMA_Done_st                ;
		end 
		default:
		begin 
			dma_req_nxt			   <= 1'b1            ;
			DMA_State_nxt      <= SDMA_Start_st                ;
		end 
		endcase
	end
		
	SDMA_Done_st:
	begin
		DMA_Busy_o_nxt         <= 1'b1             ;
		DMA_CMD_Phase_nxt      <= 1'b0     ;
		WBs_CYC_DMA_o_nxt      <= 1'b0             ;
		WBs_STB_DMA_o_nxt      <= 1'b0             ;
		WBs_WE_DMA_o_nxt       <= 1'b0             ;
		i2c_trnfr_cnt_nxt  	   <= 3'h0        ;
		dma_clr_o_nxt	       <= 1'b0             ;
		dma_req_nxt			   <= 1'b0            ;
				
		case( dma_active_i_2ff)
		1'h0:
		begin 
			dma_done_nxt	   <= 1'b1            ;
			DMA_State_nxt      <= DMA_IDLE                ;
		end 
		default:
		begin 
			dma_done_nxt	   <= 1'b0            ;
			DMA_State_nxt      <= SDMA_Done_st                ;
		end 
		endcase
	end
	
	default:
    begin
        DMA_State_nxt              <= DMA_IDLE          ;  // Waiting for the start of processing
		DMA_Busy_o_nxt             <= 1'b0             ;  // Command Queue is not busy with transfers
        DMA_CMD_Phase_nxt          <= 1'b0             ;  // 1st phase is data

		WBs_CYC_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_STB_DMA_o_nxt          <= 1'b0             ;  // Wishbone bus to I2C is Idle
		WBs_WE_DMA_o_nxt           <= 1'b0             ;  // Wishbone bus to I2C is Idle
		
		i2c_trnfr_cnt_nxt  	   <= 3'h0        ;
		dma_clr_o_nxt	       <= 1'b0             ;
		dma_req_nxt			   <= 1'b0            ;
		dma_done_nxt		   <= 1'b0     ;
  
    end
	endcase
end	


endmodule
