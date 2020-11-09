// -----------------------------------------------------------------------------
// title          : I2C Slave Rx FIFOs (Left & Right) Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_RxRAMs.v
// author         : Anand Wadke
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Right Rx FIFO and Left Rx FiFO for receiving the right & Left
//              channel I2S data
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version      author                description
// 2018/05/19      1.0        Anand Wadke           I2S Pre Rx RAMs
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module i2s_slave_RxRAMs( 

						 i2s_clk_i,
						 
                         WBs_CLK_i,
                         WBs_RST_i,
						 
						 RAM_logic_rst_i,
						 
						 f_start_o,

                         L_I2SRx_Pref_RXRAM_DAT_i,
						 L_I2SRx_Pref_RXRAM_WR_i, 
						 
						 L_f_RAM_RaDDR_i,
						 L_f_RAM_WaDDR_i,
						 L_f_RAM_Wr_en_i,
						 L_f_RAM_WR_DATA_i,
						 L_f_RAM_RD_DATA_o,
					 
						//From Wishbone
						 wb_L_f_RAM_aDDR_i,
						 wb_L_f_RAM_Wen_i,	
						 wb_L_f_RAM_wr_rd_Mast_sel_i,
						 wb_L_f_Real_RAM_Data_o
						 

                         );


//------Port Parameters----------------
//------Port Signals-------------------
//
// Fabric Global Signals
//
input                    i2s_clk_i;

input                    WBs_CLK_i;         // Wishbone Fabric Clock
input                    WBs_RST_i;         // Wishbone Fabric Reset
input                    RAM_logic_rst_i;  

output                   f_start_o;
       
input            [15:0]  L_I2SRx_Pref_RXRAM_DAT_i;
input                    L_I2SRx_Pref_RXRAM_WR_i;

input 	[9:0]  			L_f_RAM_RaDDR_i;
input 	[9:0]  			L_f_RAM_WaDDR_i;
input                   L_f_RAM_Wr_en_i;
input 	[15:0]  		L_f_RAM_WR_DATA_i;
output 	[15:0]  		L_f_RAM_RD_DATA_o;

//From Wishbone --> I2s register interface
input   [9:0]			wb_L_f_RAM_aDDR_i;
input 					wb_L_f_RAM_Wen_i;
input 					wb_L_f_RAM_wr_rd_Mast_sel_i;
output [15:0]           wb_L_f_Real_RAM_Data_o;  

//Internal Signals
wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     RAM_logic_rst_i;         // Wishbone Fabric Reset

// Tx FIFO Signals
//
wire [15:0]  			L_I2SRx_Pref_RXRAM_DAT_i;
wire                    L_I2SRx_Pref_RXRAM_WR_i;
//reg  [9:0]  			I2S_FIR_DATA_WaDDR_sig;
reg  [10:0]  			I2S_FIR_DATA_WaDDR_sig;
wire  [9:0]  			I2S_FIR_DATA_WaDDR_sig_br;
reg 					I2S_wMEM_WE_sig;

//wire [9:0]  		    I2SData_ADDR_mux_sig;
wire [10:0]  		    I2SData_ADDR_mux_sig;
wire [15:0] 		    I2SData_DATA_mux_sig;
wire   		            I2SData_wMEM_WE_mux_sig;
wire   		            I2SData_wclk;

wire sel_wr_master_i2s_fblk_bar;

wire [9:0]   wr_addr_ram0;
wire [9:0]   rd_addr_ram0;
wire [15:0]  wr_data_ram0;
wire 		 wr_en_ram0;

wire [9:0]   wr_addr_ram1;
wire [9:0]   rd_addr_ram1;
wire [15:0]  wr_data_ram1;
wire 		 wr_en_ram1;
wire [15:0]  L_Pref_RAM0_RD_DATA;
wire [15:0]  L_Pref_RAM1_RD_DATA; 

wire [15:0]  L_Pref_RAM_RD_DATA_sig;

