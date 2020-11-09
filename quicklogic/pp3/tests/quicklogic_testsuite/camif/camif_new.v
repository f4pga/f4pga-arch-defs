// ************************************************************************
// *
// *    FILE:  camif.v
// *
// *    DESCRIPTION:  
// *                 
// *
// *    HISTORY:
// *            - 2012/02/28  Kai Wu      Initial coding
// *			-						  support 4 bursts per DMA
// *            - 						  Sync to nCS, state machine and clock counter
// *			-						  change FIFO pop control
// *			-						  add debug pixel counter
// *			-						  modified for 50MHz GPMC bus
// *			-						  modified fifo_rst
// *			-						  insert buffers to apt_din
// *			-						  insert buffers to apt_din
// ************************************************************************
`timescale 1ns/1ps

module top(
  sys_rst_n,
  
  pixelclk,
  frame_valid,
  line_valid,
  apt_din,
  
  gpmc_clk,
  gpmc_csn,
  gpmc_oen,
  gpmc_wen,
  gpmc_advn,
  gpmc_ad,
  gpmc_intr
);

    input   sys_rst_n;
    input   pixelclk;
    input   frame_valid;
    input   line_valid;
    input   [9:0] apt_din;
    input   gpmc_clk;
    input   gpmc_csn;
    input   gpmc_oen;
    input   gpmc_wen;
    input   gpmc_advn;
    inout   [15:0] gpmc_ad;
    output	gpmc_intr;
    
    wire pinclk;
    wire sys_rst, sft_rst;
    wire ntginclk, ginclknt;
    wire ginclk, ginclkn, nginclk;
    
    wire [3:0] push_flaga, pop_flaga;
    wire [3:0] push_flagb, pop_flagb;
    wire [15:0] pop_data, pop_datb;
    wire i_nad_cmb, i_nwe_cmb, i_noe_cmb;
    wire i_popa, i_popb;
    wire i_pusha, i_pushb, i_pusha0;
    wire fifo_fulln, fifo_fullnb, cs_rst;
    wire fifo_emptynb, atfullb, atfulla;
	wire pixelclk_int, pinclk_dl, i_oe;
    wire [15:0] i_rddata, gpmc_adin;
    reg  [2:0] rst_d;
    reg  rst, rst0, din_valid;
    reg  [15:0] push_data;
    reg  fv_int, fv_int2, lv_int, fifo_fullna;
    reg  fifo_emptyna, tflagc;
    reg  enrgb, gpmc_intr_reg, fifo_emptyc;
    reg  pixel_clk_sel, gpmc_clk_sel;
    reg  i_push, i_push2, i_pusha1, i_pushb1;
    reg	 i_oe_sync, i_pop;
    reg  i_we_sync, i_we_sync1, i_we_sync2, i_we_sync3;
    reg  i_oe_0, i_oe_1, i_oe_2, i_oe_p, i_oe_f, i_oe_f0,i_popa_l, i_popb_l;
    reg  [9:0] push_flagc, push_flagc2;
    reg  [9:0] din_int;
    reg  [3:0] dflagc;
    reg  [5:0] pop_flagc, dflagc1;
    reg  [7:0] push_data0;
    reg  [9:0] push_data1;
    reg  [15:0] i_rd_datp, push_datb, pop_datb_dl;
    reg  [15:0] rd_data, gpmc_addr;
    reg  [4:0] statusreg;
    reg	 ev_int, intr_en, atfullbn, i_rd_sync1;
	reg  [1:0] rd_flag;
	reg  sclrn, gpmc_intr_psync;
	reg  [3:0] next_state, state, scount;
	parameter  [3:0]  IDLE  = 4'b0001;
	parameter  [3:0]  WAIT  = 4'b0010;
	parameter  [3:0]  READ1  = 4'b0100;
	parameter  [3:0]  READ0  = 4'b1000;
	reg  [3:0] pixel_counter_l;
	reg  [5:0] pixel_counter_h;
	reg  cn_h_clrn, cn_l_clrn, pixel_error, pixel_cn_error, pixel_error_d;
	reg  [1:0] next_cnstate, cnstate;
	parameter  [1:0]  S0  = 2'b00;
	parameter  [1:0]  S1  = 2'b01;
	parameter  [1:0]  S2  = 2'b10;
	reg  [2:0] sintr;
	parameter  [2:0]  STI0  = 3'b000;
	parameter  [2:0]  STI1  = 3'b001;
	parameter  [2:0]  STI2  = 3'b010;
	parameter  [2:0]  STI3  = 3'b100;
	reg  [5:0] counter_out_l, counter_out;
	reg  fifo_rst, fifo_rst1, fifo_rst2, fifo_rst3;
	reg  intr_en1, intr_en2;
	reg  intr_en_sync0, intr_en_sync1, intr_en_sync2, intr_en_sync3;
	wire [9:0] apt_din_buf;
	wire frame_valid_buf, line_valid_buf;

// Begin Module

// quad_buff I30  ( .buffer_in(apt_din[0]) , .buffer_out(apt_din_buf[0]) );
// quad_buff I31  ( .buffer_in(apt_din[1]) , .buffer_out(apt_din_buf[1]) );
// quad_buff I32  ( .buffer_in(apt_din[2]) , .buffer_out(apt_din_buf[2]) );
// quad_buff I33  ( .buffer_in(apt_din[3]) , .buffer_out(apt_din_buf[3]) );
// quad_buff I34  ( .buffer_in(apt_din[4]) , .buffer_out(apt_din_buf[4]) );
// quad_buff I35  ( .buffer_in(apt_din[5]) , .buffer_out(apt_din_buf[5]) );
// quad_buff I36  ( .buffer_in(apt_din[6]) , .buffer_out(apt_din_buf[6]) );
// quad_buff I37  ( .buffer_in(apt_din[7]) , .buffer_out(apt_din_buf[7]) );
// quad_buff I38  ( .buffer_in(apt_din[8]) , .buffer_out(apt_din_buf[8]) );
// quad_buff I39  ( .buffer_in(apt_din[9]) , .buffer_out(apt_din_buf[9]) );
// quad_buff I40  ( .buffer_in(frame_valid) , .buffer_out(frame_valid_buf) );
// quad_buff I41  ( .buffer_in(line_valid) , .buffer_out(line_valid_buf) );

assign apt_din_buf = apt_din;
assign frame_valid_buf = frame_valid;
assign line_valid_buf = line_valid;

qhsckbuff pixclk_gbuf (
.A (pixelclk_int), 
.Z (pinclk)
);

qhsckbuff gpmcclk_gbuf (
.A (gpmc_clk), 
.Z (ginclk)
);

assign pinclk_dl = pixelclk;
assign pixelclk_int = (pixel_clk_sel)? ~pinclk_dl : pinclk_dl;
assign sys_rst = ~sys_rst_n;
assign sft_rst = sys_rst | ~statusreg[4];
assign i_noe_cmb = (gpmc_csn==1'b0)? gpmc_oen : 1'b1;
assign i_nwe_cmb = (gpmc_csn==1'b0)? gpmc_wen : 1'b1;
assign i_nad_cmb = (gpmc_csn==1'b0)? gpmc_advn : 1'b1;
assign i_pusha = i_pusha1 & fifo_fullna;
assign i_pushb = i_popa_l;
assign i_oe = ~i_noe_cmb & i_nad_cmb;

   always@( posedge ginclk or posedge sft_rst)
   begin
      if (sft_rst)
      begin
         rst_d			 <= 3'b0;
      end
      else
      begin
      	if (rst_d[2]&&rst_d[0])
         rst_d			 <= rst_d;
        else      	
         rst_d			 <= rst_d + 1;
      end
   end

   always@( posedge pinclk or posedge sft_rst)
   begin
      if (sft_rst)
      begin
         rst0			 <= 1'b1;
         rst			 <= 1'b1;
      end
      else
      begin
         rst0			 <= ~(rst_d[2]&rst_d[0]);
         rst			 <= rst0;
      end
   end

   always@( posedge pinclk or posedge sys_rst)
   begin
      if (sys_rst)
      begin
         fifo_rst1		     <= 1'b0;
         fifo_rst2		     <= 1'b0;
         fifo_rst3		     <= 1'b0;
         fifo_rst			 <= 1'b1;
      end
      else
      begin
         fifo_rst1			 <= ~statusreg[4];
         fifo_rst2		     <= fifo_rst1;
         fifo_rst3		     <= fifo_rst2;
         fifo_rst		     <= fifo_rst2 & (~fifo_rst3);
      end
   end
   
   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         ev_int			     <= 1'b0;
      end
      else
      begin
      	if (fv_int && !fv_int2)
         ev_int				 <= 1'b1;
        else
         ev_int				 <= ev_int;
      end
   end

   always@( posedge pinclk or posedge sys_rst)
   begin
      if (sys_rst)
      begin
         fv_int			     <= 1'b0;
         fv_int2		     <= 1'b0;
      end
      else
      begin
         fv_int				 <= frame_valid_buf;
         fv_int2		     <= fv_int;
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         lv_int				 <= 1'b0;
         din_int			 <= 10'b0;
      end
      else
      begin
         lv_int				 <= line_valid_buf;
         din_int			 <= apt_din_buf;
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         din_valid		     <= 1'b0;
         push_data			 <= 16'b0;
      end
      else
      begin
         din_valid		     <= fv_int & lv_int & ev_int;
      	 if (enrgb)
      	 begin
         push_data[15:8]	<= push_data0;
         push_data[7:0]	 	<= push_data1[9:2];
         end
         else begin
         push_data	 		<= {6'b0, push_data1[9:0]};
         end
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         i_push			     <= 1'b0;
         i_pusha1		     <= 1'b0;
         i_pushb1		     <= 1'b0;
         push_data0          <= 8'b0;
         push_data1          <= 10'b0;
      end
      else
      begin
      	 i_pusha1			 <= din_valid & (~enrgb | i_push);
      	 push_data0			 <= push_data1[9:2];
         push_data1	         <= din_int;
      	 if (din_valid)
      	 begin
         i_push				 <= ~i_push & enrgb;
         end
      end
   end

   always@( posedge ginclk or posedge sys_rst)
   begin
      if (sys_rst)
      begin
         i_we_sync			 <= 1'b0;
         i_we_sync1			 <= 1'b0;
         i_we_sync2			 <= 1'b0;
         i_we_sync3			 <= 1'b0;
         enrgb           	 <= 1'b0;
         pixel_clk_sel		 <= 1'b0;
         gpmc_clk_sel		 <= 1'b0;
         statusreg[4:3]		 <= 2'b0;
      end
      else
      begin
         i_we_sync			 <= ~i_nwe_cmb & i_nad_cmb & ~gpmc_addr[15];
         i_we_sync1			 <= i_we_sync;
         i_we_sync2			 <= i_we_sync1;
         i_we_sync3			 <= i_we_sync2;
      	 if (~i_we_sync3 && i_we_sync2 && i_we_sync1)
      	 begin
         enrgb			     <= gpmc_adin[15];
         pixel_clk_sel		 <= gpmc_adin[14];
         gpmc_clk_sel		 <= gpmc_adin[13];
         statusreg[4]		 <= gpmc_adin[12];
         statusreg[3]		 <= gpmc_adin[11];
         end
      end
   end
   
assign i_rddata = i_rd_datp;
assign i_popb = i_oe_sync;
gpad16 GPMCIP( .A2(i_rddata) , .EN(i_oe), .FFCLK(ginclk), .FFCLR(sys_rst), .Q(gpmc_adin), .P(gpmc_ad) );

   always@( posedge ginclk or posedge sys_rst)
   begin
      if (sys_rst)
      begin
         i_rd_datp           <= 16'b0;
      end
      else
      begin
      	 if (gpmc_addr[15])
      	 begin
         i_rd_datp	         <= pop_datb;
         end
         else
         begin
         i_rd_datp	         <= {enrgb, pixel_clk_sel, gpmc_clk_sel, statusreg, 8'h5};
         end
      end
   end

   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
         gpmc_addr           <= 16'b0;
      end
      else
      begin
      	 if (!i_nad_cmb)
      	 begin
         gpmc_addr	         <= gpmc_adin;
         end
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
      	sintr <= STI0;
      	intr_en_sync3 <= 1'b1;
      	gpmc_intr_psync	 <= 1'b0;
      end
      else
      begin
      	case (sintr)
      		STI0: begin
      			gpmc_intr_psync	 <= 1'b0;
      			if (gpmc_intr_reg)
      			begin
      			intr_en_sync3 <= 1'b0;
      			sintr <= STI1;
      			end
      			else begin
      			intr_en_sync3 <= 1'b1; 
      			sintr <= STI0;
      			end
      			end
      		STI1: begin
      			gpmc_intr_psync	 <= 1'b1;
      			if (intr_en_sync1^intr_en_sync2)
      			begin
      			intr_en_sync3 <= 1'b1;
      			sintr <= STI2;
      			end
      			else begin
      			intr_en_sync3 <= 1'b0;
      			sintr <= STI1;
      			end
      			end
      		STI2: begin
      			intr_en_sync3 <= 1'b1;
      			gpmc_intr_psync	 <= 1'b0;
      			if (!tflagc)
      			begin
      			sintr <= STI3;
      			end
      			else begin
      			sintr <= STI2;
      			end
      			end
      		STI3: begin
      			intr_en_sync3 <= 1'b1;
      			gpmc_intr_psync	 <= 1'b0;
      			sintr <= STI0;
      			end
      	default: sintr <= STI0;
      	endcase
      end
   end
      
   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         intr_en_sync0			 <= 1'b0;
         intr_en_sync1			 <= 1'b0;
         intr_en_sync2			 <= 1'b0;
         gpmc_intr_reg           <= 1'b0;
      end
      else
      begin
         intr_en_sync0			 <= intr_en2;
         intr_en_sync1			 <= intr_en_sync0;
         intr_en_sync2			 <= intr_en_sync1;
		if (intr_en) begin
		 if (statusreg[3])
         gpmc_intr_reg           <= |dflagc;
         else
         gpmc_intr_reg           <= |dflagc1;
        end
        else begin
         gpmc_intr_reg           <= 1'b0;    
        end    
      end
   end
   
   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         dflagc           <= 4'b0;
         dflagc1          <= 6'b0;
      end
      else
      begin
         if (!tflagc && intr_en_sync3)
         begin
         dflagc1	         <= push_flagc2[9:4] - pop_flagc;
         end
         else
         begin
         dflagc1           <= dflagc1;
         end
         if (!tflagc && intr_en_sync3)
         begin
         dflagc	         <= push_flagc2[9:6] - pop_flagc[3:0];
         end
         else
         begin
         dflagc           <= dflagc;
         end
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         i_oe_1			     <= 1'b0;
         i_oe_f				 <= 1'b0;
         i_oe_f0			 <= 1'b0;
         i_popa_l			 <= 1'b0;
      end
      else
      begin
         i_oe_f				 <= i_oe_1;
         i_oe_1				 <= i_oe_f0;
         i_oe_f0			 <= ~i_noe_cmb & i_nad_cmb & gpmc_addr[15];
         i_popa_l			 <= i_popa;
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         tflagc				 <= 1'b0;
         push_flagc			 <= 10'b0;
         push_flagc2		 <= 10'b0;
      end
      else
      begin
         if (i_popa_l)
         begin
         push_flagc			 <= push_flagc + 1;
         end
         if (!tflagc)
         begin
         push_flagc2		 <= push_flagc;
         end
         else begin
         push_flagc2		 <= push_flagc2;
         end
         tflagc				 <= ~tflagc;
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         statusreg[1]	     <= 1'b0;
      end
      else
      begin
      	if (statusreg[1])
      	begin
         statusreg[1]		 <= i_oe_2 | i_oe_0;
      	end
      	else begin
         statusreg[1]		 <= ~fifo_fullna & i_pusha1;
       	end
      end
   end

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         i_oe_p			     <= 1'b0;
         i_oe_0			     <= 1'b0;
         i_oe_2				 <= 1'b0;
      end
      else
      begin
         i_oe_2				 <= ~i_oe_0;
         i_oe_0				 <= i_oe_p;
         i_oe_p				 <= ~i_noe_cmb & i_nad_cmb & ~gpmc_addr[15];
      end
   end

   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
         rd_flag			 <= 2'b0;
         i_rd_sync1			 <= 1'b0;
         intr_en			 <= 1'b0;
      end
      else
      begin
         if (rd_flag == 2'b00)
         begin
         intr_en <= 1'b1;
         end
         else
         begin
         intr_en <= 1'b0;
         end
         i_rd_sync1	<= i_oe_sync;
         if (!statusreg[3])
         begin
         	rd_flag		<= 2'b00;
         end
         else
         begin
         	if (!i_rd_sync1 && i_oe_sync)
         	rd_flag		<= rd_flag + 1;
         	else  rd_flag	<= rd_flag;
         end
      end
   end
   
   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
         intr_en1			 <= 1'b0;
         intr_en2			 <= 1'b0;
         pop_flagc			 <= 6'b0;
      end
      else
      begin
         if (!i_rd_sync1 && i_oe_sync && ~(|rd_flag))
         begin
         intr_en1			 <= ~intr_en1;
         pop_flagc			 <= pop_flagc + 1;
         end
         else begin
         intr_en1			 <= intr_en1;
         pop_flagc			 <= pop_flagc;
         end
         intr_en2			 <= intr_en1;
      end
   end

      always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
         i_popb_l			 <= 1'b0;
      end
      else
      begin
         i_popb_l			 <= i_popb;
      end
   end

   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
         statusreg[0]		 <= 1'b1;
         statusreg[2]		 <= 1'b0;
      end
      else
      begin
         statusreg[0]		 <= ~(fifo_emptynb | pop_flagb[0]);
         statusreg[2]		 <= 1'b0;
      end
   end

   always@( posedge ginclk or negedge sclrn)
   begin
      if (!sclrn)
      begin
      	scount <= 4'b0;
      end
      else
      begin
      	scount <= scount + 1;
      end
   end

   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
      	fifo_emptyc <= 1'b0;
      end
      else
      begin
      	if (state == WAIT)
      		fifo_emptyc	<= ~(fifo_emptynb | pop_flagb[0]);
      end
   end

   always@( posedge ginclk or posedge rst)
   begin
      if (rst)
      begin
      	sclrn <= 1'b0;
      	state <= IDLE;
      	i_oe_sync <= 1'b0;
      end
      else
      begin
      	state <= next_state;
      	case (state)
      		IDLE: begin
      			i_oe_sync <= 1'b0;
      			if (!i_nad_cmb)
      			sclrn <= 1'b1;
      			else
      			sclrn <= 1'b0; 
      			end
      		WAIT: begin
      			if (scount == 4'h2) begin
      				i_oe_sync <= gpmc_addr[15];
      				sclrn <= 1'b0; 
      			end
      			else begin
      				i_oe_sync <= 1'b0;
      				sclrn <= 1'b1;
      			end
      			end
      		READ1: begin
      			if (scount == 4'he) begin
      				i_oe_sync <= 1'b0;
      				sclrn <= 1'b0;
      			end
      			else begin
      				i_oe_sync <= 1'b1;
      				sclrn <= 1'b1;
      			end
      			end
      		READ0: begin
      			i_oe_sync <= 1'b0;
      			if (scount == 4'h1)
      			sclrn <= 1'b0; 
      			else
      			sclrn <= 1'b1;
      			end
      	default: state <= IDLE;
      	endcase
      end
   end

  always@(state, gpmc_csn, i_noe_cmb, i_nad_cmb, scount, gpmc_addr[15])
  begin
  	next_state = IDLE;
  	case(state)
  		IDLE: begin
      		  if (!i_nad_cmb)
  				next_state = WAIT;
  			  else
  				next_state = IDLE;
  			end
  		WAIT: begin
  			  if(scount == 4'h2)
  			  begin
  			  	if (!i_noe_cmb) begin
  			  		if (gpmc_addr[15]) begin
  			  			next_state = READ1;
  			  		end
  			  		else next_state = READ0;
  			  	end
  			  	else next_state = IDLE;
  			  end
  			  else
  			  	next_state = WAIT;
  			 end
  		READ1: begin
  			  if(scount == 4'he)
  			  begin
  			  	next_state = IDLE;
  			  end
  			  else next_state = READ1;
  			 end
  		READ0: begin
  			  if(scount==4'h1)
  			  begin
  			  	next_state = IDLE;
  			  end
  			  else next_state = READ0;
  			 end
  		default: next_state = IDLE;
  	endcase
  end
            
  af512x16_512x16 DFIFOA (
    .DIN             (push_data),
    .Fifo_Push_Flush (fifo_rst),
    .Fifo_Pop_Flush  (1'b0),
    .PUSH            (i_pusha),
    .POP             (i_popa),
    .Push_Clk        (pinclk),
    .Pop_Clk         (pinclk),
	.Push_Clk_En	 (1'b1),
	.Pop_Clk_En		 (1'b1),
	.Push_Clk_Sel	 (1'b1),
	.Pop_Clk_Sel	 (1'b1),
	.Fifo_Dir		 (1'b0),
	.Async_Flush	 (1'b0),
	.Async_Flush_Sel (1'b0),
    .Almost_Full     (atfulla ),
    .Almost_Empty    ( ),
    .PUSH_FLAG       (push_flaga ),
    .POP_FLAG        (pop_flaga ),
    .DOUT            (pop_data)
    );
   
  af512x16_512x16 DFIFOB (
    .DIN             (push_datb),
    .Fifo_Push_Flush (fifo_rst),
    .Fifo_Pop_Flush  (1'b0),
    .PUSH            (i_pushb),
    .POP             (i_popb),
    .Push_Clk        (pinclk),
    .Pop_Clk         (ginclk),
	.Push_Clk_En	 (1'b1),
	.Pop_Clk_En		 (1'b1),
	.Push_Clk_Sel	 (1'b1),
	.Pop_Clk_Sel	 (1'b1),
	.Fifo_Dir		 (1'b0),
	.Async_Flush	 (1'b0),
	.Async_Flush_Sel (1'b0),
    .Almost_Full     (atfullb ),
    .Almost_Empty    ( ),
    .PUSH_FLAG       (push_flagb ),
    .POP_FLAG        (pop_flagb ),
    .DOUT            (pop_datb)
    );

assign gpmc_intr = gpmc_intr_psync; 
assign i_popa = fifo_emptyna & fifo_fullnb;
assign fifo_emptynb = |pop_flagb[3:1];
assign fifo_fullnb = (|push_flagb | atfullbn) & ~atfullb;

   always@( posedge pinclk or posedge rst)
   begin
      if (rst)
      begin
         fifo_emptyna		 <= 1'b0;
         fifo_fullna		 <= 1'b1;
         atfullbn			 <= 1'b0;
         push_datb			 <= 16'b0;
      end
      else
      begin
         fifo_emptyna		 <= (|pop_flaga[3:1])|(~fifo_emptyna &pop_flaga[0]);
         fifo_fullna		 <= |push_flaga & ~atfulla;
         atfullbn			 <= ~atfullb;
         push_datb			 <= pop_data;
      end
   end      
endmodule
`ifdef gpad16
`else
`define gpad16

