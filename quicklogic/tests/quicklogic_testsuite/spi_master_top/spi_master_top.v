// -----------------------------------------------------------------------------
// title          : SPI Master	
// project        : SPI Master PSB
// -----------------------------------------------------------------------------
// file           : spi_master_top.v , Top Level File
// author         : XXXXXX		
// company        : QuickLogic Corp
// created        : 2015/06/21
// last update    : 
// platform       : 
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Top module
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author              description
// 2008/xx/xx      1.0        XXXXX               created
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------
// ---------- Design Unit Header ---------- //
`timescale 1ns / 10ps

module top (wb_clk_i, wb_rst_i, arst_i, wb_adr_i, wb_dat_i, wb_dat_o,
					   wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_inta_o,TIP_o,test_mode_en,
					   MISO_i, MOSI_i, MOSI_o, MOSI_OEn_o, SCLK_o, SSn0_o, SSn1_o, SSn2_o, SSn3_o, SSn4_o, SSn5_o, SSn6_o, SSn7_o);

	//
	// inputs & outputs
	//

	// wishbone signals
	input        wb_clk_i;     // master clock input
	input        wb_rst_i;     // synchronous active high reset
	input        arst_i;       // asynchronous reset
	input  [2:0] wb_adr_i;     // lower address bits
	input  [7:0] wb_dat_i;     // databus input
	output [7:0] wb_dat_o;     // databus output
	input        wb_we_i;      // write enable input
	input        wb_stb_i;     // stobe/core select signal
	input        wb_cyc_i;     // valid bus cycle input
	output       wb_ack_o;     // bus cycle acknowledge output
	output       wb_inta_o;    // interrupt request signal output
	
	// control signals
	output       TIP_o;	   // transfer in progress
	
	//test mode signals
	input 		test_mode_en;
	
	// spi interface signals
	input 		 MISO_i;
	input 		 MOSI_i;
	output 		 MOSI_o;
	output 		 MOSI_OEn_o;   //Output enable, active low
	output 		 SCLK_o;
	output 		 SSn0_o;
	output 		 SSn1_o;
	output 		 SSn2_o;
	output 		 SSn3_o;
	output 		 SSn4_o;
	output 		 SSn5_o;
	output 		 SSn6_o;
	output 		 SSn7_o;


	// ----------- Signal declarations -------- //
	wire CPHA;
	wire CPOL;
	wire IRQ_read;
	wire IRQ_write;
	wire LSBFE;
	wire BIDIROEn;
	wire SPC0;
	wire SPE;
	wire [15:0] divisor;
    wire [7:0] SPI_Read_Data;
	wire [7:0] SPI_Write_Data;
	wire [7:0] SPI_CS_Reg;
	wire [2:0] SPI_Bit_Ctrl;
	wire [2:0] Ext_SPI_Clk_Cnt;
	wire Ext_SPI_Clk_En;

	reg wb_ack_i;
    
	wire wb_wacc;
	wire rst;
	wire trnfer_cmplte;
	wire start; 
	wire stop;
	wire read; 
	wire write;

    // generate internal reset
	assign rst = arst_i;

	// generate wishbone signals
	assign wb_wacc = wb_we_i & wb_ack_i;

	// generate acknowledge output signal
	always @(posedge wb_clk_i or posedge rst)
	  if (rst)
	    wb_ack_i <= 1'b0;
	  else if (wb_rst_i)
	    wb_ack_i <= 1'b0;
	  else
	    wb_ack_i <= #1 wb_cyc_i & wb_stb_i & ~wb_ack_i; // because timing is always honored
		
	assign wb_ack_o = wb_ack_i;

// -------- Component instantiations -------//
	registers spi_register (
			.AD_i(wb_adr_i),
			.CLK_i(wb_clk_i),
			.RST_i(rst),
			.RST_SYNC_i(wb_rst_i),
			.WR_i(wb_wacc),

			.Data_i(wb_dat_i),
			.Data_o(wb_dat_o),
			
			.Divisor_o(divisor),
			.SPE_o(SPE),
			.BIDIROEn_o(BIDIROEn),
			.SPC0_o(SPC0),
			.CPOL_o(CPOL),
			.CPHA_o(CPHA),
			.LSBFE_o(LSBFE),
			
			.trnfer_cmplte_i(trnfer_cmplte),
			.start_o(start),
			.stop_o(stop),
			.read_o(read),
			.write_o(write),
			
			.SPI_Bit_Ctrl_o(SPI_Bit_Ctrl),
			.Ext_SPI_Clk_Cnt_o(Ext_SPI_Clk_Cnt),
			.Ext_SPI_Clk_En_o(Ext_SPI_Clk_En),

			.SPI_Read_Data_i(SPI_Read_Data),
			.SPI_Write_Data_o(SPI_Write_Data),
			.SPI_CS_Reg_o(SPI_CS_Reg),
			.IRQ_read_i(IRQ_read),
			.IRQ_write_i(IRQ_write),
			.INTR_o(wb_inta_o),
			.TIP_o(TIP_o)
			);


serializer_deserializer ser_des(
			.MOSI_i(MOSI_i), 
			.MOSI_o(MOSI_o),
			.MOSI_OEn_o(MOSI_OEn_o),
			.MISO_i(MISO_i),
			.SCK_o(SCLK_o),
			.SSn0_o(SSn0_o),
			.SSn1_o(SSn1_o),
			.SSn2_o(SSn2_o),
			.SSn3_o(SSn3_o),
			.SSn4_o(SSn4_o),
			.SSn5_o(SSn5_o),
			.SSn6_o(SSn6_o),
			.SSn7_o(SSn7_o),
			
			.Divisor_i(divisor),
			.SPE_i(SPE),
			.BIDIROEn_i(BIDIROEn),
			.SPC0_i(SPC0),
			.CPOL_i(CPOL),
			.CPHA_i(CPHA),
			.LSBFE_i(LSBFE),
			
			.trnfer_cmplte_o(trnfer_cmplte),
			.start_i(start),
			.stop_i(stop),
			.read_i(read),
			.write_i(write),
			
			.SPI_Bit_Ctrl_i(SPI_Bit_Ctrl),
			.Ext_SPI_Clk_Cnt_i(Ext_SPI_Clk_Cnt),
			.Ext_SPI_Clk_En_i(Ext_SPI_Clk_En),

			.Bus_CLK_i(wb_clk_i),
			.RST_i(rst),
			.RST_SYNC_i(wb_rst_i),
			
			.test_mode_en(test_mode_en),
			
			.SPI_Read_Data_o(SPI_Read_Data),
			.SPI_Write_Data_i(SPI_Write_Data),
        	.SPI_CS_Reg_i(SPI_CS_Reg),

			.IRQ_read_o(IRQ_read),
			.IRQ_write_o(IRQ_write),
			.Baud_Clk_o()
			);

endmodule 
