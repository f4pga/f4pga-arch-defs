////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	eqspiflash.v
//
// Project:	OpenArty, an entirely open SoC based upon the Arty platform
//
// Purpose:	Provide access to the flash device on an Arty, via the Extended
//		SPI interface.  Reads and writes will use the QuadSPI interface
//	(4-bits at a time) all other commands (register and otherwise) will use
//	the SPI interface (1 bit at a time).
//
// Registers:
//	0. Erase register control.  Provides status of pending writes, erases,
//		and commands (sub)sector erase operations.
//	   Bit-Fields:
//		31. WIP (Write-In-Progress), write a '1' to this bit to command
//			an erase sequence.
//		30. WriteEnabled -- set to a '1' to disable write protection and
//			to write a WRITE-ENABLE to the device.  Set to a '0' to
//			disable WRITE-ENABLE-LATCH.  (Key is required to enable
//			writes)
//		29. Quad mode read/writes enabled.  (Rest of controller will use
//			extended SPI mode, but reads and writes will use Quad
//			mode.)
//		28. Subsector erase bit (set 1 to erase a subsector, 0 to 
//			erase a full sector, maintains last value written from
//			an erase command, starts at '0')
//		27. SD ID loaded
//		26. Write protect violation--cleared upon any valid write
//		25. XIP enabled.  (Leave read mode in XIP, so you can start
//			next read faster.)
//		24. Unused
//		23..0: Address of erase sector upon erase command
//		23..14: Sector address (can only be changed w/ key)
//		23..10: Subsector address (can only be changed w/ key)
//		 9.. 0: write protect KEY bits, always read a '0', write
//			commands, such as WP disable or erase, must always
//			write with a '1be' to activate.
//	0. WEL:	All writes that do not command an erase will be used
//			to set/clear the write enable latch.
//			Send 0x06, return, if WP is clear (enable writes)
//			Send 0x04, return
//	1. STATUS
//		Send 0x05, read  1-byte
//		Send 0x01, write 1-byte: i_wb_data[7:0]
//	2. NV-CONFIG (16-bits)
//		Send 0xB5, read  2-bytes
//		Send 0xB1, write 2-bytes: i_wb_data[15:0]
//	3. V-CONFIG (8-bits)
//		Send 0x85, read  1-byte
//		Send 0x81, write 1-byte: i_wb_data[7:0]
//	4. EV-CONFIG (8-bits)
//		Send 0x65, read  1-byte
//		Send 0x61, write 1-byte: i_wb_data[7:0]
//	5. Lock (send 32-bits, rx 1 byte)
//		Send 0xE8, last-sector-addr (3b), read  1-byte
//		Send 0xE5, last-sector-addr (3b), write 1-byte: i_wb_data[7:0]
//	6. Flag Status
//		Send 0x70, read  1-byte
//		Send 0x50, to clear, no bytes to write
//	7. Asynch Read-ID: Write here to cause controller to read ID into buffer
//	8.-12.	ID buffer (20 bytes, 5 words)
//		Attempted reads before buffer is full will stall bus until 
//		buffer is read.  Writes act like the asynch-Read-ID command,
//		and will cause the controller to read the buffer.
//	13.-14. Unused, mapped to Asynch-read-ID
//	15.	OTP control word
//			Write zero to permanently lock OTP
//			Read to determine if OTP is permanently locked
//	16.-31.	OTP (64-bytes, 16 words, buffered until write)
//		(Send DWP before writing to clear write enable latch)
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////
//
//
// `define	QSPI_READ_ONLY
module	eqspiflash(i_clk_200mhz, i_rst,
		// Incoming wishbone connection(s)
		//	The two strobe lines allow the data to live on a
		//	separate part of the master bus from the control 
		//	registers.  Only one strobe will ever be active at any
		//	time, no strobes will ever be active unless i_wb_cyc
		//	is also active.
		i_wb_cyc, i_wb_data_stb, i_wb_ctrl_stb, i_wb_we,
		i_wb_addr, i_wb_data,
		// Outgoing wishbone data
		o_wb_ack, o_wb_stall, o_wb_data,
		// Quad SPI connections
		o_qspi_sck, o_qspi_cs_n, o_qspi_mod, o_qspi_dat, i_qspi_dat,
		// Interrupt the CPU
		o_interrupt, o_cmd_accepted,
		// Debug the interface
		o_dbg);

	input			i_clk_200mhz, i_rst;
	// Wishbone bus inputs
	input			i_wb_cyc, i_wb_data_stb, i_wb_ctrl_stb, i_wb_we;
	input		[21:0]	i_wb_addr;	// 24 bits of addr space
	input		[31:0]	i_wb_data;
	// Wishbone bus outputs
	output	reg		o_wb_ack;
	output	wire		o_wb_stall;
	output	reg	[31:0]	o_wb_data;
	// Quad SPI connections
	output	wire		o_qspi_sck, o_qspi_cs_n;
	output	wire	[1:0]	o_qspi_mod;
	output	wire	[3:0]	o_qspi_dat;
	input	wire	[3:0]	i_qspi_dat;
	//
	output	reg		o_interrupt;
	//
	output	reg		o_cmd_accepted;
	//
	output	wire	[31:0]	o_dbg;

	initial	o_cmd_accepted = 1'b0;
	always @(posedge i_clk_200mhz)
		o_cmd_accepted=((i_wb_data_stb)||(i_wb_ctrl_stb))&&(~o_wb_stall);
	//
	// lleqspi
	//
	//	Providing the low-level SPI interface
	//
	reg	spi_wr, spi_hold, spi_spd, spi_dir, spi_recycle;
	reg	[31:0]	spi_word;
	reg	[1:0]	spi_len;
	wire	[31:0]	spi_out;
	wire		spi_valid, spi_busy, spi_stopped;
	lleqspi	lowlvl(i_clk_200mhz, spi_wr, spi_hold, spi_word, spi_len,
			spi_spd, spi_dir, spi_recycle, spi_out, spi_valid, spi_busy,
		o_qspi_sck, o_qspi_cs_n, o_qspi_mod, o_qspi_dat, i_qspi_dat);
	assign	spi_stopped = (o_qspi_cs_n)&&(~spi_busy)&&(~spi_wr);


	//
	// Bus module
	//
	//	Providing a shared interface to the WB bus
	//
	// Wishbone data (returns)
	wire		bus_wb_ack, bus_wb_stall;
	wire	[31:0]	bus_wb_data;
	// Latched request data
	wire		bus_wr;
	wire	[21:0]	bus_addr;
	wire	[31:0]	bus_data;
	wire	[21:0]	bus_sector;
	// Strobe commands
	wire	bus_ack;
	wire	bus_readreq, bus_piperd, bus_ereq, bus_wreq,
			bus_pipewr, bus_endwr, bus_ctreq, bus_idreq,
			bus_other_req,
	// Live parameters
			w_xip, w_quad, w_idloaded;
	reg		bus_wip;
	qspibus	preproc(i_clk_200mhz, i_rst,
			i_wb_cyc, i_wb_data_stb, i_wb_ctrl_stb,
				i_wb_we, i_wb_addr, i_wb_data,
				bus_wb_ack, bus_wb_stall, bus_wb_data,
			bus_wr, bus_addr, bus_data, bus_sector,
				bus_readreq, bus_piperd,
					bus_wreq, bus_ereq,
					bus_pipewr, bus_endwr,
				bus_ctreq, bus_idreq, bus_other_req, bus_ack,
			w_xip, w_quad, w_idloaded, bus_wip, spi_stopped);

	//
	// Read flash module
	//
	//	Providing a means of (and the logic to support) reading from
	//	the flash
	//
	wire		rd_data_ack;
	wire	[31:0]	rd_data;
	//
	wire		rd_bus_ack;
	//
	wire		rd_qspi_req;
	wire		rd_qspi_grant;
	//
	wire		rd_spi_wr, rd_spi_hold, rd_spi_spd, rd_spi_dir, 
			rd_spi_recycle;
	wire	[31:0]	rd_spi_word;
	wire	[1:0]	rd_spi_len;
	//
	readqspi	rdproc(i_clk_200mhz, bus_readreq, bus_piperd,
					bus_other_req,
				bus_addr, rd_bus_ack,
				rd_qspi_req, rd_qspi_grant,
				rd_spi_wr, rd_spi_hold, rd_spi_word, rd_spi_len,
				rd_spi_spd, rd_spi_dir, rd_spi_recycle,
					spi_out, spi_valid,
					spi_busy, spi_stopped, rd_data_ack, rd_data,
					w_quad, w_xip);

	//
	// Write/Erase flash module
	//
	//	Logic to write (program) and erase the flash.
	//
	// Wishbone bus return
	wire		ew_data_ack;
	wire	[31:0]	ew_data;
	// Arbiter interaction
	wire		ew_qspi_req;
	wire		ew_qspi_grant;
	// Bus controller return
	wire		ew_bus_ack;
	// SPI control wires
	wire		ew_spi_wr, ew_spi_hold, ew_spi_spd, ew_spi_dir;
	wire	[31:0]	ew_spi_word;
	wire	[1:0]	ew_spi_len;
	//
	wire		w_ew_wip;
	//
	writeqspi	ewproc(i_clk_200mhz, bus_wreq,bus_ereq,
					bus_pipewr, bus_endwr,
					bus_addr, bus_data,
				ew_bus_ack, ew_qspi_req, ew_qspi_grant,
				ew_spi_wr, ew_spi_hold, ew_spi_word, ew_spi_len,
					ew_spi_spd, ew_spi_dir,
					spi_out, spi_valid, spi_busy, spi_stopped,
				ew_data_ack, w_quad, w_ew_wip);

	//
	// Control module
	//
	//	Logic to read/write status and configuration registers
	//
	// Wishbone bus return
	wire		ct_data_ack;
	wire	[31:0]	ct_data;
	// Arbiter interaction
	wire		ct_qspi_req;
	wire		ct_grant;
	// Bus controller return
	wire		ct_ack;
	// SPI control wires
	wire		ct_spi_wr, ct_spi_hold, ct_spi_spd, ct_spi_dir;
	wire	[31:0]	ct_spi_word;
	wire	[1:0]	ct_spi_len;
	//
	ctrlspi		ctproc(i_clk_200mhz,
				bus_ctreq, bus_wr, bus_addr[2:0], bus_data, bus_sector,
				ct_qspi_req, ct_grant,
				ct_spi_wr, ct_spi_hold, ct_spi_word, ct_spi_len,
					ct_spi_spd, ct_spi_dir,
					spi_out, spi_valid, spi_busy, spi_stopped,
				ct_ack, ct_data_ack, ct_data, w_xip, w_quad);
	assign	ct_spi_hold = 1'b0;
	assign	ct_spi_spd  = 1'b0;

	//
	// ID/OTP module
	//
	//	Access to ID and One-Time-Programmable registers, but to read
	//	and to program (the OTP), and to finally lock (OTP) registers.
	//
	// Wishbone bus return
	wire		id_data_ack;
	wire	[31:0]	id_data;
	// Arbiter interaction
	wire		id_qspi_req;
	wire		id_qspi_grant;
	// Bus controller return
	wire		id_bus_ack;
	// SPI control wires
	wire		id_spi_wr, id_spi_hold, id_spi_spd, id_spi_dir;
	wire	[31:0]	id_spi_word;
	wire	[1:0]	id_spi_len;
	//
	wire		w_id_wip;
	//
	idotpqspi	idotp(i_clk_200mhz, bus_idreq,
				bus_wr, bus_pipewr, bus_addr[4:0], bus_data, id_bus_ack,
				id_qspi_req, id_qspi_grant,
				id_spi_wr, id_spi_hold, id_spi_word, id_spi_len,
					id_spi_spd, id_spi_dir,
					spi_out, spi_valid, spi_busy, spi_stopped,
				id_data_ack, id_data, w_idloaded, w_id_wip);

	// Arbitrator
	reg		owned;
	reg	[1:0]	owner;
	initial		owned = 1'b0;
	always @(posedge i_clk_200mhz) // 7 inputs (spi_stopped is the CE)
		if ((~owned)&&(spi_stopped))
		begin
			casez({rd_qspi_req,ew_qspi_req,id_qspi_req,ct_qspi_req})
			4'b1???: begin owned<= 1'b1; owner <= 2'b00; end
			4'b01??: begin owned<= 1'b1; owner <= 2'b01; end
			4'b001?: begin owned<= 1'b1; owner <= 2'b10; end
			4'b0001: begin owned<= 1'b1; owner <= 2'b11; end
			default: begin owned<= 1'b0; owner <= 2'b00; end
			endcase
		end else if ((owned)&&(spi_stopped))
		begin
			casez({rd_qspi_req,ew_qspi_req,id_qspi_req,ct_qspi_req,owner})
			6'b0???00: owned<= 1'b0;
			6'b?0??01: owned<= 1'b0;
			6'b??0?10: owned<= 1'b0;
			6'b???011: owned<= 1'b0;
			//default: 
			//begin ; end
			endcase
		end

	assign	rd_qspi_grant = (owned)&&(owner == 2'b00);
	assign	ew_qspi_grant = (owned)&&(owner == 2'b01);
	assign	id_qspi_grant = (owned)&&(owner == 2'b10);
	assign	ct_grant      = (owned)&&(owner == 2'b11);

	// Module controller
	always @(posedge i_clk_200mhz)
	case(owner)
	2'b00: begin
		spi_wr      <= (owned)&&(rd_spi_wr);
		spi_hold    <= rd_spi_hold;
		spi_word    <= rd_spi_word;
		spi_len     <= rd_spi_len;
		spi_spd     <= rd_spi_spd;
		spi_dir     <= rd_spi_dir;
		spi_recycle <= rd_spi_recycle;
		end
	2'b01: begin
		spi_wr	    <= (owned)&&(ew_spi_wr);
		spi_hold    <= ew_spi_hold;
		spi_word    <= ew_spi_word;
		spi_len     <= ew_spi_len;
		spi_spd     <= ew_spi_spd;
		spi_dir     <= ew_spi_dir;
		spi_recycle <= 1'b1; // Long recycle time
		end
	2'b10: begin
		spi_wr	    <= (owned)&&(id_spi_wr);
		spi_hold    <= id_spi_hold;
		spi_word    <= id_spi_word;
		spi_len     <= id_spi_len;
		spi_spd     <= id_spi_spd;
		spi_dir     <= id_spi_dir;
		spi_recycle <= 1'b1; // Long recycle time
		end
	2'b11: begin
		spi_wr	    <= (owned)&&(ct_spi_wr);
		spi_hold    <= ct_spi_hold;
		spi_word    <= ct_spi_word;
		spi_len     <= ct_spi_len;
		spi_spd     <= ct_spi_spd;
		spi_dir     <= ct_spi_dir;
		spi_recycle <= 1'b1; // Long recycle time
		end
	endcase

	reg	last_wip;
	initial	bus_wip = 1'b0;
	initial	last_wip = 1'b0;
	initial o_interrupt = 1'b0;
	always @(posedge i_clk_200mhz)
	begin
		bus_wip <= w_ew_wip || w_id_wip;
		last_wip <= bus_wip;
		o_interrupt <= ((~bus_wip)&&(last_wip));
	end


	// Now, let's return values onto the wb bus
	always @(posedge i_clk_200mhz)
	begin
		// Ack our internal bus controller.  This means the command was
		// accepted, and the bus can go on to looking for the next 
		// command.  It controls the i_wb_stall line, just not the
		// i_wb_ack line.

		// Ack the wishbone with any response
		o_wb_ack <= (bus_wb_ack)|(rd_data_ack)|(ew_data_ack)|(id_data_ack)|(ct_data_ack);
		o_wb_data <= (bus_wb_ack)?bus_wb_data
			: (id_data_ack) ? id_data : spi_out;
	end

	assign	o_wb_stall = bus_wb_stall;
	assign	bus_ack = (rd_bus_ack|ew_bus_ack|id_bus_ack|ct_ack);
		
	assign	o_dbg = {
		i_wb_cyc, i_wb_ctrl_stb, i_wb_data_stb, o_wb_ack, bus_ack, //5
		//
		(spi_wr)&&(~spi_busy), spi_valid, spi_word[31:25],
		spi_out[7:2],
		//
		o_qspi_cs_n, o_qspi_sck, o_qspi_mod,	// 4 bits
		o_qspi_dat, i_qspi_dat			// 8 bits
		};
endmodule

module	qspibus(i_clk, i_rst, i_cyc, i_data_stb, i_ctrl_stb,
		i_we, i_addr, i_data,
			o_wb_ack, o_wb_stall, o_wb_data,
		o_wr, o_addr, o_data, o_sector,
		o_readreq, o_piperd, o_wrreq, o_erreq, o_pipewr, o_endwr,
			o_ctreq, o_idreq, o_other,
		i_ack, i_xip, i_quad, i_idloaded, i_wip, i_spi_stopped);
	//
	input			i_clk, i_rst;
	// Wishbone bus inputs
	input			i_cyc, i_data_stb, i_ctrl_stb, i_we;
	input		[21:0]	i_addr;
	input		[31:0]	i_data;
	// Wishbone bus outputs
	output	reg		o_wb_ack;
	output	reg		o_wb_stall;
	output	wire	[31:0]	o_wb_data;
	// Internal signals to the QSPI flash interface
	output	reg		o_wr;
	output	reg	[21:0]	o_addr;
	output	reg	[31:0]	o_data;
	output	wire	[21:0]	o_sector;
	output	reg		o_readreq, o_piperd, o_wrreq, o_erreq,
				o_pipewr, o_endwr,
				o_ctreq, o_idreq;
	output	wire		o_other;
	input			i_ack, i_xip, i_quad, i_idloaded;
	input			i_wip, i_spi_stopped;


	//
	reg	pending, lcl_wrreq, lcl_ctreq, lcl_ack, ack, wp_err, wp;
	reg	lcl_reg;
	reg	[14:0]	esector;
	reg	[21:0]	next_addr;


	reg	pipeable;
	reg	same_page;
	always @(posedge i_clk)
		same_page <= (i_data_stb)&&(i_we)
			&&(i_addr[21:6] == o_addr[21:6])
			&&(i_addr[5:0] == o_addr[5:0] + 6'h1);

	initial	pending = 1'b0;
	initial	o_readreq = 1'b0;
	initial	lcl_wrreq = 1'b0;
	initial	lcl_ctreq = 1'b0;
	initial	o_ctreq   = 1'b0;
	initial	o_idreq   = 1'b0;

	initial	ack = 1'b0;
	always @(posedge i_clk)
		ack <= (i_ack)||(lcl_ack);

	// wire	[9:0]	key;
	// assign	key = 10'h1be;
	reg	lcl_key, set_sector, ctreg_stb;
	initial	lcl_key = 1'b0;
	always @(posedge i_clk)
		// Write protect "key" to enable the disabling of write protect
		lcl_key<= (i_ctrl_stb)&&(~wp)&&(i_we)&&(i_addr[5:0]==6'h00)
				&&(i_data[9:0] == 10'h1be)&&(i_data[31:30]==2'b11);
	initial	set_sector = 1'b0;
	always @(posedge i_clk)
		set_sector <= (i_ctrl_stb)&&(~o_wb_stall)
				&&(i_we)&&(i_addr[5:0]==6'h00)
				&&(i_data[9:0] == 10'h1be);

	always @(posedge i_clk)
		if (i_ctrl_stb)
			lcl_reg <= (i_addr[3:0] == 4'h00);

	initial	ctreg_stb = 1'b0;
	initial	o_wb_stall = 1'b0;
	always @(posedge i_clk)
	begin // Inputs: rst, stb, stb, stall, ack, addr[4:0] -- 9
		if (i_rst)
			o_wb_stall <= 1'b0;
		else
			o_wb_stall <= (((i_data_stb)||(i_ctrl_stb))&&(~o_wb_stall))
				||((pending)&&(~ack));

		ctreg_stb <= (i_ctrl_stb)&&(~o_wb_stall)&&(i_addr[4:0]==5'h00)&&(~pending)
				||(pending)&&(ctreg_stb)&&(~lcl_ack)&&(~i_ack);
		if (~o_wb_stall)
		begin // Bus command accepted!
			if ((i_data_stb)||(i_ctrl_stb))
			begin
				pending <= 1'b1;
				o_addr <= i_addr;
				o_data <= i_data;
				o_wr   <= i_we;
				next_addr <= i_addr + 22'h1;
			end

			if ((i_data_stb)&&(~i_we))
				o_readreq <= 1'b1;

			if ((i_data_stb)&&(i_we))
				lcl_wrreq <= 1'b1;
			if ((i_ctrl_stb)&&(~i_addr[4]))
			begin
				casez(i_addr[4:0])
				5'h0: lcl_ctreq<= 1'b1;
				5'h1: lcl_ctreq <= 1'b1;
				5'h2: lcl_ctreq <= 1'b1;
				5'h3: lcl_ctreq <= 1'b1;
				5'h4: lcl_ctreq <= 1'b1;
				5'h5: lcl_ctreq <= 1'b1;
				5'h6: lcl_ctreq <= 1'b1;
				5'h7: lcl_ctreq <= 1'b1;
				5'h8: o_idreq <= 1'b1;	// ID[0]
				5'h9: o_idreq <= 1'b1;	// ID[1]
				5'ha: o_idreq <= 1'b1;	// ID[2]
				5'hb: o_idreq <= 1'b1;	// ID[3]
				5'hc: o_idreq <= 1'b1;	// ID[4]
				5'hd: o_idreq <= 1'b1;	//
				5'he: o_idreq <= 1'b1;
				5'hf: o_idreq <= 1'b1; // Program OTP register
				default: begin o_idreq <= 1'b1; end
				endcase
			end else if (i_ctrl_stb)
				o_idreq <= 1'b1;
		end else if (ack)
		begin
			pending <= 1'b0;
			o_readreq <= 1'b0;
			o_idreq <= 1'b0;
			lcl_ctreq <= 1'b0;
			lcl_wrreq <= 1'b0;
		end

		if(i_rst)
		begin
			pending <= 1'b0;
			o_readreq <= 1'b0;
			o_idreq <= 1'b0;
			lcl_ctreq <= 1'b0;
			lcl_wrreq <= 1'b0;
		end

		if ((i_data_stb)&&(~o_wb_stall))
			o_piperd <= ((~i_we)&&(~o_wb_stall)&&(pipeable)&&(i_addr == next_addr));
		else if ((i_ack)||(((i_ctrl_stb)||(i_data_stb))&&(~o_wb_stall)))
			o_piperd <= 1'b0;
		if ((i_data_stb)&&(~o_wb_stall))
			pipeable <= (~i_we);
		else if ((i_ctrl_stb)&&(~o_wb_stall))
			pipeable <= 1'b0;

		o_pipewr <= (same_page)||(pending)&&(o_pipewr);
	end

	reg	r_other, last_wip;

	reg	last_pending;
	always @(posedge i_clk)
		last_pending <= pending;
	always @(posedge i_clk)
		last_wip <= i_wip;
	wire	new_req;
	assign	new_req = (pending)&&(~last_pending);

	initial	o_wrreq   = 1'b0;
	initial	o_erreq   = 1'b0;
	initial	wp_err    = 1'b0;
	initial	lcl_ack   = 1'b0;
	initial	r_other   = 1'b0;
	initial	o_endwr   = 1'b1;
	initial	wp        = 1'b1;
	always @(posedge i_clk)
	begin
		if (i_ack)
		begin
			o_erreq <= 1'b0;
			o_wrreq <= 1'b0;
			o_ctreq <= 1'b0;
			r_other <= 1'b0;
		end

		if ((last_wip)&&(~i_wip))
			wp <= 1'b1;

		// o_endwr  <= ((~i_cyc)||(~o_wr)||(o_pipewr))
				// ||(~new_req)&&(o_endwr);
		o_endwr <= ((pending)&&(~o_pipewr))||((~pending)&&(~i_cyc));

		// Default ACK is always set to zero, unless the following ...
		o_wb_ack <= 1'b0;

		if (set_sector)
		begin
			esector[13:0] <= { o_data[23:14], 4'h0 };
			wp <= (o_data[30])&&(new_req)||(wp)&&(~new_req);
			if (o_data[28])
			begin
				esector[14] <= o_data[28];
				esector[3:0] <= o_data[13:10];
			end
		end

		lcl_ack <= 1'b0;
		if ((i_wip)&&(new_req)&&(~same_page))
		begin
			o_wb_ack <= 1'b1;
			lcl_ack <= 1'b1;
		end else if ((ctreg_stb)&&(new_req))
		begin // A request of the status register
			// Always ack control register, even on failed attempts
			// to erase.
			o_wb_ack <= 1'b1;
			lcl_ack <= 1'b1;

			if (lcl_key)
			begin
				o_ctreq <= 1'b0;
				o_erreq <= 1'b1;
				r_other <= 1'b1;
				lcl_ack <= 1'b0;
			end else if ((o_wr)&&(~o_data[31]))
			begin // WEL or WEL disable
				o_ctreq <= (wp == o_data[30]);
				r_other <= (wp == o_data[30]);
				lcl_ack <= (wp != o_data[30]);
				wp <= !o_data[30];
			end else if (~o_wr)
				lcl_ack <= 1'b1;
			wp_err <= (o_data[31])&&(~lcl_key);
		end else if ((lcl_ctreq)&&(new_req))
		begin
			o_ctreq <= 1'b1;
			r_other <= 1'b1;
		end else if ((lcl_wrreq)&&(new_req))
		begin
			if (~wp)
			begin
				o_wrreq <= 1'b1;
				r_other <= 1'b1;
				o_endwr  <= 1'b0;
				lcl_ack <= 1'b0;
			end else begin
				o_wb_ack <= 1'b1;
				wp_err <= 1'b1;
				lcl_ack <= 1'b1;
			end
		end

		if (i_rst)
		begin
			o_ctreq <= 1'b0;
			o_erreq <= 1'b0;
			o_wrreq <= 1'b0;
			r_other <= 1'b0;
		end

	end


	assign o_wb_data[31:0] = { i_wip, ~wp, i_quad, esector[14],
			i_idloaded, wp_err, i_xip, i_spi_stopped,
			esector[13:0], 10'h00 };
	assign	o_sector = { esector[13:0], 8'h00 }; // 22 bits
	assign	o_other = (r_other)||(o_idreq);

endmodule


`define	RD_IDLE			4'h0
`define	RD_IDLE_GET_PORT	4'h1
`define	RD_SLOW_DUMMY		4'h2
`define	RD_SLOW_READ_DATA	4'h3
`define	RD_QUAD_READ_DATA	4'h4
`define	RD_QUAD_DUMMY		4'h5
`define	RD_QUAD_ADDRESS		4'h6
`define	RD_XIP			4'h7
`define	RD_GO_TO_IDLE		4'h8
`define	RD_GO_TO_XIP		4'h9

module	readqspi(i_clk, i_readreq, i_piperd, i_other_req, i_addr, o_bus_ack,
		o_qspi_req, i_grant,
			o_spi_wr, o_spi_hold, o_spi_word, o_spi_len,
				o_spi_spd, o_spi_dir, o_spi_recycle,
			i_spi_data, i_spi_valid, i_spi_busy, i_spi_stopped,
			o_data_ack, o_data, i_quad, i_xip);
	input			i_clk;
	input			i_readreq, i_piperd, i_other_req;
	input		[21:0]	i_addr;
	output	reg		o_bus_ack, o_qspi_req;
	input	wire		i_grant;
	output	reg		o_spi_wr;
	output	wire		o_spi_hold;
	output	reg	[31:0]	o_spi_word;
	output	reg	[1:0]	o_spi_len;
	output	reg		o_spi_spd, o_spi_dir, o_spi_recycle;
	input		[31:0]	i_spi_data;
	input			i_spi_valid, i_spi_busy, i_spi_stopped;
	output	reg		o_data_ack;
	output	reg	[31:0]	o_data;
	input			i_quad, i_xip;

	reg	accepted;
	initial	accepted = 1'b0;
	always @(posedge i_clk)
		accepted <= (~i_spi_busy)&&(i_grant)&&(o_spi_wr)&&(~accepted);

	reg	[3:0]	rd_state;
	reg		r_leave_xip, r_xip, r_quad, r_requested;
	reg	[3:0]	invalid_ack_pipe;
	initial	rd_state = `RD_IDLE;
	initial o_data_ack = 1'b0;
	initial o_bus_ack  = 1'b0;
	initial o_qspi_req = 1'b0;
	always @(posedge i_clk)
	begin
		o_data_ack <= 1'b0;
		o_bus_ack <= 1'b0;
		o_spi_recycle <= 1'b0;
		if (i_spi_valid)
			o_data <= i_spi_data;
		invalid_ack_pipe <= { invalid_ack_pipe[2:0], accepted };
		case(rd_state)
		`RD_IDLE: begin
			r_requested <= 1'b0;
			o_qspi_req <= 1'b0;
			o_spi_word <= { ((i_quad)? 8'h6B: 8'h0b), i_addr, 2'b00 };
			o_spi_wr <= 1'b0;
			o_spi_dir <= 1'b0;
			o_spi_spd <= 1'b0;
			o_spi_len <= 2'b11;
			r_xip <= (i_xip)&&(i_quad);
			r_leave_xip <= 1'b0; // Not in it, so can't leave it
			r_quad <= i_quad;
			if (i_readreq)
			begin
				rd_state <= `RD_IDLE_GET_PORT;
				o_bus_ack <= 1'b1;
			end end
		`RD_IDLE_GET_PORT: begin
			o_spi_wr <= 1'b1; // Write the address
			o_qspi_req <= 1'b1;
			if (accepted)
				rd_state <= `RD_SLOW_DUMMY;
			end
		`RD_SLOW_DUMMY: begin
			o_spi_wr <= 1'b1; // Write 8 dummy clocks
			o_qspi_req <= 1'b1;
			o_spi_dir <= 1'b0;
			o_spi_spd <= 1'b0;
			o_spi_word[31:24] <= (r_xip) ? 8'h00 : 8'hff;
			o_spi_len  <= 2'b00; // 8 clocks = 8-bits
			if (accepted)
				rd_state <= (r_quad)?`RD_QUAD_READ_DATA
						: `RD_SLOW_READ_DATA;
			end
		`RD_SLOW_READ_DATA: begin
			o_qspi_req <= 1'b1;
			o_spi_dir <= 1'b1;
			o_spi_spd <= 1'b0;
			o_spi_len <= 2'b11;
			o_spi_wr <= (~r_requested)||(i_piperd);
			invalid_ack_pipe[0] <= (!r_requested);
			o_data_ack <=  (!invalid_ack_pipe[3])&&(i_spi_valid)&&(r_requested);
			o_bus_ack <=   (r_requested)&&(accepted)&&(i_piperd);
			r_requested <= (r_requested)||(accepted);
			if ((i_spi_valid)&&(~o_spi_wr))
				rd_state <= `RD_GO_TO_IDLE;
			end
		`RD_QUAD_READ_DATA: begin
			o_qspi_req <= 1'b1;
			o_spi_dir <= 1'b1;
			o_spi_spd <= 1'b1;
			o_spi_len <= 2'b11;
			o_spi_recycle <= (r_leave_xip)? 1'b1: 1'b0;
			invalid_ack_pipe[0] <= (!r_requested);
			r_requested <= (r_requested)||(accepted);
			o_data_ack <=  (!invalid_ack_pipe[3])&&(i_spi_valid)&&(r_requested)&&(~r_leave_xip);
			o_bus_ack  <= (r_requested)&&(accepted)&&(i_piperd)&&(~r_leave_xip);
			o_spi_wr <= (~r_requested)||(i_piperd);
			// if (accepted)
				// o_spi_wr <= (i_piperd);
			if (accepted) // only happens if (o_spi_wr)
				o_data <= i_spi_data;
			if ((i_spi_valid)&&(~o_spi_wr))
				rd_state <= ((r_leave_xip)||(~r_xip))?`RD_GO_TO_IDLE:`RD_GO_TO_XIP;
			end
		`RD_QUAD_ADDRESS: begin
			o_qspi_req <= 1'b1;
			o_spi_wr <= 1'b1;
			o_spi_dir <= 1'b0; // Write the address
			o_spi_spd <= 1'b1; // High speed
			o_spi_word[31:0] <= { i_addr, 2'b00, 8'h00 };
			o_spi_len  <= 2'b10; // 24 bits, High speed, 6 clocks
			if (accepted)
				rd_state <= `RD_QUAD_DUMMY;
			end
		`RD_QUAD_DUMMY: begin
			o_qspi_req <= 1'b1;
			o_spi_wr <= 1'b1;
			o_spi_dir <= 1'b0; // Write the dummy
			o_spi_spd <= 1'b1; // High speed
			o_spi_word[31:0] <= (r_xip)? 32'h00 : 32'hffffffff;
			o_spi_len  <= 2'b11; // 8 clocks = 32-bits, quad speed
			if (accepted)
				rd_state <= (r_quad)?`RD_QUAD_READ_DATA
						: `RD_SLOW_READ_DATA;
			end
		`RD_XIP: begin
			r_requested <= 1'b0;
			o_qspi_req <= 1'b1;
			o_spi_word <= { i_addr, 2'b00, 8'h00 };
			o_spi_wr <= 1'b0;
			o_spi_dir <= 1'b0; // Write to SPI
			o_spi_spd <= 1'b1; // High speed
			o_spi_len <= 2'b11;
			r_leave_xip <= i_other_req;
			r_xip <= (~i_other_req);
			o_bus_ack <= 1'b0;
			if ((i_readreq)||(i_other_req))
			begin
				rd_state <= `RD_QUAD_ADDRESS;
				o_bus_ack <= i_readreq;
			end end
		`RD_GO_TO_IDLE: begin
			if ((!invalid_ack_pipe[3])&&(i_spi_valid)&&(~r_leave_xip))
				o_data_ack <=  1'b1;
			o_spi_wr   <= 1'b0;
			o_qspi_req <= 1'b0;
			if ((i_spi_stopped)&&(~i_grant))
				rd_state <= `RD_IDLE;
			end
		`RD_GO_TO_XIP: begin
			r_requested <= 1'b0;
			if ((i_spi_valid)&&(!invalid_ack_pipe[3]))
				o_data_ack <=  1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr   <= 1'b0;
			if (i_spi_stopped)
				rd_state <= `RD_XIP;
			end
		default: begin
			// rd_state <= (i_grant)?`RD_BREAK;
			o_qspi_req <= 1'b0;
			o_spi_wr <= 1'b0;
			if ((i_spi_stopped)&&(~i_grant))
				rd_state <= `RD_IDLE;
			end
		endcase
	end

	assign	o_spi_hold = 1'b0;

endmodule

module	writeqspi(i_clk, i_wreq, i_ereq, i_pipewr, i_endpipe, i_addr, i_data,
			o_bus_ack, o_qspi_req, i_qspi_grant,
				o_spi_wr, o_spi_hold, o_spi_word, o_spi_len,
				o_spi_spd, o_spi_dir, i_spi_data, i_spi_valid,
					i_spi_busy, i_spi_stopped,
				o_data_ack, i_quad, o_wip);
	input		i_clk;
	//
	input		i_wreq, i_ereq, i_pipewr, i_endpipe;
	input		[21:0]	i_addr;
	input		[31:0]	i_data;
	output	reg		o_bus_ack, o_qspi_req;
	input			i_qspi_grant;
	output	reg		o_spi_wr, o_spi_hold;
	output	reg	[31:0]	o_spi_word;
	output	reg	[1:0]	o_spi_len;
	output	reg		o_spi_spd, o_spi_dir;
	input		[31:0]	i_spi_data;
	input			i_spi_valid;
	input			i_spi_busy, i_spi_stopped;
	output	reg		o_data_ack;
	input			i_quad;
	output	reg		o_wip;

`ifdef	QSPI_READ_ONLY
	always @(posedge i_clk)
		o_data_ack <= (i_wreq)||(i_ereq);
	always @(posedge i_clk)
		o_bus_ack <= (i_wreq)||(i_ereq);

	always @(posedge i_clk)
	begin
		o_qspi_req <= 1'b0;
		o_spi_wr   <= 1'b0;
		o_spi_hold <= 1'b0;
		o_spi_dir  <= 1'b1; // Read
		o_spi_spd  <= i_quad;
		o_spi_len  <= 2'b00;
		o_spi_word <= 32'h00;
		o_wip <= 1'b0;
	end
`else

`define	WR_IDLE				4'h0
`define	WR_START_WRITE			4'h1
`define	WR_START_QWRITE			4'h2
`define	WR_PROGRAM			4'h3
`define	WR_PROGRAM_GETNEXT		4'h4
`define	WR_START_ERASE			4'h5
`define	WR_WAIT_ON_STOP			4'h6
`define	WR_REQUEST_STATUS		4'h7
`define	WR_REQUEST_STATUS_NEXT		4'h8
`define	WR_READ_STATUS			4'h9
`define	WR_WAIT_ON_FINAL_STOP		4'ha

	reg	accepted;
	initial	accepted = 1'b0;
	always @(posedge i_clk)
		accepted <= (~i_spi_busy)&&(i_qspi_grant)&&(o_spi_wr)&&(~accepted);


	reg		cyc, chk_wip, valid_status;
	reg	[3:0]	wr_state;
	initial	wr_state = `WR_IDLE;
	initial	cyc = 1'b0;
	always @(posedge i_clk)
	begin
		chk_wip <= 1'b0;
		o_bus_ack  <= 1'b0;
		o_data_ack <= 1'b0;
		case(wr_state)
		`WR_IDLE: begin
			valid_status <= 1'b0;
			o_qspi_req <= 1'b0;
			cyc <= 1'b0;
			if (i_ereq)
				wr_state <= `WR_START_ERASE;
			else if (i_wreq)
				wr_state <= (i_quad)?`WR_START_QWRITE
					: `WR_START_WRITE;
			end
		`WR_START_WRITE: begin
			o_wip      <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr   <= 1'b1;
			o_spi_dir  <= 1'b0;
			o_spi_len  <= 2'b11;
			o_spi_spd  <= 1'b0;
			o_spi_hold <= 1'b1;
			o_spi_word <= { 8'h02, i_addr, 2'b00 };
			cyc <= 1'b1;
			if (accepted)
			begin
				o_bus_ack  <= 1'b1;
				o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
				o_spi_word <= i_data;
			end end
		`WR_START_QWRITE: begin
			o_wip      <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr   <= 1'b1;
			o_spi_dir  <= 1'b0;
			o_spi_len  <= 2'b11;
			o_spi_spd  <= 1'b0;
			o_spi_hold <= 1'b1;
			o_spi_word <= { 8'h32, i_addr, 2'b00 };
			cyc <= 1'b1;
			if (accepted)
			begin
				o_bus_ack  <= 1'b1;
				o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
				o_spi_word <= i_data;
			end end
		`WR_PROGRAM: begin
			o_wip     <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr   <= 1'b1;
			o_spi_dir  <= 1'b0;
			o_spi_len  <= 2'b11;
			o_spi_spd  <= i_quad;
			o_spi_hold <= 1'b1;
			// o_spi_word <= i_data;
			if (accepted)
				wr_state <= `WR_PROGRAM_GETNEXT;
			end
		`WR_PROGRAM_GETNEXT: begin
			o_wip      <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr   <= 1'b0;
			o_spi_dir  <= 1'b0;
			o_spi_len  <= 2'b11;
			o_spi_spd  <= i_quad;
			o_spi_hold <= 1'b1;
			o_spi_word <= i_data;
			cyc <= (cyc)&&(~i_endpipe);
			if (~cyc)
				wr_state <= `WR_WAIT_ON_STOP;
			else if (i_pipewr)
			begin
				o_bus_ack  <= 1'b1;
				o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
			end end
		`WR_START_ERASE: begin
			o_wip <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_wr  <= 1'b1;
			o_spi_dir <= 1'b0;
			o_spi_spd <= 1'b0;
			o_spi_len <= 2'b11;
			if (i_data[28])
				// Subsector erase
				o_spi_word[31:24] <= 8'h20;
			else
				// Sector erase
				o_spi_word[31:24] <= 8'hd8;
			o_spi_word[23:0] <= { i_data[21:10], 12'h0 };
			// Data has already been ack'd, so no need to ack
			// it again.  However, we can now free the QSPI
			// bus processor to accept another command from the
			// bus.
			o_bus_ack <= accepted;
			if (accepted)
				wr_state <= `WR_WAIT_ON_STOP;
			end
		`WR_WAIT_ON_STOP: begin
			o_wip <= 1'b1;
			o_qspi_req <= 1'b0;
			o_spi_wr   <= 1'b0;
			o_spi_hold <= 1'b0;
			if (i_spi_stopped)
				wr_state <= `WR_REQUEST_STATUS;
			end
		`WR_REQUEST_STATUS: begin
			o_wip <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_wr   <= 1'b1;
			o_spi_spd  <= 1'b0; // Slow speed
			o_spi_len  <= 2'b00; // 8 bytes
			o_spi_dir  <= 1'b0; // Write
			o_spi_word <= { 8'h05, 24'h00 };
			if (accepted)
				wr_state <= `WR_REQUEST_STATUS_NEXT;
			end
		`WR_REQUEST_STATUS_NEXT: begin
			o_wip <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_wr   <= 1'b1;
			o_spi_spd  <= 1'b0; // Slow speed
			o_spi_len  <= 2'b00; // 8 bytes
			o_spi_dir  <= 1'b1; // Read
			o_spi_word <= 32'h00;
			if (accepted)
				wr_state <= `WR_READ_STATUS;
			valid_status <= 1'b0;
			end
		`WR_READ_STATUS: begin
			o_wip <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_wr   <= 1'b1;
			o_spi_spd  <= 1'b0; // Slow speed
			o_spi_len  <= 2'b00; // 8 bytes
			o_spi_dir  <= 1'b1; // Read
			o_spi_word <= 32'h00;
			if (i_spi_valid)
				valid_status <= 1'b1;
			if ((i_spi_valid)&&(valid_status))
				chk_wip <= 1'b1;
			if ((chk_wip)&&(~i_spi_data[0]))
				wr_state <= `WR_WAIT_ON_FINAL_STOP;
			end
		// `WR_WAIT_ON_FINAL_STOP: // Same as the default
		default: begin
			o_qspi_req <= 1'b0;
			o_spi_wr <= 1'b0;
			o_wip <= 1'b0;
			if (i_spi_stopped)
				wr_state <= `WR_IDLE;
			end
		endcase
	end
`endif

endmodule


`define	CT_SAFE
`define	CT_IDLE			3'h0
`define	CT_NEXT			3'h1
`define	CT_GRANTED		3'h2
`define	CT_DATA			3'h3
`define	CT_READ_DATA		3'h4
`define	CT_WAIT_FOR_IDLE	3'h5

// CTRL commands:
//	WEL (write-enable latch)
//	Read Status
module	ctrlspi(i_clk, i_req, i_wr, i_addr, i_data, i_sector_address,
				o_spi_req, i_grant,
				o_spi_wr, o_spi_hold, o_spi_word, o_spi_len,
					o_spi_spd, o_spi_dir,
				i_spi_data, i_spi_valid, i_spi_busy,
					i_spi_stopped,
				o_bus_ack, o_data_ack, o_data, o_xip, o_quad);
	input		i_clk;
	// From the WB bus controller
	input			i_req;
	input			i_wr;
	input		[2:0]	i_addr;
	input		[31:0]	i_data;
	input		[21:0]	i_sector_address;
	// To/from the arbiter
	output	reg		o_spi_req;
	input			i_grant;
	// To/from the low-level SPI driver
	output	reg		o_spi_wr;
	output	wire		o_spi_hold;
	output	reg	[31:0]	o_spi_word;
	output	reg	[1:0]	o_spi_len;
	output	wire		o_spi_spd;
	output	reg		o_spi_dir;
	input		[31:0]	i_spi_data;
	input			i_spi_valid;
	input			i_spi_busy, i_spi_stopped;
	// Return data to the bus controller, and the wishbone bus
	output	reg		o_bus_ack, o_data_ack;
	output	reg	[31:0]	o_data;
	// Configuration items that we may have configured.
	output	reg		o_xip;
	output	wire		o_quad;

	// Command registers
	reg	[1:0]	ctcmd_len;
	reg	[31:0]	ctcmd_word;
	// Data stage registers
	reg		ctdat_skip, // Skip the data phase?
			ctdat_wr;	// Write during data? (or not read)
	wire	[1:0]	ctdat_len;
	reg	[31:0]	ctdat_word;

	reg	[2:0]	ctstate;
	reg		accepted;
	reg	[3:0]	invalid_ack_pipe;


	initial	accepted = 1'b0;
	always @(posedge i_clk)
		accepted <= (~i_spi_busy)&&(i_grant)&&(o_spi_wr)&&(~accepted);

	reg	r_ctdat_len, ctbus_ack, first_valid;
	assign	ctdat_len = { 1'b0, r_ctdat_len };

	// First step, calculate the values for our state machine
	initial	o_xip = 1'b0;
	// initial o_quad = 1'b0;
	always @(posedge i_clk)
	if (i_req) // A request for us to act from the bus controller
	begin
		ctdat_skip <= 1'b0;
		ctbus_ack  <= 1'b1;
		ctcmd_word[23:0] <= { i_sector_address, 2'b00 };
		ctdat_word <= { i_data[7:0], 24'h00 };
		ctcmd_len <= 2'b00; // 8bit command (for all but Lock regs)
		r_ctdat_len <= 1'b0; // 8bit data (read or write)
		ctdat_wr <= i_wr;
		casez({ i_addr[2:0], i_wr, i_data[30] })
		5'b00010: begin // Write Disable
			ctcmd_word[31:24] <= 8'h04;
			ctdat_skip <= 1'b1;
			ctbus_ack  <= 1'b0;
			end
		5'b00011: begin // Write enable
			ctcmd_word[31:24] <= 8'h06;
			ctdat_skip <= 1'b1;
			ctbus_ack  <= 1'b0;
			end
		// 4'b0010?: begin // Read Status register
		//	Moved to defaults section
		5'b0011?: begin // Write Status register (Requires WEL)
			ctcmd_word[31:24] <= 8'h01;
`ifdef	CT_SAFE
			ctdat_word <= { 6'h00, i_data[1:0], 24'h00 };
`else
			ctdat_word <= { i_data[7:0], 24'h00 };
`endif
			end
		5'b0100?: begin // Read NV-Config register (two bytes)
			ctcmd_word[31:24] <= 8'hB5;
			r_ctdat_len <= 1'b1; // 16-bit data
			end
		5'b0101?: begin // Write NV-Config reg (2 bytes, Requires WEL)
			ctcmd_word[31:24] <= 8'hB1;
			r_ctdat_len <= 1'b1; // 16-bit data
`ifdef	CT_SAFE
			ctdat_word <= { 4'h8, 3'h7, 3'h7, i_data[5:1], 1'b1, 16'h00 };
`else
			ctdat_word <= { i_data[15:0], 16'h00 };
`endif
			end
		5'b0110?: begin // Read V-Config register
			ctcmd_word[31:24] <= 8'h85;
			end
		5'b0111?: begin // Write V-Config register (Requires WEL)
			ctcmd_word[31:24] <= 8'h81;
			r_ctdat_len <= 1'b0; // 8-bit data
`ifdef	CT_SAFE
			ctdat_word <= { 4'h8, i_data[3:2], 2'b11, 24'h00 };
`else
			ctdat_word <= { i_data[7:0], 24'h00 };
`endif
			o_xip <= i_data[3];
			end
		5'b1000?: begin // Read EV-Config register
			ctcmd_word[31:24] <= 8'h65;
			end
		5'b1001?: begin // Write EV-Config register (Requires WEL)
			ctcmd_word[31:24] <= 8'h61;
			// o_quad <= (~i_data[7]);
`ifdef	CT_SAFE
			ctdat_word <= { 1'b1, 3'h5, 4'hf, 24'h00 };
`else
			ctdat_word <= { i_data[7:0], 24'h00 };
`endif
			end
		5'b1010?: begin // Read Lock register
			ctcmd_word[31:0] <= { 8'he8,  i_sector_address, 2'b00 };
			ctcmd_len <= 2'b11;
			ctdat_wr  <= 1'b0;  // Read, not write
			end
		5'b1011?: begin // Write Lock register (Requires WEL)
			ctcmd_word[31:0] <= { 8'he5, i_sector_address, 2'b00 };
			ctcmd_len <= 2'b11;
			ctdat_wr  <= 1'b1;  // Write
			end
		5'b1100?: begin // Read Flag Status register
			ctcmd_word[31:24] <= 8'h70;
			ctdat_wr  <= 1'b0;  // Read, not write
			end
		5'b1101?: begin // Write/Clear Flag Status register (No WEL required)
			ctcmd_word[31:24] <= 8'h50;
			ctdat_skip <= 1'b1;
			end
		default: begin // Default to reading the status register
			ctcmd_word[31:24] <= 8'h05;
			ctdat_wr  <= 1'b0;  // Read, not write
			r_ctdat_len <= 1'b0; // 8-bit data
			end
		endcase
	end

	assign	o_quad = 1'b1;

	reg	nxt_data_ack;

	// Second step, actually drive the state machine
	initial	ctstate = `CT_IDLE;
	always @(posedge i_clk)
	begin
		o_spi_wr <= 1'b1;
		o_bus_ack <= 1'b0;
		o_data_ack <= 1'b0;
		invalid_ack_pipe <= { invalid_ack_pipe[2:0], accepted };
		if (i_spi_valid)
			o_data <= i_spi_data;
		case(ctstate)
		`CT_IDLE: begin
			o_spi_req <= 1'b0;
			o_spi_wr  <= 1'b0;
			if (i_req) // Need a clock to let the digestion
				ctstate <= `CT_NEXT; // process complete
			end
		`CT_NEXT: begin
			o_spi_wr <= 1'b1;
			o_spi_req <= 1'b1;
			o_spi_word <= ctcmd_word;
			o_spi_len <= ctcmd_len;
			o_spi_dir <= 1'b0; // Write
			if (accepted)
			begin
				ctstate <= (ctdat_skip)?`CT_WAIT_FOR_IDLE:`CT_DATA;
				o_bus_ack <= (ctdat_skip);
				o_data_ack <= (ctdat_skip)&&(ctbus_ack);
			end end
		`CT_GRANTED: begin
			o_spi_wr <= 1'b1;
			if ((accepted)&&(ctdat_skip))
				ctstate <= `CT_WAIT_FOR_IDLE;
			else if (accepted)//&&(~ctdat_skip)
				ctstate <= `CT_DATA;
			end
		`CT_DATA: begin
			o_spi_wr   <= 1'b1;
			o_spi_len  <= ctdat_len;
			o_spi_dir  <= ~ctdat_wr;
			o_spi_word <= ctdat_word;
			if (accepted)
				o_bus_ack <= 1'b1;
			if (accepted)
				ctstate <= (ctdat_wr)?`CT_WAIT_FOR_IDLE:`CT_READ_DATA;
			if ((accepted)&&(ctdat_wr))
				o_data_ack <= 1'b1;
			first_valid <= 1'b0;
			end
		`CT_READ_DATA: begin
			o_spi_wr <= 1'b0; // No more words to go, just to wait
			o_spi_req <= 1'b1;
			invalid_ack_pipe[0] <= 1'b0;
			if ((i_spi_valid)&&(!invalid_ack_pipe[3])) // for a value to read
			begin
				o_data_ack <= 1'b1;
				o_data <= i_spi_data;
				ctstate <= `CT_WAIT_FOR_IDLE;
			end end
		default: begin // `CT_WAIT_FOR_IDLE
			o_spi_wr <= 1'b0;
			o_spi_req <= 1'b0;
			if (i_spi_stopped)
				ctstate <= `CT_IDLE;
			end
		endcase
	end
		
	// All of this is done in straight SPI mode, so our speed will always be zero
	assign	o_spi_hold = 1'b0;
	assign	o_spi_spd  = 1'b0;

endmodule

`define	ID_IDLE				5'h00
`define	ID_WAIT_ON_START_ID		5'h01
`define	ID_WAIT_ON_START_OTP		5'h02
`define	ID_WAIT_ON_START_OTP_WRITE	5'h03
`define	ID_READ_DATA_COMMAND		5'h04
`define	ID_GET_DATA			5'h05
`define	ID_LOADED			5'h06
`define	ID_LOADED_NEXT			5'h07
`define	ID_OTP_SEND_DUMMY		5'h08
`define	ID_OTP_CLEAR			5'h09
`define	ID_OTP_GET_DATA			5'h0a
`define	ID_OTP_WRITE			5'h0b
`define	ID_WAIT_ON_STOP			5'h0c
`define	ID_REQ_STATUS			5'h0d
`define	ID_REQ_STATUS_NEXT		5'h0e
`define	ID_READ_STATUS			5'h0f
//
`define	ID_FINAL_STOP			5'h10

module	idotpqspi(i_clk, i_req, i_wr, i_pipewr, i_addr, i_data, o_bus_ack,
		o_qspi_req, i_qspi_grant,
		o_spi_wr, o_spi_hold, o_spi_word, o_spi_len,
		o_spi_spd, o_spi_dir, i_spi_data, i_spi_valid,
		i_spi_busy, i_spi_stopped, o_data_ack, o_data, o_loaded,
		o_wip);
	input			i_clk;
	input			i_req, i_wr, i_pipewr;
	input		[4:0]	i_addr;
	input		[31:0]	i_data;
	output	reg		o_bus_ack, o_qspi_req;
	input			i_qspi_grant;
	output	reg		o_spi_wr, o_spi_hold;
	output	reg	[31:0]	o_spi_word;
	output	reg	[1:0]	o_spi_len;
	output	wire		o_spi_spd;
	output	reg		o_spi_dir;
	input		[31:0]	i_spi_data;
	input			i_spi_valid, i_spi_busy, i_spi_stopped;
	output	reg		o_data_ack;
	output	reg	[31:0]	o_data;
	output	wire		o_loaded;
	output	reg		o_wip;

	reg	id_loaded;
	initial	id_loaded = 1'b0;
	assign	o_loaded= id_loaded;

/*	
	// Only the ID register will be kept in memory, OTP will be read
	// or written upon request
	always @(posedge i_clk)
		if (i_addr[4])
			o_data <= otpmem[i_addr[3:0]];
		else
			o_data <= idmem[i_addr[2:0]];

	always @(posedge i_clk)
		if ((otp_loaded)&&(i_req)&&(i_addr[4]))
			o_data_ack <= 1'b1;
		else if ((id_loaded)&&(i_req)&&(~i_addr[4]))
			o_data_ack <= idmem[i_addr[2:0]];
		else
			o_data_ack <= 1'b0;
*/

	reg	otp_read_request, id_read_request, accepted, otp_wr_request,
		id_read_device, last_id_read;
	reg	[4:0]	req_addr;
	reg	[2:0]	lcl_id_addr;
	reg	[4:0]	id_state;
	always @(posedge i_clk)
	begin
		otp_read_request <= (i_req)&&(~i_wr)&&((i_addr[4])||(i_addr[3:0]==4'hf));
		last_id_read     <= (i_req)&&(~i_addr[4])&&(i_addr[3:0]!=4'hf);
		id_read_request  <= (i_req)&&(~i_addr[4])&&(i_addr[3:0]!=4'hf)&&(~last_id_read);
		id_read_device   <= (i_req)&&(~i_addr[4])&&(i_addr[3:0]!=4'hf)&&(~id_loaded);
		accepted <= (~i_spi_busy)&&(i_qspi_grant)&&(o_spi_wr)&&(~accepted);

		otp_wr_request <= (i_req)&&(i_wr)&&((i_addr[4])||(i_addr[3:0]==4'hf));

		if (id_state == `ID_IDLE)
			req_addr <= (i_addr[4:0]==5'h0f) ? 5'h10
				: { 1'b0, i_addr[3:0] };
	end

	reg	last_addr;
	always @(posedge i_clk)
		last_addr <= (lcl_id_addr >= 3'h4);

	reg	[31:0]	idmem[0:5];
	reg	[31:0]	r_data;

	// Now, quickly, let's deal with the fact that the data from the
	// bus comes one clock later ...
	reg	nxt_data_ack, nxt_data_spi;
	reg	[31:0]	nxt_data;

	reg	set_val, chk_wip, first_valid;
	reg	[2:0]	set_addr;
	reg	[3:0]	invalid_ack_pipe;

	always @(posedge i_clk)
	begin // Depends upon state[4], otp_rd, otp_wr, otp_pipe, id_req, accepted, last_addr
		o_bus_ack <= 1'b0;
		// o_data_ack <= 1'b0;
		o_spi_hold <= 1'b0;
		nxt_data_ack <= 1'b0;
		nxt_data_spi <= 1'b0;
		chk_wip      <= 1'b0;
		set_val <= 1'b0;
		invalid_ack_pipe <= { invalid_ack_pipe[2:0], accepted };
		if ((id_loaded)&&(id_read_request))
		begin
			nxt_data_ack <= 1'b1;
			o_bus_ack  <= 1'b1;
		end
		nxt_data <= idmem[i_addr[2:0]];
		o_spi_wr <= 1'b0; // By default, we send nothing
		case(id_state)
		`ID_IDLE: begin
			o_qspi_req <= 1'b0;
			o_spi_dir <= 1'b0; // Write to SPI
			lcl_id_addr <= 3'h0;
			o_spi_word[23:7] <= 17'h00;
			o_spi_word[6:0] <= { req_addr[4:0], 2'b00 };
			r_data <= i_data;
			o_wip <= 1'b0;
			first_valid <= 1'b0;
			if (otp_read_request)
			begin
				// o_spi_word <= { 8'h48, 8'h00, 8'h00, 8'h00 };
				id_state <= `ID_WAIT_ON_START_OTP;
				o_bus_ack <= 1'b1;
			end else if (otp_wr_request)
			begin
				o_bus_ack <= 1'b1;
				// o_data_ack <= 1'b1;
				nxt_data_ack <= 1'b1;
				id_state <= `ID_WAIT_ON_START_OTP_WRITE;
			end else if (id_read_device)
			begin
				id_state <= `ID_WAIT_ON_START_ID;
				o_bus_ack <= 1'b0;
				o_spi_word[31:24] <= 8'h9f;
			end end
		`ID_WAIT_ON_START_ID: begin
			o_spi_wr <= 1'b1;
			o_qspi_req <= 1'b1;
			o_spi_len <= 2'b0; // 8 bits
			if (accepted)
				id_state <= `ID_READ_DATA_COMMAND;
			end
		`ID_WAIT_ON_START_OTP: begin
			o_spi_wr <= 1'b1;
			o_spi_word[31:24] <= 8'h4B;
			o_qspi_req <= 1'b1;
			o_spi_len <= 2'b11; // 32 bits
			o_spi_word[6:0] <= { req_addr[4:0], 2'b00 };
			if (accepted) // Read OTP command was just sent
				id_state <= `ID_OTP_SEND_DUMMY;
			end
		`ID_WAIT_ON_START_OTP_WRITE: begin
			o_spi_wr <= 1'b1;
			o_qspi_req <= 1'b1;
			o_wip <= 1'b1;
			o_spi_len <= 2'b11; // 32 bits
			o_spi_word[31:24] <= 8'h42;
			if (accepted) // Read OTP command was just sent
				id_state <= `ID_OTP_WRITE;
			end
		`ID_READ_DATA_COMMAND: begin
			o_spi_len <= 2'b11; // 32-bits
			o_spi_wr <= 1'b1; // Still transmitting
			o_spi_dir <= 1'b1; // Read from SPI
			o_qspi_req <= 1'b1;
			if (accepted)
				id_state <= `ID_GET_DATA;
			first_valid <= 1'b0;
			end
		`ID_GET_DATA: begin
			o_spi_len <= 2'b11; // 32-bits
			o_spi_wr <= (~last_addr); // Still transmitting
			o_spi_dir <= 1'b1; // Read from SPI
			o_qspi_req <= 1'b1;
			invalid_ack_pipe[0] <= 1'b0;
			if((i_spi_valid)&&(!invalid_ack_pipe[3]))
			begin
				set_val <= 1'b1;
				set_addr <= lcl_id_addr[2:0];
				// idmem[lcl_id_addr[2:0]] <= i_spi_data;
				lcl_id_addr <= lcl_id_addr + 3'h1;
				if (last_addr)
					id_state <= `ID_LOADED;
			end end
		`ID_LOADED: begin
			id_loaded <= 1'b1;
			o_bus_ack  <= 1'b1;
			o_spi_wr   <= 1'b0;
			nxt_data_ack <= 1'b1;
			id_state   <= `ID_LOADED_NEXT;
			end
		`ID_LOADED_NEXT: begin
			o_spi_len <= 2'b11; // 32-bits
			o_bus_ack  <= 1'b0;
			o_spi_wr   <= 1'b0;
			nxt_data_ack <= 1'b1;
			id_state   <= `ID_IDLE;
			end
		`ID_OTP_SEND_DUMMY: begin
			o_spi_len <= 2'b00; // 1 byte
			o_spi_wr  <= 1'b1; // Still writing
			o_spi_dir <= 1'b0; // Write to SPI
			if (accepted) // Wait for the command to be accepted
				id_state <= `ID_OTP_CLEAR;
			end
		`ID_OTP_CLEAR: begin
			o_spi_wr  <= 1'b1; // Still writing
			o_spi_dir <= 1'b1; // Read from SPI
			o_spi_len <= 2'b11; // Read 32 bits
			if (accepted)
				id_state <= `ID_OTP_GET_DATA;
			end
		`ID_OTP_GET_DATA: begin
			invalid_ack_pipe[0] <= 1'b0;
			if ((i_spi_valid)&&(!invalid_ack_pipe[3]))
			begin
				id_state <= `ID_FINAL_STOP;
				nxt_data_ack <= 1'b1;
				nxt_data_spi <= 1'b1;
			end end
		`ID_OTP_WRITE: begin
			o_spi_wr  <= 1'b1;
			o_spi_len <= 2'b11;
			o_spi_dir <= 1'b0; // Write to SPI
			o_spi_word <= r_data;
			// o_bus_ack  <= (otp_wr_request)&&(accepted)&&(i_pipewr);
			// o_data_ack <= (otp_wr_request)&&(accepted);
			if (accepted) // &&(~i_pipewr)
				id_state <= `ID_WAIT_ON_STOP;
			else if(accepted)
			begin
				o_spi_word <= i_data;
				r_data <= i_data;
			end end
		`ID_WAIT_ON_STOP: begin
			o_spi_wr <= 1'b0;
			if (i_spi_stopped)
				id_state <= `ID_REQ_STATUS;
			end
		`ID_REQ_STATUS: begin
			o_spi_wr <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_word[31:24] <= 8'h05;
			o_spi_dir <= 1'b0;
			o_spi_len <= 2'b00;
			if (accepted)
				id_state <= `ID_REQ_STATUS_NEXT;
			end
		`ID_REQ_STATUS_NEXT: begin
			o_spi_wr <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_dir <= 1'b1; // Read
			o_spi_len <= 2'b00; // 8 bits
			// o_spi_word <= dont care
			if (accepted)
				id_state <= `ID_READ_STATUS;
			end
		`ID_READ_STATUS: begin
			o_spi_wr <= 1'b1;
			o_spi_hold <= 1'b0;
			o_spi_dir <= 1'b1; // Read
			o_spi_len <= 2'b00; // 8 bits
			// o_spi_word <= dont care
			invalid_ack_pipe[0] <= 1'b0;
			if ((i_spi_valid)&&(~invalid_ack_pipe[3]))
				chk_wip <= 1'b1;
			if ((chk_wip)&&(~i_spi_data[0]))
			begin
				o_wip <= 1'b0;
				id_state <= `ID_FINAL_STOP;
			end end
		default: begin // ID_FINAL_STOP
			o_bus_ack <= 1'b0;
			nxt_data_ack <= 1'b0;
			o_qspi_req <= 1'b0;
			o_spi_wr <= 1'b0;
			o_spi_hold <= 1'b0;
			o_spi_dir <= 1'b1; // Read
			o_spi_len <= 2'b00; // 8 bits
			// o_spi_word <= dont care
			if (i_spi_stopped)
				id_state <= `ID_IDLE;
			end
		endcase
	end

	always @(posedge i_clk)
	begin
		if (nxt_data_ack)
			o_data <= (nxt_data_spi)?i_spi_data : nxt_data;
		o_data_ack <= nxt_data_ack;
	end

	always @(posedge i_clk)
		if (set_val)
			idmem[set_addr] <= i_spi_data;

	assign	o_spi_spd = 1'b0; // Slow, 1-bit at a time

endmodule



