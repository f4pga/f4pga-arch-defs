// file           : serializer_deserializer.v 
// description  : Serializer_Deserializer Module
// Modified        : 2013/09/09 
// Modified by     : Rakesh Moolacheri	
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author              description
// 2008/xx/xx      1.0        XXXXX               created
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------
`timescale 1ns / 10ps

module serializer_deserializer ( MOSI_i,MOSI_o, MOSI_OEn_o, MISO_i, SCK_o, SSn0_o, SSn1_o, SSn2_o, SSn3_o, SSn4_o, SSn5_o, SSn6_o, SSn7_o, 
								 Divisor_i, SPE_i, BIDIROEn_i, SPC0_i, CPOL_i, CPHA_i, LSBFE_i, Bus_CLK_i, RST_i, RST_SYNC_i,test_mode_en,
								 trnfer_cmplte_o, start_i, stop_i,read_i, write_i, SPI_Bit_Ctrl_i, Ext_SPI_Clk_Cnt_i, 
								 Ext_SPI_Clk_En_i,SPI_Read_Data_o,SPI_Write_Data_i,SPI_CS_Reg_i,IRQ_read_o,IRQ_write_o,Baud_Clk_o );
	
	input 		MOSI_i;
	output 		MOSI_o;
	output 		MOSI_OEn_o;
	input 		MISO_i;
	output 		SCK_o;
	output 		SSn0_o;
	output 		SSn1_o;
	output 		SSn2_o;
	output 		SSn3_o;
	output 		SSn4_o;
	output 		SSn5_o;
	output 		SSn6_o;
	output		SSn7_o;

	input [15:0]Divisor_i;
	input 		SPE_i;
	input 		BIDIROEn_i;
	input 		SPC0_i;
	input 		CPOL_i;
	input 		CPHA_i;
	input 		LSBFE_i;

	input 		Bus_CLK_i;
	input 		RST_i;
	input 		RST_SYNC_i;
	
	input 		test_mode_en;
	
	output 		trnfer_cmplte_o; 
	
	input 		start_i;
	input 		stop_i;
	input 		read_i;
	input 		write_i;
	
	input [2:0] SPI_Bit_Ctrl_i;
	input [2:0] Ext_SPI_Clk_Cnt_i;
	input 		Ext_SPI_Clk_En_i;
	
	input [7:0] SPI_Write_Data_i;			
	input [7:0] SPI_CS_Reg_i;

	output [7:0]SPI_Read_Data_o;
	output 		IRQ_read_o;
	output 		IRQ_write_o;
	output 		Baud_Clk_o;
 
	
	reg [2:0] FSM_spi_state;
	parameter IDLE = 0, SPI_START_ST = 1, SPI_STOP_ST = 2, SPI_WR_ST = 3, WR_DONE_IRQ_ST = 4,
			  SPI_RD_ST = 5,  RD_DONE_IRQ_ST = 6, SPI_EXT_CLK_ST = 7;

	wire [7:0] 	SPIDR ;
	reg 		SS_bar;
	
	reg [2:0] 	bit_count;
	wire 		Baud_Rate;	
	wire 		Baud_Rate_int;
	reg			trnsfer_done;

	reg [7:0] 	Shift_Reg;

	reg 		IRQ_read;
	wire clk_cntrl;
	wire MISO;
	wire start;
	wire stop;
	reg  [7:0] SPI_Read_Data;
	wire Baud_Rate_Clk;
	
	assign SPI_Read_Data_o = SPI_Read_Data;
	
	assign Baud_Clk_o = Baud_Rate;
	
	assign trnfer_cmplte_o = (FSM_spi_state == SPI_STOP_ST);
	
	ql_mux2_x2 ql_mux2_x2_INST_C01(
        .s                      (test_mode_en),		
        .i0                     (Baud_Rate_int),
        .i1                     (Bus_CLK_i),		
        .z                      (Baud_Rate_Clk)
	);
	
    ql_clkgate_x4 ql_clkgate_x4_spim_clk (
		.clk_in                 (Baud_Rate_Clk),
		.en                     (1'b1),
		.se                     (1'b0),
		.clk_out                (Baud_Rate)
		);
	
	//baud generator
	baud_generator BG (.Baud_Rate_o(Baud_Rate_int),
		.Bus_Clk_i(Bus_CLK_i),
		.Divisor_i(Divisor_i),
		.RST_i(RST_i)
		);	   
	
	assign start = (start_i && SPE_i);
	assign stop = (stop_i && SPE_i);
	
	/* Bit Counter for the bytes and it counts when the SPI is out of the IDLE state */
	always @ (posedge Baud_Rate or posedge RST_i)
	begin
		if(RST_i)
			bit_count <= 8'h00;
		else if (RST_SYNC_i)
			bit_count <= 8'h00;   
		else
		    if(FSM_spi_state == SPI_WR_ST || FSM_spi_state == SPI_RD_ST || FSM_spi_state == SPI_EXT_CLK_ST)
					bit_count <= bit_count + 1;	
			else if(FSM_spi_state == IDLE)
					bit_count <= 8'h00;   
	end 
	
	assign SPIDR = 	SPI_Write_Data_i;		

	always @ (posedge RST_i or posedge Baud_Rate)
	begin
		if (RST_i)  begin
				SS_bar <= 1'b0; 
			end
		else if (RST_SYNC_i) begin
				SS_bar <= 1'b0; 
			end
		else 		  
			begin
				if (FSM_spi_state == IDLE && start == 1'b1)
					SS_bar <= 1'b1;
				else if (FSM_spi_state == IDLE && stop == 1'b1)
					SS_bar <= 1'b0;
				else 
					SS_bar <= SS_bar;
			end
	end	
	
	assign SSn0_o = (SS_bar && SPI_CS_Reg_i[0])? 1'b0 : 1'b1; 
	assign SSn1_o = (SS_bar && SPI_CS_Reg_i[1])? 1'b0 : 1'b1;
	assign SSn2_o = (SS_bar && SPI_CS_Reg_i[2])? 1'b0 : 1'b1;
	assign SSn3_o = (SS_bar && SPI_CS_Reg_i[3])? 1'b0 : 1'b1;
	assign SSn4_o = (SS_bar && SPI_CS_Reg_i[4])? 1'b0 : 1'b1;
	assign SSn5_o = (SS_bar && SPI_CS_Reg_i[5])? 1'b0 : 1'b1;
	assign SSn6_o = (SS_bar && SPI_CS_Reg_i[6])? 1'b0 : 1'b1;
	assign SSn7_o = (SS_bar && SPI_CS_Reg_i[7])? 1'b0 : 1'b1;
	
	assign IRQ_write_o = (FSM_spi_state == WR_DONE_IRQ_ST);
	assign IRQ_read_o = IRQ_read;
	
	always @ (posedge RST_i or posedge Baud_Rate)
	begin
		if (RST_i)  begin
				IRQ_read <= 1'b0;
			end
		else if (RST_SYNC_i) begin
				IRQ_read <= 1'b0; 
			end
		else 		  
			begin
				IRQ_read <= (FSM_spi_state == RD_DONE_IRQ_ST);	
			end
	end
	
	always @ (posedge RST_i or negedge Baud_Rate)
	begin
		if (RST_i)  begin
				trnsfer_done <= 1'b0; 
			end
		else if (RST_SYNC_i) begin
				trnsfer_done <= 1'b0; 
			end
		else 		  
			begin
				if (bit_count == SPI_Bit_Ctrl_i)
					trnsfer_done <= 1'b1;
				else 
					trnsfer_done <= 1'b0;
			end
	end	
	
	/* SCK signal based on CPHA, CPOL, BAUD CLOCK and State Machine State*/
	assign clk_cntrl = CPOL_i ^ CPHA_i;	
	assign SCK_o = (FSM_spi_state == IDLE || FSM_spi_state == SPI_START_ST || FSM_spi_state == SPI_STOP_ST || FSM_spi_state == WR_DONE_IRQ_ST
                 	|| FSM_spi_state == RD_DONE_IRQ_ST || (trnsfer_done == 1'b1 && CPHA_i == 1'b1)) ? CPOL_i : (clk_cntrl == 1'b0)? ~Baud_Rate : Baud_Rate;
	
	// SPI state machine	
	always @ (posedge Baud_Rate or posedge RST_i)
	begin
		if(RST_i)
			FSM_spi_state <= IDLE;	
		else if (RST_SYNC_i)
			FSM_spi_state <= IDLE;	
		else begin
				case (FSM_spi_state) 
					IDLE : begin  
							if(start)
								FSM_spi_state <= SPI_START_ST; 
							else if (stop)
								FSM_spi_state <= SPI_STOP_ST;
							else
								FSM_spi_state <= IDLE;
						end
					
					SPI_START_ST : begin
      						if(write_i)
								FSM_spi_state <= SPI_WR_ST; 
							else if(read_i)
								FSM_spi_state <= SPI_RD_ST;	
							else 
								FSM_spi_state <= IDLE; 						
					
						end
						
					SPI_STOP_ST : begin
      						if(Ext_SPI_Clk_En_i)
								FSM_spi_state <= SPI_EXT_CLK_ST; 
							else 
								FSM_spi_state <= IDLE; 		
						end
					
					SPI_WR_ST : begin
							if(bit_count == SPI_Bit_Ctrl_i) begin 
								FSM_spi_state <= WR_DONE_IRQ_ST;
							  end
							else begin
								FSM_spi_state <= SPI_WR_ST;
							  end
						end
						
					WR_DONE_IRQ_ST : begin
							if(start == 1'b0)
								FSM_spi_state <= IDLE;
						    else
							    FSM_spi_state <= WR_DONE_IRQ_ST; 
						end
						
					SPI_RD_ST : begin
							if(bit_count == SPI_Bit_Ctrl_i) begin
								FSM_spi_state <= RD_DONE_IRQ_ST;
							  end
							else begin
								FSM_spi_state <= SPI_RD_ST;
							  end
						end
						
					RD_DONE_IRQ_ST : begin
							if(start == 1'b0)
								FSM_spi_state <= IDLE;
						    else
							    FSM_spi_state <= RD_DONE_IRQ_ST; 
						end
					
					 SPI_EXT_CLK_ST: begin
							if(bit_count == Ext_SPI_Clk_Cnt_i) begin
								FSM_spi_state <= IDLE;
							  end
							else begin
								FSM_spi_state <= SPI_EXT_CLK_ST;
							  end
						end
						
					default :   FSM_spi_state <= IDLE;
					
				endcase
			end
		end
	
	//Serializer block
	always @ (posedge Baud_Rate or posedge RST_i)
	begin
		if(RST_i)
			Shift_Reg <= 8'h00;
		else if (RST_SYNC_i)
			Shift_Reg <= 8'h00;
		else 
			if (FSM_spi_state == SPI_WR_ST || FSM_spi_state == SPI_RD_ST) begin
				if(LSBFE_i) // (LSB)
						Shift_Reg <= {Shift_Reg[0], Shift_Reg[7:1]};          
				else                                                              
						Shift_Reg <= {Shift_Reg[6:0], Shift_Reg[7]};  
			  end	
			else begin 
	            Shift_Reg <= SPIDR;
			  end	  	
    end				
	
	// Bidirectional Mode for Master
	assign MISO = (BIDIROEn_i && SPC0_i) ? MOSI_i : MISO_i;
	
	// The default state of MOSI is "1", when the SPI is in Bidir mode and State machine is in the read fifo deserialize data
	// MOSI is driven by the slave, hence its a "z". 
	//assign MOSI_io = (FSM_spi_state == IDLE || FSM_spi_state == SPI_START_ST || FSM_spi_state == SPI_STOP_ST || FSM_spi_state == WR_DONE_IRQ_ST 
	//		|| FSM_spi_state == RD_DONE_IRQ_ST || FSM_spi_state == SPI_EXT_CLK_ST || (BIDIROEn_i == 0 && FSM_spi_state == SPI_RD_ST )) 
	//		? 1'b1 : (BIDIROEn_i == 1 && FSM_spi_state == SPI_RD_ST)
	//		? 1'bz : (LSBFE_i)? Shift_Reg[0] : Shift_Reg[7];
			
	assign MOSI_o = (FSM_spi_state == IDLE || FSM_spi_state == SPI_START_ST || FSM_spi_state == SPI_STOP_ST || FSM_spi_state == WR_DONE_IRQ_ST 
			|| FSM_spi_state == RD_DONE_IRQ_ST || FSM_spi_state == SPI_EXT_CLK_ST || (BIDIROEn_i == 0 && FSM_spi_state == SPI_RD_ST )) 
			? 1'b1 : (LSBFE_i)? Shift_Reg[0] : Shift_Reg[7];
	
	assign MOSI_OEn_o = (SPC0_i == 1'b1 && BIDIROEn_i == 1'b1 && FSM_spi_state == SPI_RD_ST)? 1'b1: 1'b0;
	    
	//De-seializer block
	always @ ( negedge Baud_Rate or posedge RST_i)     
    begin	
		if(RST_i) begin
			SPI_Read_Data <= 8'h00;	
          end			
		else if (RST_SYNC_i) begin
			SPI_Read_Data <= 8'h00;
		  end
		else if (FSM_spi_state == SPI_WR_ST || FSM_spi_state == SPI_RD_ST) begin		   
			if(LSBFE_i)
				SPI_Read_Data <= {MISO, SPI_Read_Data[7:1]};
			else 
				SPI_Read_Data <= {SPI_Read_Data[6:0], MISO}; 
		  end
		else begin
			SPI_Read_Data <= SPI_Read_Data;
		  end
	end
	
endmodule
