// -----------------------------------------------------------------------------
// title          : I2S Slave RX mode 
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_rx.v
// author         : Rakesh Moolacheri
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: I2S Slave RX mode
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author                        description
// 2017/03/23      1.0        Rakesh Moolacheri        created / Initial Release
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module i2s_slave_rx (

                WBs_CLK_i,
                WBs_RST_i,
				
				i2s_clk_i,  
				i2s_clk_o,
				i2s_ws_clk_i,    
				i2s_din_i,       

				I2S_S_EN_i,  
				i2s_dis_o,				

				data_left_o,     
				data_right_o,    

				push_left_o,     
				push_right_o    
				
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

input                    i2s_clk_i;
input                    i2s_ws_clk_i;
input                    i2s_din_i;

input                    I2S_S_EN_i;

output    		[15:0]   data_left_o;
output    		[15:0]   data_right_o;

output					 push_left_o; 
output					 push_right_o;

output					 i2s_clk_o;

output 					 i2s_dis_o;

wire                     WBs_CLK_i;
wire                     WBs_RST_i;

wire                     i2s_clk_i;
wire                     i2s_ws_clk_i;
wire                     i2s_din_i;

wire                    I2S_S_EN_i;

wire					 i2s_clk_o;

wire    		[15:0]   data_left_o;
wire    		[15:0]   data_right_o;

wire					 push_left_o; 
wire					 push_right_o;

reg            [15:0]     data_l_int;
reg            [15:0]     data_r_int;

wire                    i2s_clk_int; 
//wire                    i2s_clk_hyst;

reg                    i2s_ws_dl;
reg                    i2s_ws_d2;
reg                    i2s_dll;
reg                    i2s_dll_1,i2s_dll_2;//Anand

wire 				   rst;

reg            [4:0]     cnt_l;
reg            [4:0]     cnt_r; 

wire 				i2s_clk_edge;
//reg            [6:0]     time_cnt;
reg            [15:0]     time_cnt;
reg 					 i2s_dis_o;

reg 				i2s_clk_dl;
reg 				i2s_clk_d2;
reg 				i2s_clk_d3;

//-----Internal Signals--------------------



//------Logic Operations----------
//
assign i2s_clk_o = i2s_clk_int;

assign rst = WBs_RST_i | ~I2S_S_EN_i;

assign data_left_o  = data_l_int;
assign data_right_o = data_r_int;

assign push_left_o  =  i2s_ws_dl & ~i2s_ws_d2 & i2s_dll_2;
assign push_right_o = ~i2s_ws_dl &  i2s_ws_d2 & i2s_dll_2;

//hysteresis added to i2s input clock
/*
 hysteresis hys_inst(
     .sys_rst   (WBs_RST_i),
     .clk_in    (i2s_clk_i),
     .clk_out   (i2s_clk_hyst),
     .clk_en1   (I2S_S_EN_i),
     .clk_en2_n (~I2S_S_EN_i)
 );
 */
 
gclkbuff u_gclkbuff_i2s_clk ( .A(i2s_clk_i) , .Z(i2s_clk_int)); 
//assign i2s_clk_int = i2s_clk_i;

// Define the registers associated with the Command Queue Statemachine
//

always@( posedge i2s_clk_int or posedge rst)
begin
      if (rst)
      begin
         i2s_ws_dl           <= 1'b0;
		 i2s_ws_d2           <= 1'b0;
         i2s_dll             <= 1'b0;
         i2s_dll_1             <= 1'b0;
         i2s_dll_2             <= 1'b0;
      end
      else
      begin
      	 i2s_dll			 <= 1'b1;
		 i2s_dll_1           <= i2s_dll;
		 i2s_dll_2           <= i2s_dll_1;
         i2s_ws_dl           <= i2s_ws_clk_i;
		 i2s_ws_d2           <= i2s_ws_dl;
      end
end

always @(posedge i2s_clk_int or posedge rst)  
begin
    if (rst)
    begin
        cnt_r		<=  5'h0  ;
    end
    else 
    begin  
		if (push_right_o == 1'b1)
			cnt_r	<=  5'h0;
		else if (i2s_ws_dl == 1'b1 && i2s_dll_1 == 1'b1)
			cnt_r   <=  cnt_r + 1;
		else 
			cnt_r	<=  cnt_r ;
 	end
end 

always @(posedge i2s_clk_int or posedge rst)  
begin
    if (rst)
    begin
        cnt_l		<=  5'h0  ;
    end
    else 
    begin  
		if (push_left_o == 1'b1)
			cnt_l	<=  5'h0;
		else if (i2s_ws_dl == 1'b0 && i2s_dll_1 == 1'b1)
			cnt_l   <=  cnt_l + 1;
		else 
			cnt_l	<=  cnt_l ;
 	end
end 

always@( posedge i2s_clk_int or posedge rst)
begin
      if (rst)
      begin
         data_l_int           <= 16'b0;
      end
      else
      begin
	    if (i2s_ws_dl == 1'b0 && cnt_l[4] == 1'b0)
		  begin
				data_l_int[15:1] <= data_l_int[14:0];
				data_l_int[0]	 <= i2s_din_i;
		  end
		else 
		 begin
				data_l_int       <= data_l_int;
		 end
      end
end

always@( posedge i2s_clk_int or posedge rst)
begin
      if (rst)
      begin
         data_r_int           <= 16'b0;
      end
      else
      begin
	    if (i2s_ws_dl == 1'b1 && cnt_r[4] == 1'b0)
		  begin
				data_r_int[15:1] <= data_r_int[14:0];
				data_r_int[0]	 <= i2s_din_i;
		  end
		else 
		 begin
				data_r_int       <= data_r_int;
		 end
      end
end

// added for I2S disable interrupt
always@( posedge WBs_CLK_i or posedge rst)
begin
      if (rst)
      begin
         i2s_clk_dl           <= 1'b0;
		 i2s_clk_d2           <= 1'b0;
		 i2s_clk_d3           <= 1'b0;
      end
      else
      begin
         i2s_clk_dl           <= i2s_clk_i;
		 i2s_clk_d2           <= i2s_clk_dl;
		 i2s_clk_d3           <= i2s_clk_d2;
      end
end

assign i2s_clk_edge = i2s_clk_d2 ^ i2s_clk_d3;

always @(posedge WBs_CLK_i or posedge rst)  
begin
    if (rst)
    begin
        //time_cnt		<=  7'h0  ;
        time_cnt		<=  0  ;
    end
    else 
    begin  
		if (i2s_clk_edge == 1'b1)
			//time_cnt		<=  7'h0  ;
			time_cnt		<=  0  ;
		else 
			time_cnt        <=  time_cnt + 1;
 	end
end 

always @(posedge WBs_CLK_i or posedge WBs_RST_i)  
begin
    if (WBs_RST_i)
    begin
        i2s_dis_o		<=  1'h0  ;
    end
    else 
    begin  
		//if (time_cnt[6] == 1'b1)
		//if (time_cnt[15] == 1'b1)
		//if (time_cnt[8] == 1'b1)
		if (time_cnt[7] == 1'b1)
			i2s_dis_o		<=  1'h1  ;
		else 
			i2s_dis_o       <=  1'h0  ;
 	end
end 
   
endmodule