module gpad16 ( A2 , EN, FFCLK, FFCLR, Q, P );

input [15:0] A2;
input EN;
input FFCLK /* synthesis syn_isclock=1 */;
input FFCLR;
output [15:0] Q;
inout [15:0] P;

supply1 VCC;

bipadoff I12  ( .A2(A2[0]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[0]) , .P(P[0]) );

bipadoff I13  ( .A2(A2[1]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[1]) , .P(P[1]) );

bipadoff I14  ( .A2(A2[2]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[2]) , .P(P[2]) );

bipadoff I15  ( .A2(A2[3]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[3]) , .P(P[3]) );

bipadoff I16  ( .A2(A2[4]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[4]) , .P(P[4]) );

bipadoff I17  ( .A2(A2[5]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[5]) , .P(P[5]) );

bipadoff I18  ( .A2(A2[6]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[6]) , .P(P[6]) );

bipadoff I19  ( .A2(A2[7]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[7]) , .P(P[7]) );

bipadoff I20  ( .A2(A2[11]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[11]) , .P(P[11]) );

bipadoff I21  ( .A2(A2[10]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[10]) , .P(P[10]) );

bipadoff I22  ( .A2(A2[9]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[9]) , .P(P[9]) );

bipadoff I23  ( .A2(A2[8]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[8]) , .P(P[8]) );

bipadoff I24  ( .A2(A2[12]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[12]) , .P(P[12]) );

bipadoff I25  ( .A2(A2[13]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[13]) , .P(P[13]) );

bipadoff I26  ( .A2(A2[14]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[14]) , .P(P[14]) );

bipadoff I27  ( .A2(A2[15]) , .EN(EN) , .FFCLK(FFCLK) , .FFCLR(FFCLR) , .O_FFEN(VCC),
               .Q(Q[15]) , .P(P[15]) );
endmodule
`endif


module bipadoff ( A2 , EN, FFCLK, FFCLR, O_FFEN, Q, P );

input A2, EN;
input FFCLK /* synthesis syn_isclock=1 */;
input FFCLR, O_FFEN;
inout P;
output Q;
wire temp;
reg Q;
supply1 VCC;
supply0 GND;

//-------------Code Starts Here---------
always @ ( posedge FFCLK or negedge FFCLR)
if (~FFCLR) begin
  Q <= 1'b0;
end  else begin
if (O_FFEN) begin 
  Q <= A2;
  end
end
assign P = EN ? A2 : 1'b1 ;
endmodule

module qhsckbuff (input A ,output Z );

assign Z= A;
endmodule