wire         ram0_wr_clk;
wire         ram1_wr_clk;
wire         ram0_wr_clk_g;
wire         ram1_wr_clk_g;
wire         ram_logic_rst;

reg          ignore_1st_toggle_after_rst;

reg          address_wrapp_toggle;
reg          address_wrapp_toggle_r1;
wire         address_wrapp_toggle_1pulse;

assign ram_logic_rst 				= RAM_logic_rst_i | WBs_RST_i;

assign f_start_o 					= address_wrapp_toggle_1pulse ;
assign address_wrapp_toggle_1pulse  = (address_wrapp_toggle ^ address_wrapp_toggle_r1) & (~ignore_1st_toggle_after_rst);

genvar br_i; 
generate 
for( br_i=0; br_i<10; br_i=br_i+1 ) 
begin : brev 
assign I2S_FIR_DATA_WaDDR_sig_br[br_i] = I2S_FIR_DATA_WaDDR_sig[9-br_i]; 
end 
endgenerate



always @( posedge i2s_clk_i or posedge ram_logic_rst)
begin
    if (ram_logic_rst)
    begin
         address_wrapp_toggle  		<= 0;
         address_wrapp_toggle_r1  	<= 0;
		 ignore_1st_toggle_after_rst <= 1;
	end  
    else
    begin
	     address_wrapp_toggle    <= I2S_FIR_DATA_WaDDR_sig[10];
		 address_wrapp_toggle_r1 <= address_wrapp_toggle;
		 if (address_wrapp_toggle & ~I2S_FIR_DATA_WaDDR_sig[10])
		 begin
		    ignore_1st_toggle_after_rst <= 0;
		 end	 
    end  
end 


//New Addition based on the decimator--Anand
always @( posedge i2s_clk_i or posedge ram_logic_rst)
begin
    if (ram_logic_rst)
    begin
         I2S_FIR_DATA_WaDDR_sig  <= 11'h3FF;//h1FF
         I2S_wMEM_WE_sig  <= 1'b0;
		
    end  
    else
    begin
	  if (L_I2SRx_Pref_RXRAM_WR_i)
	  begin
		 I2S_FIR_DATA_WaDDR_sig  <= I2S_FIR_DATA_WaDDR_sig + 1;
		 I2S_wMEM_WE_sig         <= 1'b1; 
	  end	 
	  else
	  begin
	     I2S_FIR_DATA_WaDDR_sig  <= I2S_FIR_DATA_WaDDR_sig;
		 I2S_wMEM_WE_sig         <= 1'b0; 
	  end	 
    end  
