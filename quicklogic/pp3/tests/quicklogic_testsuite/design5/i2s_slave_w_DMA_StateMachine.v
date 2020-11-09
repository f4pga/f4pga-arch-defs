// -----------------------------------------------------------------------------
// title          : I2S Slave DMA Controler State machine Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_w_DMA_StateMachine.v
// author         : Anand Wadke
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2018/05/21
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: I2S Slave DMA controller
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author                        description
// 2017/03/23      1.0        Rakesh Moolacheri        created / Initial Release
// 2018/01/18      1.1        Anand A Wadke            Modiifed for Decimator-AEC 20
// 2018/05/21      1.2        Anand A Wadke            Modiifed for f processing.
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module i2s_slave_w_DMA_StateMachine (
       
                         WBs_CLK_i,
                         WBs_RST_i,

						 DMA_Clr_o,
						 
						 DMA_REQ_o,
						 DMA_DONE_o,
						 DMA_Active_i,
						 DMA_Active_o,

                         LR_RXFIFO_Pop_i,
						 
						 DMA_CNT_i,
						 I2S_S_EN_i,

                         DMA_Start_i,
						 dma_cntr_o,
						 dma_st_o,
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

input                    DMA_Start_i;
output                   DMA_Busy_o;

output    				 DMA_Clr_o;

output					 DMA_REQ_o; 
output					 DMA_DONE_o;
input				     DMA_Active_i;
output				     DMA_Active_o;

input                    LR_RXFIFO_Pop_i;

input          [8:0]     DMA_CNT_i;

output         [8:0]     dma_cntr_o;

output         [1:0]     dma_st_o;

input                    I2S_S_EN_i;

wire                     WBs_CLK_i;
wire                     WBs_RST_i;

wire                     DMA_Start_i;
wire                     LR_RXFIFO_Pop_i;

reg                      DMA_Busy_o;
reg                      DMA_Busy_o_nxt;

reg 					 DMA_REQ_o;
reg						 dma_req_nxt;

reg 					 DMA_DONE_o;
reg 					 dma_done_nxt;

reg            			 DMA_Clr_o;
reg             		 dma_clr_o_nxt;

reg            			 dma_active_i_1ff;
reg            			 dma_active_i_2ff;
wire  					 DMA_Active_o;
wire  					 DMA_Active_i;

reg            [8:0]     dma_cntr;

wire           [8:0]     DMA_CNT_i;

wire           [1:0]     dma_st_o;

//wire					 rst;

wire                     I2S_S_EN_i;

//------Define Parameters---------
//

//
// Define the Command Queue Statemachine States
//
// Note: These states are chosen to allow for overlap of various signals
//       during operation. This overlap should help reduce timing
//       dependancies.
//
parameter DMA_IDLE              = 2'h0;
parameter DMA_START             = 2'h1;
parameter DMA_XFR_PRGSS         = 2'h2;
parameter DMA_DONE              = 2'h3;


//-----Internal Signals--------------------
//
// Define the Statemachine registers
//
reg               [1:0]  DMA_State            ;
reg               [1:0]  DMA_State_nxt        ;



//------Logic Operations----------
//
assign DMA_Active_o = dma_active_i_2ff;

assign dma_cntr_o = dma_cntr;

assign dma_st_o = DMA_State;

//assign rst = WBs_RST_i | ~I2S_S_EN_i;

// Define the registers associated with the Command Queue Statemachine
//
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        DMA_State           <= DMA_IDLE;
        DMA_Busy_o          <=  1'b0  ;
		DMA_Clr_o	        <=  1'b0  ;
		DMA_REQ_o			<=  1'b0  ;
		DMA_DONE_o			<=  1'b0  ;
		
		dma_active_i_1ff	<=  1'b0  ;
		dma_active_i_2ff	<=  1'b0  ;

    end
	else if (~I2S_S_EN_i)
	begin
        DMA_State           <= DMA_IDLE;
        DMA_Busy_o          <=  1'b0  ;
		DMA_Clr_o	        <=  1'b0  ;
		DMA_REQ_o			<=  1'b0  ;
		DMA_DONE_o			<=  1'b0  ;
		
		dma_active_i_1ff	<=  1'b0  ;
		dma_active_i_2ff	<=  1'b0  ;
	
	end
    else 
    begin  
        DMA_State           <=  DMA_State_nxt        ;
        DMA_Busy_o          <=  DMA_Busy_o_nxt       ;
		DMA_Clr_o           <=  dma_clr_o_nxt       ;
		
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
        dma_cntr		<=  9'h0  ;
    end
    else 
    begin  
		if (DMA_State == DMA_IDLE)
			dma_cntr	<=  9'h0  ;
		else if (LR_RXFIFO_Pop_i)
			dma_cntr    <=  dma_cntr + 1;
		else 
			dma_cntr	<=  dma_cntr;
 	end
end 

// Define the DMA State machine
//
always @( DMA_State          	or
          DMA_Start_i         	or
          dma_active_i_2ff      or
		  dma_cntr              or
		  DMA_CNT_i
         )
begin
    case(DMA_State)
    DMA_IDLE:
	begin
		dma_clr_o_nxt	           <= 1'b0             ;
		dma_done_nxt			   <= 1'b0             ;
	
		case(DMA_Start_i)
		1'b0:    // No Activity
		begin
            DMA_State_nxt          <= DMA_IDLE         ;
		    DMA_Busy_o_nxt         <= 1'b0             ;
			dma_req_nxt			   <= 1'b0             ;
        end
		1'b1:    // Start at the Command Queue Processing
		begin
            DMA_State_nxt          <= DMA_START         ;
		    DMA_Busy_o_nxt         <= 1'b1             ;
			dma_req_nxt			   <= 1'b1             ;
        end
        endcase

	end
	DMA_START:
    begin
        case(DMA_Start_i )
        1'b1:                                           
        begin
			dma_done_nxt		   <= 1'b0     ;
			DMA_Busy_o_nxt         <= 1'b1             ;
			case( dma_active_i_2ff)
			1'b1:
				begin 
				    dma_req_nxt			   <= 1'b0              ;
					dma_clr_o_nxt	       <= 1'b1              ;
					DMA_State_nxt          <= DMA_XFR_PRGSS     ;					
				end 
			default:
				begin 
				    dma_req_nxt			   <= 1'b1              ;
					dma_clr_o_nxt	       <= 1'b0              ;
					DMA_State_nxt          <= DMA_START         ;
				end 
			endcase
        end
        default:
        begin
            DMA_State_nxt          <= DMA_IDLE         ;  
		    DMA_Busy_o_nxt         <= 1'b0             ;   
			dma_req_nxt			   <= 1'b0             ;
			dma_done_nxt		   <= 1'b0             ;
			dma_clr_o_nxt	       <= 1'b0             ;
        end
        endcase
    end
	DMA_XFR_PRGSS:
    begin
        DMA_Busy_o_nxt             <= 1'b1             ;  
		dma_req_nxt			   	   <= 1'b0             ;
		dma_clr_o_nxt	           <= 1'b0             ;
		
		case(dma_cntr)
			DMA_CNT_i:
						begin 
							DMA_State_nxt      <= DMA_DONE         ;
							dma_done_nxt	   <= 1'b1             ;
						end 
			default:
						begin 
							DMA_State_nxt      <= DMA_XFR_PRGSS    ;
							dma_done_nxt	   <= 1'b0             ;
						end 
			endcase
	end
		
	DMA_DONE:
	begin
		DMA_Busy_o_nxt         <= 1'b0             ;
		dma_clr_o_nxt	       <= 1'b0             ;
		dma_req_nxt			   <= 1'b0             ;
		dma_done_nxt	       <= 1'b0             ;
		DMA_State_nxt          <= DMA_IDLE         ;
	end
	
	default:
    begin
        DMA_Busy_o_nxt             <= 1'b0         ;  
		dma_clr_o_nxt	       	   <= 1'b0         ;
		dma_req_nxt			       <= 1'b0         ;
		dma_done_nxt	           <= 1'b0         ;
        DMA_State_nxt              <= DMA_IDLE     ;
    end
	endcase
end	

endmodule
