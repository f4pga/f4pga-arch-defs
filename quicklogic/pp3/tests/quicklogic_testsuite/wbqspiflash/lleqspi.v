///////////////////////////////////////////////////////////////////////////
//
// Filename: 	lleqspi.v
//
// Project:	Wishbone Controlled Quad SPI Flash Controller
//
// Purpose:	Reads/writes a word (user selectable number of bytes) of data
//		to/from a Quad SPI port.  The port is understood to be 
//		a normal SPI port unless the driver requests four bit mode.
//		When not in use, unlike our previous SPI work, no bits will
//		toggle.
//
// Creator:	Dan Gisselquist
//		Gisselquist Technology, LLC
//
///////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2016, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory, run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
///////////////////////////////////////////////////////////////////////////
`define	EQSPI_IDLE	3'h0
`define	EQSPI_START	3'h1
`define	EQSPI_BITS	3'h2
`define	EQSPI_READY	3'h3
`define	EQSPI_HOLDING	3'h4
`define	EQSPI_STOP	3'h5
`define	EQSPI_STOP_B	3'h6
`define	EQSPI_RECYCLE	3'h7

// Modes
`define	EQSPI_MOD_SPI	2'b00
`define	EQSPI_MOD_QOUT	2'b10	// Write
`define	EQSPI_MOD_QIN	2'b11	// Read

module	lleqspi(i_clk,
		// Module interface
		i_wr, i_hold, i_word, i_len, i_spd, i_dir, i_recycle,
			o_word, o_valid, o_busy,
		// QSPI interface
		o_sck, o_cs_n, o_mod, o_dat, i_dat);
	input			i_clk;
	// Chip interface
	//	Can send info
	//		i_dir = 1, i_spd = 0, i_hold = 0, i_wr = 1,
	//			i_word = { 1'b0, 32'info to send },
	//			i_len = # of bytes in word-1
	input			i_wr, i_hold;
	input		[31:0]	i_word;
	input		[1:0]	i_len;	// 0=>8bits, 1=>16 bits, 2=>24 bits, 3=>32 bits
	input			i_spd; // 0 -> normal QPI, 1 -> QSPI
	input			i_dir; // 0 -> read, 1 -> write to SPI
	input			i_recycle; // 0 = 20ns, 1 = 50ns
	output	reg	[31:0]	o_word;
	output	reg		o_valid;
	output	reg		o_busy;
	// Interface with the QSPI lines
	output	reg		o_sck;
	output	reg		o_cs_n;
	output	reg	[1:0]	o_mod;
	output	reg	[3:0]	o_dat;
	input		[3:0]	i_dat;

	// output	wire	[22:0]	o_dbg;
	// assign	o_dbg = { state, spi_len,
		// o_busy, o_valid, o_cs_n, o_sck, o_mod, o_dat, i_dat };

	wire	i_miso;
	assign	i_miso = i_dat[1];

	// These are used in creating a delayed input.
	reg		rd_input, rd_spd, rd_valid;

	reg		r_spd, r_dir;
	reg	[3:0]	r_recycle;
	reg	[5:0]	spi_len;
	reg	[31:0]	r_word;
	reg	[30:0]	r_input;
	reg	[2:0]	state;
	initial	state = `EQSPI_IDLE;
	initial	o_sck   = 1'b1;
	initial	o_cs_n  = 1'b1;
	initial	o_dat   = 4'hd;
	initial	rd_valid = 1'b0;
	initial	o_busy  = 1'b0;
	initial	r_input = 31'h000;
	initial rd_valid = 1'b0;
	always @(posedge i_clk)
	begin
		rd_input <= 1'b0;
		rd_spd   <= r_spd;
		rd_valid <= 1'b0;
		
		if ((state == `EQSPI_IDLE)&&(o_sck))
		begin
			o_cs_n <= 1'b1;
			o_busy  <= 1'b0;
			o_mod <= `EQSPI_MOD_SPI;
			r_word <= i_word;
			r_spd <= i_spd;
			r_dir <= i_dir;
			o_dat <= 4'hc;
			r_recycle <= (i_recycle)? 4'h8 : 4'h2; // 4'ha : 4'h4
			spi_len<= { 1'b0, i_len, 3'b000 } + 6'h8;
			o_sck <= 1'b1;
			if (i_wr)
			begin
				state <= `EQSPI_START;
				o_cs_n <= 1'b0;
				o_busy <= 1'b1;
			end
		end else if (state == `EQSPI_START)
		begin // We come in here with sck high, stay here 'til sck is low
			o_sck <= 1'b0;
			if (o_sck == 1'b0)
			begin
				state <= `EQSPI_BITS;
				spi_len<= spi_len - ( (r_spd)? 6'h4 : 6'h1 );
				if (r_spd)
					r_word <= { r_word[27:0], 4'h0 };
				else
					r_word <= { r_word[30:0], 1'b0 };
			end
			o_mod <= (r_spd) ? { 1'b1, r_dir } : `EQSPI_MOD_SPI;
			o_cs_n <= 1'b0;
			o_busy <= 1'b1;
			if (r_spd)
				o_dat <= r_word[31:28];
			else
				o_dat <= { 3'b110, r_word[31] };
		end else if (~o_sck)
		begin
			o_sck <= 1'b1;
			o_busy <= ((state != `EQSPI_READY)||(~i_wr));
		end else if (state == `EQSPI_BITS)
		begin
			// Should enter into here with at least a spi_len
			// of one, perhaps more
			o_sck <= 1'b0;
			o_busy <= 1'b1;
			if (r_spd)
			begin
				o_dat <= r_word[31:28];
				r_word <= { r_word[27:0], 4'h0 };
				spi_len <= spi_len - 6'h4;
				if (spi_len == 6'h4)
					state <= `EQSPI_READY;
			end else begin
				o_dat <= { 3'b110, r_word[31] };
				r_word <= { r_word[30:0], 1'b0 };
				spi_len <= spi_len - 6'h1;
				if (spi_len == 6'h1)
					state <= `EQSPI_READY;
			end

			rd_input <= 1'b1;
		end else if (state == `EQSPI_READY)
		begin
			o_cs_n <= 1'b0;
			o_busy <= 1'b1;
			// This is the state on the last clock (both low and
			// high clocks) of the data.  Data is valid during
			// this state.  Here we chose to either STOP or
			// continue and transmit more.
			o_sck <= (i_hold); // No clocks while holding
			if((~o_busy)&&(i_wr))// Acknowledge a new request
			begin
				state <= `EQSPI_BITS;
				o_busy <= 1'b1;
				o_sck <= 1'b0;

				// Read the new request off the bus
				r_spd <= i_spd;
				r_dir <= i_dir;
				// Set up the first bits on the bus
				o_mod <= (i_spd) ? { 1'b1, i_dir } : `EQSPI_MOD_SPI;
				if (i_spd)
				begin
					o_dat <= i_word[31:28];
					r_word <= { i_word[27:0], 4'h0 };
					// spi_len <= spi_len - 4;
					spi_len<= { 1'b0, i_len, 3'b000 } + 6'h8
						- 6'h4;
				end else begin
					o_dat <= { 3'b110, i_word[31] };
					r_word <= { i_word[30:0], 1'b0 };
					spi_len<= { 1'b0, i_len, 3'b000 } + 6'h8
						- 6'h1;
				end

				// Read a bit upon any transition
				rd_input <= 1'b1;
				rd_valid <= 1'b1;
			end else begin
				o_sck <= 1'b1;
				state <= (i_hold)?`EQSPI_HOLDING : `EQSPI_STOP;
				o_busy <= (~i_hold);

				// Read a bit upon any transition
				rd_valid <= 1'b1;
				rd_input <= 1'b1;
			end
		end else if (state == `EQSPI_HOLDING)
		begin
			// We need this state so that the o_valid signal
			// can get strobed with our last result.  Otherwise
			// we could just sit in READY waiting for a new command.
			//
			// Incidentally, the change producing this state was
			// the result of a nasty race condition.  See the
			// commends in wbqspiflash for more details.
			//
			rd_valid <= 1'b0;
			o_cs_n <= 1'b0;
			o_busy <= 1'b0;
			if((~o_busy)&&(i_wr))// Acknowledge a new request
			begin
				state  <= `EQSPI_BITS;
				o_busy <= 1'b1;
				o_sck  <= 1'b0;

				// Read the new request off the bus
				r_spd <= i_spd;
				r_dir <= i_dir;
				// Set up the first bits on the bus
				o_mod<=(i_spd)?{ 1'b1, i_dir } : `EQSPI_MOD_SPI;
				if (i_spd)
				begin
					o_dat <= i_word[31:28];
					r_word <= { i_word[27:0], 4'h0 };
					spi_len<= { 1'b0, i_len, 3'b100 };
				end else begin
					o_dat <= { 3'b110, i_word[31] };
					r_word <= { i_word[30:0], 1'b0 };
					spi_len<= { 1'b0, i_len, 3'b111 };
				end
			end else begin
				o_sck <= 1'b1;
				state <= (i_hold)?`EQSPI_HOLDING : `EQSPI_STOP;
				o_busy <= (~i_hold);
			end
		end else if (state == `EQSPI_STOP)
		begin
			o_sck   <= 1'b1; // Stop the clock
			rd_valid <= 1'b0; // Output may have just been valid, but no more
			o_busy  <= 1'b1; // Still busy till port is clear
			state <= `EQSPI_STOP_B;
			// Can't change modes for at least one cycle
			// o_mod <= `EQSPI_MOD_SPI;
		end else if (state == `EQSPI_STOP_B)
		begin
			o_cs_n <= 1'b1;
			o_sck <= 1'b1;
			// Do I need this????
			// spi_len <= 3; // Minimum CS high time before next cmd
			state <= `EQSPI_RECYCLE;
			o_busy <= 1'b1;
			o_mod <= `EQSPI_MOD_SPI;
		end else begin // Recycle state
			r_recycle <= r_recycle - 1'b1;
			o_cs_n <= 1'b1;
			o_sck <= 1'b1;
			o_busy <= 1'b1;
			o_mod <= `EQSPI_MOD_SPI;
			o_dat <= 4'hc;
			if (r_recycle[3:1] == 3'h0)
				state <= `EQSPI_IDLE;
		end
		/*
		end else begin // Invalid states, should never get here
			state   <= `EQSPI_STOP;
			o_valid <= 1'b0;
			o_busy  <= 1'b1;
			o_cs_n  <= 1'b1;
			o_sck   <= 1'b1;
			o_mod   <= `EQSPI_MOD_SPI;
			o_dat   <= 4'hd;
		end
		*/
	end

`define EXTRA_DELAY
	wire	rd_input_N, rd_valid_N, r_spd_N;
`ifdef EXTRA_DELAY
	reg	[2:0]	rd_input_p, rd_valid_p, r_spd_p;
	always @(posedge i_clk)
		rd_input_p <= { rd_input_p[1:0], rd_input };
	always @(posedge i_clk)
		rd_valid_p <= { rd_valid_p[1:0], rd_valid };
	always @(posedge i_clk)
		r_spd_p <= { r_spd_p[1:0], r_spd };

	assign	rd_input_N = rd_input_p[2];
	assign	rd_valid_N = rd_valid_p[2];
	assign	r_spd_N = r_spd_p[2];
`else
	assign	rd_input_N = rd_input;
	assign	rd_valid_N = rd_valid;
	assign	r_spd_N    = rd_spd;
`endif


	always @(posedge i_clk)
	begin
		// if ((state == `EQSPI_IDLE)||(rd_valid_N))
		if (o_valid)
			r_input <= 31'h00;
		if ((rd_input_N)&&(r_spd_N))
			r_input <= { r_input[26:0], i_dat };
		else if (rd_input_N)
			r_input <= { r_input[29:0], i_miso };

		if ((rd_valid_N)&&(r_spd_N))
			o_word  <= { r_input[27:0], i_dat };
		else if (rd_valid_N)
			o_word  <= { r_input[30:0], i_miso };
		o_valid <= rd_valid_N;
	end

endmodule

