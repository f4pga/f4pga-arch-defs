// -----------------------------------------------------------------------------
// title          : AL4S3B Fabric In VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : vga_rx_dma_ctrl.v
// author         : Anand Wadke
// company        : QuickLogic Corp
// created        : 2017/11/08	
// last update    : 2017/11/08
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: 
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2017/11/08      1.0        Anand Wadke    Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps
`define NOT_EMPTY_ASSP_CTRL_TRIG

module vga_rx_dma_ctrl ( 
            input  			clk_i	,
            input  			rst_i	,
			
			input           Rx_FIFO_Full_i,
			input           Rx_FIFO_Empty_i,
			//input    [10:0] Rx_FIFO_DAT_CNT_i,
			input           thresh_line_cnt_reached_i,
			
            input  			DMA_Active_i	,
			input           ASSP_DMA_Done_i,
            output 			DMA_Done_o	,
			output          DMA_Clr_o,
            input  			DMA_Enable_i	,
			output 			DMA_REQ_o  	 				
	

			);

reg     dma_req;  
reg     dma_active_i_1ff;
reg     dma_active_i_2ff;
reg     dma_active_i_3ff;

wire    ASSP_done_sample_rst;


assign  DMA_REQ_o = dma_req;

`ifdef NOT_EMPTY_ASSP_CTRL_TRIG
wire dma_reset;
assign dma_reset = rst_i | DMA_Active_i;
always @(posedge clk_i or posedge dma_reset) 
begin
    if (dma_reset)
    begin
        dma_req           <=  1'b0 ;
    end
    else 
    begin 
		if (DMA_Enable_i && ~Rx_FIFO_Empty_i && ~dma_req)
			dma_req           <=  1'b1;
		else 
			dma_req           <=  dma_req;
 	end	
end	

`else
always @(posedge clk_i or posedge rst_i) 
begin
    if (rst_i)
    begin
        dma_req           <=  1'b0 ;
    end
    else 
    begin  
		//if (DMA_Enable_i && (Rx_FIFO_Empty_i==1'b1|| Rx_FIFO_h_Empty_i==1'b1 ))
		if (DMA_Enable_i && (thresh_line_cnt_reached_i==1'b1))
			dma_req           <=  1'b1;
		else if (dma_active_i_3ff)
			dma_req           <=  1'b0;
		else 
			dma_req           <=  dma_req;
 	end
end 
`endif

always @(posedge clk_i or posedge rst_i) 
begin
    if (rst_i)
    begin
		dma_active_i_1ff	<=  1'b0;
		dma_active_i_2ff	<=  1'b0;
		dma_active_i_3ff	<=  1'b0;
    end
    else 
    begin  
		dma_active_i_1ff	<= DMA_Active_i;
		dma_active_i_2ff	<= dma_active_i_1ff;
		dma_active_i_3ff    <= dma_active_i_2ff;
 	end
end  

`ifdef NOT_EMPTY_ASSP_CTRL_TRIG
assign DMA_Clr_o   = ASSP_DMA_Done_i;
assign DMA_Done_o  = ASSP_DMA_Done_i;
`else
assign DMA_Clr_o  = ~dma_active_i_3ff & dma_active_i_2ff;
assign DMA_Done_o =  dma_active_i_3ff & ~dma_active_i_2ff;
`endif





endmodule