end 



			
// Ram instantiation 
//I2S Mono data is written to RAM for f
assign I2SData_ADDR_mux_sig 	= (wb_L_f_RAM_wr_rd_Mast_sel_i) ? {1'b0,wb_L_f_RAM_aDDR_i} : {I2S_FIR_DATA_WaDDR_sig[10],I2S_FIR_DATA_WaDDR_sig_br} ;
//assign I2SData_ADDR_mux_sig 	= (wb_L_f_RAM_wr_rd_Mast_sel_i) ? {1'b0,wb_L_f_RAM_aDDR_i} : I2S_FIR_DATA_WaDDR_sig ;
assign I2SData_DATA_mux_sig 	= (wb_L_f_RAM_wr_rd_Mast_sel_i) ? 15'h00 : L_I2SRx_Pref_RXRAM_DAT_i;//L_RXFIFO_DAT_i ;//Default clear with Zeros from Wishbone
assign I2SData_wMEM_WE_mux_sig 	= (wb_L_f_RAM_wr_rd_Mast_sel_i) ? wb_L_f_RAM_Wen_i  : I2S_wMEM_WE_sig ;
assign I2SData_wclk 			= (wb_L_f_RAM_wr_rd_Mast_sel_i) ? ~WBs_CLK_i  : ~i2s_clk_i ;

assign sel_wr_master_i2s_fblk_bar = I2SData_ADDR_mux_sig[10];

assign ram0_wr_clk = (sel_wr_master_i2s_fblk_bar) ? I2SData_wclk : ~WBs_CLK_i;
assign ram1_wr_clk = (~sel_wr_master_i2s_fblk_bar) ? I2SData_wclk : ~WBs_CLK_i;

gclkbuff  u_i2sram0_gclkbuff
			(
			.A(ram0_wr_clk),	
			.Z(ram0_wr_clk_g)
			);

			
gclkbuff  u_i2sram1_gclkbuff
			(
			.A(ram1_wr_clk),	
			.Z(ram1_wr_clk_g)
			);	


			
assign L_Pref_RAM_RD_DATA_sig = (~sel_wr_master_i2s_fblk_bar) ? L_Pref_RAM0_RD_DATA : L_Pref_RAM1_RD_DATA;
assign L_f_RAM_RD_DATA_o   = L_Pref_RAM_RD_DATA_sig;
assign wb_L_f_Real_RAM_Data_o	= L_Pref_RAM_RD_DATA_sig;			
			
assign wr_addr_ram0 = (sel_wr_master_i2s_fblk_bar) ?  I2SData_ADDR_mux_sig[9:0] 	: L_f_RAM_WaDDR_i;
assign wr_data_ram0 = (sel_wr_master_i2s_fblk_bar) ?  I2SData_DATA_mux_sig 		: L_f_RAM_WR_DATA_i;
assign wr_en_ram0   = (sel_wr_master_i2s_fblk_bar) ?  I2SData_wMEM_WE_mux_sig 	: L_f_RAM_Wr_en_i;

assign rd_addr_ram0 = (wb_L_f_RAM_wr_rd_Mast_sel_i) ? wb_L_f_RAM_aDDR_i[9:0]    : L_f_RAM_RaDDR_i;


r1024x16_1024x16 u_r1024x16_1024x16_I2S_f_RAM0_DATA (
								 .WA	  	( wr_addr_ram0 ), 
								 .RA		( rd_addr_ram0 )	,
								 
								 .WD		( wr_data_ram0 ), 
								 .WD_SEL	( wr_en_ram0 ),//(I2SData_wMEM_WE_mux_sig), 
								 .RD_SEL	( 1'b1 )	,
								 .WClk		( ram0_wr_clk_g ),
								 .RClk		( WBs_CLK_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {wr_en_ram0,wr_en_ram0} ),
								 .RD		( L_Pref_RAM0_RD_DATA  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )

								);
								
assign wr_addr_ram1 = (~sel_wr_master_i2s_fblk_bar) ?  I2SData_ADDR_mux_sig[9:0]  : L_f_RAM_WaDDR_i;
assign wr_data_ram1 = (~sel_wr_master_i2s_fblk_bar) ?  I2SData_DATA_mux_sig 		: L_f_RAM_WR_DATA_i;
assign wr_en_ram1   = (~sel_wr_master_i2s_fblk_bar) ?  I2SData_wMEM_WE_mux_sig 	: L_f_RAM_Wr_en_i;

assign rd_addr_ram1 = (wb_L_f_RAM_wr_rd_Mast_sel_i) ? wb_L_f_RAM_aDDR_i[9:0]    : L_f_RAM_RaDDR_i;
								
r1024x16_1024x16 u_r1024x16_1024x16_I2S_f_RAM1_DATA (
								 .WA	  	( wr_addr_ram1 ), 
								 .RA		( rd_addr_ram1 )	,
								 
								 .WD		( wr_data_ram1 ), 
								 .WD_SEL	( wr_en_ram1 ),//(I2SData_wMEM_WE_mux_sig), 
								 .RD_SEL	( 1'b1 )	,
								 .WClk		( ram1_wr_clk_g ),
								 .RClk		( WBs_CLK_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {wr_en_ram1,wr_en_ram1} ),
								 .RD		( L_Pref_RAM1_RD_DATA  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )

								);								
								
								


endmodule


