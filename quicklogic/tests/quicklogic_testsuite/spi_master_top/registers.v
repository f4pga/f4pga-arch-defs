// file           : registers.v 
// description  : SPI Register Module
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
module registers (AD_i, CLK_i, RST_i, RST_SYNC_i, WR_i,	Data_i,	Data_o,Divisor_o, SPE_o,	
				  BIDIROEn_o, SPC0_o, CPOL_o, CPHA_o, LSBFE_o,trnfer_cmplte_i,start_o,stop_o,
				  read_o,write_o, SPI_Bit_Ctrl_o,Ext_SPI_Clk_Cnt_o,Ext_SPI_Clk_En_o,SPI_Read_Data_i, 
				  SPI_Write_Data_o, SPI_CS_Reg_o,IRQ_read_i,IRQ_write_i, INTR_o, TIP_o);	
	
	// wishbone interface signals
	
	input 	[2:0] 	AD_i;
	input			CLK_i;
	input			RST_i;
	input			RST_SYNC_i;
	input			WR_i;

	input  	[7:0] 	Data_i;
	output  [7:0] 	Data_o;
	
	//Register value
	output [15:0] 	Divisor_o;
	output		    SPE_o;
	output		    BIDIROEn_o;
	output		    SPC0_o;
	output		    CPOL_o;
	output		    CPHA_o;
	output		    LSBFE_o;

	input 	[7:0]  	SPI_Read_Data_i;
	output 	[7:0]  	SPI_Write_Data_o;
	output 	[7:0]  	SPI_CS_Reg_o;
	output 	[2:0]  	SPI_Bit_Ctrl_o;
	output 	[2:0]  	Ext_SPI_Clk_Cnt_o;
	output			Ext_SPI_Clk_En_o;
	
	input		   	IRQ_read_i; 
	input			IRQ_write_i;
	output 			INTR_o; 
	output 			TIP_o; 
	
	input		   	trnfer_cmplte_i;
	
	output 			start_o; 
	output 			stop_o;
	output 			read_o;
	output 			write_o;
	
		
	// internal registers and wires
	wire  			SPIE;
	reg [7:0]    	SPICR1;
	reg [15:0]  	SPIBR;
	reg [7:0]    	tx_reg;
	reg [2:0]    	spi_ctrl_reg;
	reg [7:0]    	spi_clk_cnt_reg;
	wire     	    spi_clk_cnt_en;
	reg [7:0]    	ss_reg;				// SS7......SS0  slave selects
	reg 		   	cmd_reg0; 
	reg 		   	cmd_reg1; 
	reg [1:0]    	cmd_reg32;
	reg 		  	cmd_reg7;
	reg 			irq_rd1, irq_rd2;
	wire			irq_rd_pos;	
	reg 			irq_wr1, irq_wr2;
	wire			irq_wr_pos;
	wire            IACK;
	reg             TIP;
	reg         	INTR_read, INTR_write;
	
	reg  [7:0] 		Data_out_r;	

	
	// Baud_Rate register
	assign Divisor_o = SPIBR;
	
	// SPI Control register 1 	
	assign SPE_o = SPICR1[7];
	assign SPIE = SPICR1[6];
	assign BIDIROEn_o = SPICR1[5];
	assign SPC0_o = SPICR1[4];
	assign CPOL_o = SPICR1[3];
	assign CPHA_o = SPICR1[2];
	assign LSBFE_o = SPICR1[0];  
	
	assign TIP_o = TIP;
	assign start_o = cmd_reg0; 
	assign stop_o = cmd_reg1;
	assign read_o = cmd_reg32[1];
	assign write_o = cmd_reg32[0];
	assign SPI_Write_Data_o = tx_reg;
	assign SPI_CS_Reg_o = ss_reg;
	assign SPI_Bit_Ctrl_o = spi_ctrl_reg;
	assign Ext_SPI_Clk_Cnt_o = spi_clk_cnt_reg;
	assign Ext_SPI_Clk_En_o = spi_clk_cnt_en;
	
	
	assign Data_o = Data_out_r; 
   
	// Logic to clear the interrupt flags.	
	always @ (posedge CLK_i or posedge RST_i)
		if(RST_i)
			begin
				irq_rd1 <= 1'b0;		// 2 flops for the clock domain synchronization
				irq_rd2 <= 1'b0;
				irq_wr1 <= 1'b0;
				irq_wr2 <= 1'b0;
			end	
		else if (RST_SYNC_i)
			begin
				irq_rd1 <= 1'b0;		// 2 flops for the clock domain synchronization
				irq_rd2 <= 1'b0;
				irq_wr1 <= 1'b0;
				irq_wr2 <= 1'b0;
			end
		else
			begin
				irq_rd2 <= irq_rd1;		// 2 flops for the clock domain synchronization
				irq_rd1 <= IRQ_read_i;
				irq_wr2 <= irq_wr1;
				irq_wr1 <= IRQ_write_i;
			end	
	
	assign	irq_rd_pos = (irq_rd1 && ~irq_rd2);  // posedge detector read
	assign  irq_wr_pos = (irq_wr1 && ~irq_wr2);  // posedge detector write
	
	always @ (posedge CLK_i or posedge RST_i)
		if ( RST_i ) begin
			INTR_read    <= 1'b0;
		end
		else if (RST_SYNC_i) begin
			INTR_read    <= 1'b0;
		end
		else begin
			if (irq_rd_pos)
				INTR_read    <= 1'b1;
			else if (IACK)
				INTR_read    <= 1'b0;
		end	
		
	always @ (posedge CLK_i or posedge RST_i)
		if ( RST_i ) begin
			INTR_write    <= 1'b0;
		end
		else if (RST_SYNC_i) begin
			INTR_write    <= 1'b0;
		end
		else begin
			if (irq_wr_pos)
				INTR_write    <= 1'b1;
			else if (IACK)
				INTR_write    <= 1'b0;
		end	
		
	always @ (posedge CLK_i or posedge RST_i)
		if ( RST_i ) begin
			TIP    <= 1'b0;
		end
		else if (RST_SYNC_i) begin
			TIP  <= 1'b0;
		end
		else begin
			TIP <= (cmd_reg32[1] | cmd_reg32[0]);
		end	

	assign INTR_o = (INTR_read || INTR_write) && SPIE && SPICR1[7];
	
	assign spi_clk_cnt_en = spi_clk_cnt_reg[7];			// SPI clock enable after CSn is deactivated
	
	// registers
	always @ (posedge CLK_i or posedge RST_i )
		begin
			if (RST_i)       					   
				begin
					SPIBR <= 16'h0001; 			   	// SPI Baud Register, Read and write anytime
					SPICR1 <= 8'h00;		       	// SPI control register 1, Read and Write anytime
					tx_reg <= 8'h00;			   	// Transmit register
					ss_reg <= 8'h00;			 	// Slave Select register
					spi_ctrl_reg <= 3'b111;			// SPI bit transaction control
					spi_clk_cnt_reg <= 8'h00;		// No. of SPI clock after CSn is deactivated
				end	 
			else if (RST_SYNC_i) 
				begin
					SPIBR <= 16'h0001; 			   	// SPI Baud Register, Read and write anytime
					SPICR1 <= 8'h00;		       	// SPI control register 1, Read and Write anytime
					tx_reg <= 8'h00;			   	// Transmit register
					ss_reg <= 8'h00;			 	// Slave Select register
					spi_ctrl_reg <= 3'b111;			// SPI bit transaction control
					spi_clk_cnt_reg <= 8'h00;		// No. of SPI clock after CSn is deactivated
				end
			else
				begin 		
					if (WR_i)
						case (AD_i) // synopsys parallel_case
							3'b000 : SPIBR [ 7:0] 	<= #1 Data_i[7:0];
							3'b001 : SPIBR [15:8] 	<= #1 Data_i[7:0];
							3'b010 : SPICR1[ 7:0] 	<= #1 {Data_i[7:2],1'b0,Data_i[0]};
							3'b011 : tx_reg [7:0] 	<= #1 Data_i[7:0];
							3'b101 : ss_reg       	<= #1 Data_i[7:0];
							3'b110 : spi_ctrl_reg 	<= #1 Data_i[2:0];
							3'b111 : spi_clk_cnt_reg<= #1 {Data_i[7],4'h0,Data_i[2:0]};
							default: ;
						endcase
				end
		end
	
	// generate command register (special case) 
	always @(posedge CLK_i or posedge RST_i)
		begin
			if (RST_i) begin
				cmd_reg0 <= #1 1'b0;
			end
			else if (RST_SYNC_i) begin 
				cmd_reg0 <= #1 1'b0;
			end
			else if (WR_i)
			begin
				if (SPICR1[7] & (AD_i == 3'b100))
					cmd_reg0 <= #1 Data_i[0];
			end
			else
			begin
				if (IRQ_read_i || IRQ_write_i)
					cmd_reg0 <= #1 1'b0;           // clear start bit when done
	        end	
		end
		
	always @(posedge CLK_i or posedge RST_i)
		begin
			if (RST_i) begin
				cmd_reg1 <= #1 1'b0;
			end
			else if (RST_SYNC_i) begin 
				cmd_reg1 <= #1 1'b0;
			end
			else if (WR_i)
			begin
				if (SPICR1[7] & (AD_i == 3'b100))
					cmd_reg1 <= #1 Data_i[1];
			end
			else
			begin
				if (trnfer_cmplte_i)
					cmd_reg1 <= #1 1'b0;           // clear stop bit when done
	        end	
		end
		
	always @(posedge CLK_i or posedge RST_i)
		begin
			if (RST_i) begin
				cmd_reg32 <= #1 2'b00;
			end
			else if (RST_SYNC_i) begin 
				cmd_reg32 <= #1 2'b00;
			end
			else if (WR_i)
			begin
				if (SPICR1[7] & (AD_i == 3'b100))
					cmd_reg32 <= #1 Data_i[3:2];
			end
			else
			begin
				if (IRQ_read_i || IRQ_write_i)
					cmd_reg32 <= #1 2'b00;           // clear read write bits when done
	        end	
		end	

		
    always @(posedge CLK_i or posedge RST_i)
		begin
			if (RST_i) begin
				cmd_reg7 <= #1 1'b0;
			end
			else if (RST_SYNC_i) begin 
				cmd_reg7 <= #1 1'b0;
			end
			else if (WR_i)
			begin
				if (SPICR1[7] & (AD_i == 3'b100))
					cmd_reg7 <= #1 Data_i[7];
			end
			else
			begin
				if (!INTR_write && !INTR_read) 
					cmd_reg7 <= #1 1'b0;           // clear IACK bit when done
	        end	
		end	
	
	assign IACK = cmd_reg7;
		
// reading registers memory map 
//always @(AD_i[2:0] or SPIBR or SPICR1 or SPI_Read_Data_i or TIP or INTR_write or INTR_read or ss_reg or spi_ctrl_reg or spi_clk_cnt_reg)
always @(posedge CLK_i)
		begin
			case(AD_i[2:0])
				3'b000: Data_out_r <=  SPIBR[7:0];
				3'b001: Data_out_r <=  SPIBR[15:8];
				3'b010: Data_out_r <=  SPICR1[7:0];
				3'b011: Data_out_r <=  SPI_Read_Data_i;
				3'b100: Data_out_r <=  {5'b00000,TIP,INTR_write,INTR_read};
				3'b101: Data_out_r <=  ss_reg;
				3'b110: Data_out_r <=  {5'b00000,spi_ctrl_reg};
				3'b111: Data_out_r <=  spi_clk_cnt_reg; 
				default : Data_out_r <= SPI_Read_Data_i;
			endcase 
		end  
	
endmodule
