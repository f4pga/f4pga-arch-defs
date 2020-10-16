// -----------------------------------------------------------------------------
// title          : AL4S3B Fabric Intel VGA sample IP Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : Dma_Ctrl.v
// author         : Anand Wadke
// company        : QuickLogic Corp
// created        : 2017/11/25	
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: 
// -----------------------------------------------------------------------------
// copyright (c) 2018
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2017/11/25      1.0        Anand Wadke    Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps

module Dma_Ctrl ( 
            input  			clk_i	,
            input  			rst_i	,
			
			input           trig_i,
			
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
//reg     dma_active_i_3ff;

//wire    ASSP_done_sample_rst;

wire    dreq_reset;
assign  dreq_reset = rst_i | DMA_Active_i | dma_active_i_1ff | dma_active_i_2ff | ASSP_DMA_Done_i;


assign  DMA_REQ_o = dma_req ;

//always @(posedge clk_i or posedge rst_i or posedge DMA_Active_i) 
always @(posedge clk_i or posedge dreq_reset) 
begin
    //if (rst_i | DMA_Active_i)
    if (dreq_reset)
    begin
        dma_req           <=  1'b0 ;
    end
    else 
    begin 
		if (trig_i && ~dma_req)
			dma_req           <=  1'b1;
		else 
			dma_req           <=  dma_req;
 	end	
end	


always @(posedge clk_i or posedge rst_i) 
begin
    if (rst_i)
    begin
		dma_active_i_1ff	<=  1'b0;
		dma_active_i_2ff	<=  1'b0;
		//dma_active_i_3ff	<=  1'b0;
    end
    else 
    begin  
		dma_active_i_1ff	<= DMA_Active_i;
		dma_active_i_2ff	<= dma_active_i_1ff;
		//dma_active_i_3ff    <= dma_active_i_2ff;
 	end
end  

assign DMA_Clr_o   = ASSP_DMA_Done_i;
assign DMA_Done_o  = ASSP_DMA_Done_i;


endmodule