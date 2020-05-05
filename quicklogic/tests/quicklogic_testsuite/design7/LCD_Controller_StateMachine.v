// -----------------------------------------------------------------------------
// title          : LCD Controller State machine Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : LCD_Controller_StateMachine.v
// author         : Rakesh M
// company        : QuickLogic Corp
// created        : 2016/06/03	
// last update    : 2016/06/06
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: HRM DMA controller
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2016/06/06     1.0        Rakesh. M         created / Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module LCD_Controller_StateMachine (

						 CLK_4M_i,
						 RST_fb_i,
						
                         WBs_CLK_i,
                         WBs_RST_i,

                         LCD_TXFIFO_DAT_o,
                         LCD_TXFIFO_PUSH_o,
						 LCD_CQ_EN_o,
						 Tx_FIFO_Empty_i,
						 
						 LCD_CNTL_EN_i,
						 AUTO_PAN_EN_i,
						 //LCD_PAN_EN_i,
						 //LCD_PAN_RNL_i,
						 //LCD_Dp_Strt_Adr_i,
						 LCD_SLV_Adr_i,
                         LCD_CNTL_Busy_o,
						 LCD_Clr_o,
						 LCD_LD_Done_o,
			 
						 SRAM_RD_ADR_o,
						 SRAM_RD_DAT_i,
						 
						 DMA_REQ_o,
						 DMA_Active_i,

                         DMA_Enable_i,
						 DMA_Done_o,
                         DMA_Clr_o

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

output            [35:0] LCD_TXFIFO_DAT_o;
output                   LCD_TXFIFO_PUSH_o;
output 					 LCD_CQ_EN_o;

input                    LCD_CNTL_EN_i;
input					 AUTO_PAN_EN_i;
//input                    LCD_PAN_EN_i;
//input                    LCD_PAN_RNL_i;
//input			  [11:0] LCD_Dp_Strt_Adr_i;
input			  [6:0]	 LCD_SLV_Adr_i;
output                   LCD_CNTL_Busy_o;
output                   LCD_Clr_o;
output                   LCD_LD_Done_o;

output            [11:0] SRAM_RD_ADR_o;
input             [7:0]  SRAM_RD_DAT_i;

output                   DMA_REQ_o;
input                    DMA_Active_i;

output                   DMA_Clr_o;
output                   DMA_Done_o;
input                    DMA_Enable_i;

input 					 Tx_FIFO_Empty_i;

input 					 CLK_4M_i; 
input 					 RST_fb_i;


wire                     WBs_CLK_i;
wire                     WBs_RST_i;

reg 					 DMA_REQ_o;
wire                     DMA_Enable_i;
wire 					 DMA_Done_o;
wire	             	 DMA_Clr_o;

reg            			 dma_active_i_1ff;
reg            			 dma_active_i_2ff;
reg            			 dma_active_i_3ff;

wire					 LCD_Enable;

reg                      LCD_CNTL_Busy_o;
reg                      LCD_CNTL_Busy_o_nxt; 

reg                      frm_cnt_strt;
reg                      frm_cnt_strt_nxt;

reg            [10:0]  	 i2c_trnfr_cnt;
reg            [10:0]  	 i2c_trnfr_cnt_nxt;

reg                      start_phase; 
reg                      stop_phase; 
reg                      fifo_push_dat;

reg                      start_phase_nxt; 
reg                      stop_phase_nxt; 
reg                      fifo_push_dat_nxt;

reg                      UP_DAT_Phase;
reg                      UP_DAT_Phase_nxt;

reg            [11:0] 	 SRAM_RD_ADR_o;

reg            [7:0]    dat_byte_l;

reg            [35:0] LCD_TXFIFO_DAT_o;

reg		   [10:0] lcd_dp_strt_adr;

reg            [2:0]    fr_cnt;


reg            [18:0]   frt_tim_cnt;
reg               frt_done;

//reg               frt_done_r;
//reg               frt_done_r1;

//reg               idle_st_r;
//reg               idle_st_r1;

reg 			lcd_load_done_nxt;
reg				LCD_LD_Done_o;


//------Define Parameters---------
//

//
// Define the Command Queue Statemachine States
//
// Note: These states are chosen to allow for overlap of various signals
//       during operation. This overlap should help reduce timing
//       dependancies.
//

parameter LCD_IDLE              = 3'h0;
parameter LCD_START             = 3'h1;
//parameter LCD_START_Done        = 3'h2;
parameter LCD_EVAL              = 3'h2;
parameter LCD_DAT_TRNFER        = 3'h3;
parameter LCD_DAT_TRNFER_Done   = 3'h4;
parameter LCD_STOP              = 3'h5;
parameter LCD_STOP_Done         = 3'h6;
parameter LCD_FRT_Done          = 3'h7;

parameter I2C_COMMAND_REG_ADR  = 3'h4;
parameter I2C_TRANSMIT_REG_ADR = 3'h3;

parameter DMA_SRAM_WR_ADR1  = 8'h0;
parameter DMA_SRAM_WR_ADR2  = 8'h1;



parameter STRT_WR_CMD  = 8'h90;
parameter CNT_WR_CMD   = 8'h10;
parameter STOP_CMD     = 8'h40;

parameter SRAM_END_ADR   = 12'h840;

//-----Internal Signals--------------------
//


//
// Define the Statemachine registers
//
reg               [2:0]  LCD_State            ;
reg               [2:0]  LCD_State_nxt        ;


//------Logic Operations----------
//
assign LCD_TXFIFO_PUSH_o = fifo_push_dat;
assign LCD_CQ_EN_o = LCD_CNTL_Busy_o;
//assign LCD_LD_Done_o = ((LCD_State == LCD_STOP_Done) & ((fr_cnt== 3'h4) | (~AUTO_PAN_EN_i)));
//assign LCD_Clr_o = (LCD_State == LCD_STOP);
assign LCD_Clr_o = ((LCD_State == LCD_STOP_Done) & ((fr_cnt== 3'h4) | (~AUTO_PAN_EN_i)));

// DMA Section: 

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        DMA_REQ_o           <=  1'b0 ;
    end
    else 
    begin  
		if (DMA_Enable_i && LCD_State == LCD_IDLE)
			DMA_REQ_o           <=  1'b1;
		else if (dma_active_i_3ff)
			DMA_REQ_o           <=  1'b0;
		else 
			DMA_REQ_o           <=  DMA_REQ_o;
 	end
end  

assign DMA_Clr_o  = ~dma_active_i_3ff & dma_active_i_2ff;
assign DMA_Done_o =  dma_active_i_3ff & ~dma_active_i_2ff;

//syncing to CLK_4M_i domain
/*
always @(posedge CLK_4M_i or posedge RST_fb_i) 
begin
    if (RST_fb_i)
    begin
        idle_st_r         <=  1'b1 ;
		idle_st_r1        <=  1'b1 ;
    end
    else 
    begin  
		idle_st_r         <=  ~frm_cnt_strt;
		idle_st_r1        <=  idle_st_r ;
 	end
end 
*/
//frame refresh timer count
/*
always @(posedge CLK_4M_i or posedge RST_fb_i) 
begin
    if (RST_fb_i)
    begin
        frt_tim_cnt    <=  19'h0 ;
    end
    else 
    begin  
		if (idle_st_r1)
			frt_tim_cnt    <=  19'h0 ;
		else 
			frt_tim_cnt  <=  frt_tim_cnt + 1'b1;
 	end
end 
*/
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        frt_tim_cnt    <=  19'h0 ;
    end
    else 
    begin  
		if (frm_cnt_strt == 1'b0)
			frt_tim_cnt    <=  19'h0 ;
		else 
			frt_tim_cnt  <=  frt_tim_cnt + 1'b1;
 	end
end 

/*
always @(posedge CLK_4M_i or posedge RST_fb_i) 
begin
    if (RST_fb_i)
    begin
        frt_done         <=  1'b0 ;
    end
    else 
    begin  
		if (idle_st_r1)
			frt_done    <=  1'b0 ;
		else if (frt_tim_cnt[18:12] == 7'h41)
			frt_done  	<=  1'b1 ;
		else 
			frt_done  <=  frt_done;
 	end
end 
*/
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        frt_done         <=  1'b0 ;
    end
    else 
    begin  
		if (frm_cnt_strt == 1'b0)
			frt_done    <=  1'b0 ;
		else if (frt_tim_cnt[18:12] == 7'h63)
			frt_done  	<=  1'b1 ;
		else 
			frt_done  <=  frt_done;
 	end
end 

//syncing to WBs_CLK_i domain
/*
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        frt_done_r         <=  1'b0 ;
		frt_done_r1        <=  1'b0 ;
    end
    else 
    begin  
		frt_done_r         <=  frt_done ;
		frt_done_r1        <=  frt_done_r ;
 	end
end 
*/

// Frame Count
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        fr_cnt           <=  3'h0 ;
    end
    else 
    begin  
		if ( fr_cnt == 3'h5 || ~AUTO_PAN_EN_i)
			fr_cnt  <=  3'h0 ;
		else if (LCD_State == LCD_STOP_Done)
			fr_cnt  <=  fr_cnt + 1'b1;
		else 
			fr_cnt  <=  fr_cnt;
 	end
end 

//SRAM Jump Address
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        lcd_dp_strt_adr           <=  11'h0 ;
    end
    else 
    begin  
        case(fr_cnt)
		3'b001:
		begin
			lcd_dp_strt_adr    <= 11'h1e0; 
		end
		3'b010:
		begin
			lcd_dp_strt_adr    <= 11'h300;  
		end
		3'b011:
		begin
			lcd_dp_strt_adr    <= 11'h3c0;  
		end
		3'b100:
		begin
			lcd_dp_strt_adr    <= 11'h420;  
		end
		default:
		begin
			lcd_dp_strt_adr    <=  11'h0 ; 
		end
        endcase
 	end
end  

// SRAM RD Address generation 
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        SRAM_RD_ADR_o           <=  12'h0 ;
    end
    else 
    begin  
		if (LCD_CNTL_EN_i && LCD_State == LCD_IDLE)
			SRAM_RD_ADR_o  <=  {1'b0,lcd_dp_strt_adr};
		else if (LCD_State == LCD_DAT_TRNFER_Done)
			SRAM_RD_ADR_o  <=  SRAM_RD_ADR_o + 1'b1;
		else 
			SRAM_RD_ADR_o  <=  SRAM_RD_ADR_o;
 	end
end  

//
always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        LCD_State           <= LCD_IDLE;
        LCD_CNTL_Busy_o     <=  1'b0;
        UP_DAT_Phase        <=  1'b0;
		start_phase         <=  1'b0;
        stop_phase          <=  1'b0;
        fifo_push_dat       <=  1'b0;
		i2c_trnfr_cnt		<=  12'h0;
		dma_active_i_1ff	<=  1'b0;
		dma_active_i_2ff	<=  1'b0;
		dma_active_i_3ff	<=  1'b0;
		frm_cnt_strt	    <= 1'b0;
		LCD_LD_Done_o 		<= 1'b0;
    end
    else 
    begin  
        LCD_State           <=  LCD_State_nxt;
        LCD_CNTL_Busy_o     <=  LCD_CNTL_Busy_o_nxt;
        UP_DAT_Phase       	<=  UP_DAT_Phase_nxt;
		start_phase       	<=  start_phase_nxt; 
        stop_phase        	<=  stop_phase_nxt;
        fifo_push_dat     	<=  fifo_push_dat_nxt;
       	i2c_trnfr_cnt    	<=  i2c_trnfr_cnt_nxt;
		dma_active_i_1ff	<= DMA_Active_i;
		dma_active_i_2ff	<= dma_active_i_1ff;
		dma_active_i_3ff    <= dma_active_i_2ff;
		frm_cnt_strt	    <= frm_cnt_strt_nxt;
		LCD_LD_Done_o 		<= lcd_load_done_nxt;
 	end
end  
 
always @(
         dat_byte_l          or
		 SRAM_RD_DAT_i       or
		 start_phase         or
		 stop_phase     	 or
		 LCD_SLV_Adr_i
		 )
 begin
    case({stop_phase,start_phase})
    2'b01    : LCD_TXFIFO_DAT_o <= {4'hF,8'h10,8'h40,8'h90,LCD_SLV_Adr_i,1'b0};
    2'b10    : LCD_TXFIFO_DAT_o <= {4'hF,8'h50,SRAM_RD_DAT_i,8'h10,dat_byte_l};
	default  : LCD_TXFIFO_DAT_o <= {4'hF,8'h10,SRAM_RD_DAT_i,8'h10,dat_byte_l};
	endcase
end

always @(posedge WBs_CLK_i or posedge WBs_RST_i) 
begin
    if (WBs_RST_i)
    begin
        dat_byte_l  <=  8'h0  ;
    end
    else 
    begin  
		if (LCD_State == LCD_DAT_TRNFER_Done && (~UP_DAT_Phase))
		    dat_byte_l  <=  SRAM_RD_DAT_i;
		else
			dat_byte_l  <=  dat_byte_l;
 	  end
end 

assign LCD_Enable = ~DMA_Enable_i & LCD_CNTL_EN_i;

// Define the LCD State machine
//
always @( LCD_State          or
          LCD_Enable         or
          UP_DAT_Phase       or
          Tx_FIFO_Empty_i    or
          i2c_trnfr_cnt      or
		  UP_DAT_Phase       or
		  //frt_done_r1        or
		  frt_done	         or
		  fr_cnt			 or
		  stop_phase
         )
begin
    case(LCD_State)
    LCD_IDLE:
	begin

		UP_DAT_Phase_nxt    	   <= 1'b0;  
		i2c_trnfr_cnt_nxt  		   <= 12'h0; 
		stop_phase_nxt    	       <= 1'b0; 
		fifo_push_dat_nxt    	   <= 1'b0; 
		frm_cnt_strt_nxt    	   <= 1'b0;
		lcd_load_done_nxt   <= 1'b0;
		
		case(LCD_Enable)
		1'b0:    // No Activity
		begin
            LCD_State_nxt          <= LCD_IDLE;
		    LCD_CNTL_Busy_o_nxt    <= 1'b0;
			start_phase_nxt        <= 1'b0; 
        end
		1'b1:    // Start the LCD image loading
		begin
            LCD_State_nxt          <= LCD_START;
		    LCD_CNTL_Busy_o_nxt    <= 1'b1;
			start_phase_nxt        <= 1'b1;
        end
        endcase

	end
	LCD_START:
    begin
        case(Tx_FIFO_Empty_i)
        1'b1:                                           
        begin
            LCD_State_nxt      	<= LCD_EVAL ;  
			LCD_CNTL_Busy_o_nxt <= 1'b1;
			UP_DAT_Phase_nxt    <= UP_DAT_Phase;
			i2c_trnfr_cnt_nxt  	<= 12'h0;
			start_phase_nxt     <= 1'b1;   
			stop_phase_nxt      <= 1'b0; 
			fifo_push_dat_nxt   <= 1'b1; 
			frm_cnt_strt_nxt    <= 1'b0;
			lcd_load_done_nxt   <= 1'b0;
		end
        default:
        begin
            LCD_State_nxt      	<= LCD_START ;  
			LCD_CNTL_Busy_o_nxt <= 1'b1;
			UP_DAT_Phase_nxt   <= UP_DAT_Phase;
			i2c_trnfr_cnt_nxt  	<= 12'h0;
			start_phase_nxt     <= 1'b1;   
			stop_phase_nxt      <= 1'b0; 
			fifo_push_dat_nxt   <= 1'b0; 
			frm_cnt_strt_nxt    <= 1'b0;
			lcd_load_done_nxt   <= 1'b0;
        end
        endcase
    end
/*	
	LCD_START_Done:
    begin
            LCD_State_nxt      	<= LCD_EVAL ;  
			LCD_CNTL_Busy_o_nxt <= 1'b1;
			UP_DAT_Phase_nxt   <= UP_DAT_Phase;
			i2c_trnfr_cnt_nxt  	<= 12'h0;
			start_phase_nxt     <= 1'b0;   
			stop_phase_nxt      <= 1'b0; 
			fifo_push_dat_nxt   <= 1'b0; 
	end
*/
	LCD_EVAL:
    begin
        case( i2c_trnfr_cnt)
        12'h420: 
        begin
            LCD_State_nxt      	<= LCD_STOP ;  
			LCD_CNTL_Busy_o_nxt <= 1'b1;
			UP_DAT_Phase_nxt   <= UP_DAT_Phase;
			i2c_trnfr_cnt_nxt  	<= i2c_trnfr_cnt;
			start_phase_nxt     <= 1'b0;   
			stop_phase_nxt      <= stop_phase; 
			fifo_push_dat_nxt   <= 1'b0;
			frm_cnt_strt_nxt    <= 1'b1;
			lcd_load_done_nxt   <= 1'b0;
        end
       default:
        begin
            LCD_State_nxt      	<= LCD_DAT_TRNFER;  
			LCD_CNTL_Busy_o_nxt <= 1'b1;
			UP_DAT_Phase_nxt   <= UP_DAT_Phase;
			i2c_trnfr_cnt_nxt  	<= i2c_trnfr_cnt;
			start_phase_nxt     <= 1'b0;   
			stop_phase_nxt      <= stop_phase; 
			fifo_push_dat_nxt   <= 1'b0; 
			frm_cnt_strt_nxt    <= 1'b1;
			lcd_load_done_nxt   <= 1'b0;
        end
        endcase
    end
	LCD_DAT_TRNFER:
    begin
        case( {Tx_FIFO_Empty_i, UP_DAT_Phase} )
		2'b00:
		begin
			fifo_push_dat_nxt    <= 1'b0; 
            LCD_State_nxt        <= LCD_DAT_TRNFER; 
		end
		2'b01:
		begin
			fifo_push_dat_nxt    <= 1'b0; 
            LCD_State_nxt        <= LCD_DAT_TRNFER; 
		end
		2'b10:
		begin
			fifo_push_dat_nxt    <= 1'b0; 
            LCD_State_nxt        <= LCD_DAT_TRNFER_Done; 
		end
		2'b11:
		begin
			fifo_push_dat_nxt    <= 1'b1; 
            LCD_State_nxt        <= LCD_DAT_TRNFER_Done; 
		end
        endcase
		frm_cnt_strt_nxt    <= 1'b1;
		LCD_CNTL_Busy_o_nxt <= 1'b1;
		UP_DAT_Phase_nxt    <= UP_DAT_Phase;
		i2c_trnfr_cnt_nxt  	<= i2c_trnfr_cnt;
		start_phase_nxt     <= 1'b0;   
		lcd_load_done_nxt   <= 1'b0;
		case( i2c_trnfr_cnt)
        12'h41E: 
        begin
			stop_phase_nxt      <= 1'b1; 
        end
        default:
        begin
			stop_phase_nxt      <= stop_phase; 
        end
        endcase
    end
	LCD_DAT_TRNFER_Done:
    begin
        LCD_State_nxt      	<= LCD_EVAL;  
		LCD_CNTL_Busy_o_nxt <= 1'b1;
		UP_DAT_Phase_nxt    <= ~UP_DAT_Phase;
		i2c_trnfr_cnt_nxt  	<= i2c_trnfr_cnt + 1'b1;
		start_phase_nxt     <= 1'b0;   
		stop_phase_nxt      <= stop_phase; 
		fifo_push_dat_nxt   <= 1'b0;
		frm_cnt_strt_nxt    <= 1'b1;
		lcd_load_done_nxt   <= 1'b0;
    end
	LCD_STOP:
	begin
        LCD_CNTL_Busy_o_nxt <= 1'b1;
		UP_DAT_Phase_nxt    <= 1'b0;
		i2c_trnfr_cnt_nxt  	<= 12'h0;
		start_phase_nxt     <= 1'b0;   
		stop_phase_nxt      <= 1'b1; 
		fifo_push_dat_nxt   <= 1'b0;
		frm_cnt_strt_nxt    <= 1'b1;
		lcd_load_done_nxt   <= 1'b0;
		case( Tx_FIFO_Empty_i)
		1'h1:
		begin 
			LCD_State_nxt     <= LCD_STOP_Done;
		end 
		default:
		begin 
			LCD_State_nxt     <= LCD_STOP;
		end 
		endcase
	end
	LCD_STOP_Done: 
	begin
        LCD_State_nxt      	<= LCD_FRT_Done;  
		LCD_CNTL_Busy_o_nxt <= 1'b1;
		UP_DAT_Phase_nxt    <= 1'b0; 
		i2c_trnfr_cnt_nxt  	<= 12'h0;
		start_phase_nxt     <= 1'b0;   
		stop_phase_nxt      <= 1'b0; 
		fifo_push_dat_nxt   <= 1'b0;
		frm_cnt_strt_nxt    <= 1'b1;
		lcd_load_done_nxt   <= 1'b0;
	end
	LCD_FRT_Done: 
	begin
		//case(frt_done_r1)
		case(frt_done)
		1'b1:    
		begin
            LCD_State_nxt          <= LCD_IDLE;
		    LCD_CNTL_Busy_o_nxt    <= 1'b0;
			frm_cnt_strt_nxt    <= 1'b0;
			case(fr_cnt)
            3'h0: 
			begin
				lcd_load_done_nxt      <= 1'b1; 
			end
			default:
			begin
				lcd_load_done_nxt      <= 1'b0;
			end
			endcase
        end
		1'b0:    
		begin
            LCD_State_nxt          <= LCD_FRT_Done;
		    LCD_CNTL_Busy_o_nxt    <= 1'b1;
			frm_cnt_strt_nxt       <= 1'b1;
			lcd_load_done_nxt      <= 1'b0;
        end
        endcase
		UP_DAT_Phase_nxt    <= 1'b0; 
		i2c_trnfr_cnt_nxt  	<= 12'h0;
		start_phase_nxt     <= 1'b0;   
		stop_phase_nxt      <= 1'b0; 
		fifo_push_dat_nxt   <= 1'b0;
	end
	default:
    begin
        LCD_State_nxt      	<= LCD_IDLE;  
		LCD_CNTL_Busy_o_nxt <= 1'b0;
		UP_DAT_Phase_nxt    <= 1'b0; 
		i2c_trnfr_cnt_nxt  	<= 12'h0;
		start_phase_nxt     <= 1'b0;   
		stop_phase_nxt      <= 1'b0; 
		fifo_push_dat_nxt   <= 1'b0;  
		frm_cnt_strt_nxt    <= 1'b0;
		lcd_load_done_nxt   <= 1'b0;
    end
	endcase
end	

endmodule
