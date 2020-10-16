`timescale 1ns/1ns
`ifdef FIFO
`else
`define FIFO

module FIFO(DIN,PUSH,POP,Fifo_Push_Flush,Fifo_Pop_Flush,Push_Clk,Pop_Clk,Push_Clk_En,Pop_Clk_En,PUSH_FLAG, POP_FLAG,Almost_Full,Almost_Empty,DOUT, Fifo_Dir, Async_Flush,Push_Clk_Sel,Pop_Clk_Sel, Async_Flush_Sel, LS, SD, DS, LS_RB1, SD_RB1, DS_RB1);

parameter wr_depth_int = 256,
	  rd_depth_int = 128,
	  wr_width_int = 9,
	  rd_width_int = 18,
	  reg_rd_int   = 0,
	  sync_fifo_int = 1;
	  
output [rd_width_int-1 :0] DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;
input PUSH,POP;
input Fifo_Push_Flush,Fifo_Pop_Flush;
input Pop_Clk /* synthesis syn_isclock = 1 */;
input Push_Clk/* synthesis syn_isclock = 1 */; 
input Pop_Clk_En,Push_Clk_En;
input [wr_width_int-1:0] DIN;
input Fifo_Dir, Async_Flush, Async_Flush_Sel;
input Pop_Clk_Sel,Push_Clk_Sel;
input LS, SD, DS, LS_RB1, SD_RB1, DS_RB1;

wire VCC,GND;
wire [1:0] WS1;
wire [1:0] WS2;
wire [10 :0] addr_wr,addr_rd;
wire [35:0] in_reg;
wire reg_rd,sync_fifo;
wire [35:0] out_reg;
wire clk1_sig, clk2_sig, clk1_sig_en, clk2_sig_en, fifo_clk1_flush_sig, fifo_clk2_flush_sig, p1_sig, p2_sig,clk1_sig_sel,clk2_sig_sel;

//parameter depth_level1 = 256;
//parameter depth_level2 = 512;
//parameter depth_level3 = 1024;

parameter depth_level1 = 512;
parameter depth_level2 = 1024;
parameter depth_level3 = 2048;


parameter mod2 =(wr_width_int)%2;
parameter mod4 =(wr_width_int)%4;

parameter zero_36_2= (36-wr_width_int) / 2;
parameter zero_36_2_odd=(36-wr_width_int+1)/2;
parameter zero_18_2_odd= (18-wr_width_int+1)/2;
parameter zero_36_4_1=(36-wr_width_int+1)/4;
parameter zero_36_4_2=(36-wr_width_int+2)/4;
parameter zero_36_4_3=(36-wr_width_int+3)/4;
parameter zero_36_4 = (36- wr_width_int) /4 ;
parameter zero_18_2=(18-wr_width_int)/2;
parameter by_2 = (wr_width_int)/2;
parameter by_4 = (wr_width_int)/4;
parameter by_4_2= (wr_width_int/4)*2;
parameter by_4_3=(wr_width_int/4)*3;
parameter zero_18_2_rg = 18-wr_width_int;
parameter zero_9_2_rg = 9-wr_width_int;
parameter by_2_read= (rd_width_int)/2;
parameter by_4_read = (rd_width_int)/4;
parameter by_4_readx2=(rd_width_int/4)*2;
parameter by_4_readx3=(rd_width_int/4)*3;

assign VCC = 1'b1;
assign GND = 1'b0;
assign reg_rd = reg_rd_int;
assign sync_fifo = sync_fifo_int;

generate
begin
	assign addr_wr=10'b0000000000;
	assign addr_rd=10'b0000000000;
end
endgenerate

assign clk1_sig = Fifo_Dir ? Pop_Clk : Push_Clk;
assign clk2_sig = Fifo_Dir ? Push_Clk : Pop_Clk ;
assign clk1_sig_en = Fifo_Dir ? Pop_Clk_En : Push_Clk_En;
assign clk2_sig_en = Fifo_Dir ? Push_Clk_En : Pop_Clk_En ;
assign clk1_sig_sel =  Push_Clk_Sel;
assign clk2_sig_sel=  Pop_Clk_Sel ;
assign fifo_clk1_flush_sig = Fifo_Dir ? Fifo_Pop_Flush : Fifo_Push_Flush;
assign fifo_clk2_flush_sig = Fifo_Dir ? Fifo_Push_Flush : Fifo_Pop_Flush ;
assign p1_sig = Fifo_Dir ? POP : PUSH;
assign p2_sig = Fifo_Dir ? PUSH : POP ;

generate 
//Generating data
if(wr_width_int == 1)
	begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[0]= DIN[0]; 
	end 
else if (wr_width_int ==36)
	assign in_reg[wr_width_int-1:0]=DIN;
else if (wr_width_int == 18 || wr_width_int ==9)
    begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=DIN;
	end
else if(wr_width_int ==35 || (wr_width_int ==17 && wr_depth_int ==depth_level2) ||(wr_width_int==17 && wr_depth_int ==depth_level1 && rd_depth_int != depth_level3) || (wr_width_int==8&&wr_depth_int==depth_level3) || (wr_width_int ==8 && wr_depth_int ==depth_level2 && rd_depth_int != depth_level3))
	begin
	assign in_reg[wr_width_int:wr_width_int]=0;				 
	assign in_reg[wr_width_int-1 :0]=DIN;
	end
else if(wr_width_int == rd_width_int)
begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int -1 :0]=DIN;
end
else if(wr_width_int ==34 && rd_depth_int ==depth_level3 ) 
	begin
	assign in_reg[35]=0;
	assign in_reg[26]=0;
	assign in_reg[34:27]=DIN[33:26];
	assign in_reg[25:18]=DIN[25:18];
	assign in_reg[17:0]=DIN[17:0];
	end
else if(wr_width_int ==33 && rd_depth_int ==depth_level3 )
	begin
	assign in_reg[35]=0;
	assign in_reg[26]=0;
	assign in_reg[17]=0;
	assign in_reg[34:27]=DIN[33:26];
	assign in_reg[25:18]=DIN[25:18];
	assign in_reg[16:0]=DIN[17:0];
	end
else if(wr_depth_int == depth_level1)
	begin
		if(rd_depth_int == depth_level2)
		begin
			if(wr_width_int > 18)
			begin
				if(mod2 ==0)
        			begin
				assign in_reg[17 : 18-zero_36_2]=0;
				assign in_reg[35 :  36-zero_36_2]=0  ;            
                        	assign in_reg[18-zero_36_2-1:0]=DIN[by_2-1:0] ;
                        	assign in_reg[36-zero_36_2-1:18]= DIN[wr_width_int-1:by_2];
                        	end
				else
				begin
				assign in_reg[35:36-zero_36_2_odd]=0;
				assign in_reg[17:18-zero_36_2_odd+1]=0;
				assign in_reg[36-zero_36_2_odd-1:18]=DIN[wr_width_int-1:by_2+1];
				assign in_reg[18-zero_36_2_odd:0]=DIN[by_2:0];
				end
			end
			else
				begin
				if(mod2==0)
				begin
				assign in_reg[8:9-zero_18_2]=0;
				assign in_reg[17: 18-zero_18_2]=0;
				assign in_reg[9-zero_18_2-1:0]=DIN[ by_2-1:0];
				assign in_reg[18-zero_18_2:9]=DIN[wr_width_int-1:by_2];
				end
				else
				begin
				assign in_reg[17:18-zero_18_2_odd]=0;
				assign in_reg[8:9-zero_18_2_odd+1]=0;
				assign in_reg[18-zero_18_2_odd-1:9]=DIN[wr_width_int-1:by_2+1];
				assign in_reg[9-zero_18_2_odd:0]=DIN[by_2:0];
				end
			end
			
		end
		else if(rd_depth_int == depth_level3 )
		begin
			if(mod4 == 0)
			begin
			assign in_reg[35:36-zero_36_4] = 0;
			assign in_reg[26:27- zero_36_4]=0;
			assign in_reg[17:18-zero_36_4]=0;
			assign in_reg[8:9-zero_36_4]=0;
			assign in_reg[36-zero_36_4-1:27]=DIN[wr_width_int-1:by_4_3];
			assign in_reg[27-zero_36_4-1:18]= DIN[by_4_3-1:by_4_2];
			assign in_reg[18-zero_36_4-1:9]=DIN[by_4_2-1:by_4];
			assign in_reg[9-zero_36_4-1:0]=DIN[by_4-1:0];
			end
			else if (mod4==1)
			begin
			assign in_reg[35:36-zero_36_4_3]=0;
			assign in_reg[26:27-zero_36_4_3]=0;
			assign in_reg[17:18-zero_36_4_3]=0;
			assign in_reg[8:9-zero_36_4_3+1]=0;
			assign in_reg[36-zero_36_4_3-1:27]=DIN[wr_width_int-1:by_4_3+1];
			assign in_reg[27-zero_36_4_3-1:18]=DIN[by_4_3:by_4_2+1];
			assign in_reg[18-zero_36_4_3-1:9]=DIN[by_4_2:by_4+1];
			assign in_reg[9-zero_36_4_3:0]=DIN[by_4:0];
			end
			else if (mod4==2)
			begin
			assign in_reg[35:36-zero_36_4_2]=0;
			assign in_reg[26:27-zero_36_4_2]=0;
			assign in_reg[17:18-zero_36_4_2+1]=0;
			assign in_reg[8:9-zero_36_4_2+1]=0;
			assign in_reg[36-zero_36_4_2-1:27]=DIN[wr_width_int-1:by_4_3+2];
			assign in_reg[27-zero_36_4_2-1:18]=DIN[by_4_3+1:by_4_2+2];
			assign in_reg[18-zero_36_4_2:9]=DIN[by_4_2+1:by_4+1];
			assign in_reg[9-zero_36_4_2:0]=DIN[by_4:0];
			end
			else if (mod4==3)
			begin
			assign in_reg[35:36-zero_36_4_1-1]=0;
			assign in_reg[26:27-zero_36_4_1]=0;
			assign in_reg[17:18-zero_36_4_1]=0;
			assign in_reg[8:9-zero_36_4_1]=0;
			assign in_reg[36-zero_36_4_1-2:27]=DIN[wr_width_int-1:by_4_3+3];
			assign in_reg[27-zero_36_4_1-1:18]=DIN[by_4_3+2:by_4_2+2];
			assign in_reg[18-zero_36_4_1-1:9]=DIN[by_4_2+1:by_4+1];
			assign in_reg[9-zero_36_4_1-1:0]=DIN[by_4:0];
			end
		end

	end
else if(wr_depth_int == depth_level2)
begin
	if(rd_depth_int == depth_level3)
		begin
		if(mod2==0)
		begin
		assign in_reg[8:9-zero_18_2]=0;
		assign in_reg[17: 18-zero_18_2]=0;
		assign in_reg[9-zero_18_2-1:0]=DIN[ by_2-1:0];
		assign in_reg[18-zero_18_2:9]=DIN[wr_width_int-1:by_2];
		end
		else
		begin
		assign in_reg[17:18-zero_18_2_odd]=0;
		assign in_reg[8:9-zero_18_2_odd+1]=0;
		assign in_reg[18-zero_18_2_odd-1:9]=DIN[wr_width_int-1:by_2+1];
		assign in_reg[9-zero_18_2_odd:0]=DIN[by_2:0];
		end
	end
	else
	begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=DIN;
	end
	
end
else
		
	begin 

	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=DIN;	
	end	
if(rd_depth_int == depth_level3 && wr_depth_int == depth_level1)
	assign WS1 =2'b10;
else if(rd_depth_int == depth_level3 && wr_depth_int == depth_level2)
	assign WS1=2'b01;
else if(wr_depth_int == depth_level1 && wr_width_int <=9)
	assign WS1=2'b01;
else if(wr_width_int <=9)
	assign WS1 = 2'b00;
else if(wr_width_int >9 && wr_width_int <=18)
	assign WS1 = 2'b01;
else if(wr_width_int > 18)
	assign WS1 = 2'b10;


if(wr_depth_int == depth_level3 && rd_depth_int == depth_level1)
	assign WS2 = 2'b10;
else if(wr_depth_int == depth_level3  && rd_depth_int == depth_level2)
	assign WS2 = 2'b01;
else if(rd_depth_int == depth_level1 && rd_width_int <=9)
	assign WS2 = 2'b01;
else if(rd_width_int <= 9)
	assign WS2 = 2'b00;
else if((rd_width_int >9) && (rd_width_int <= 18))
	assign WS2 = 2'b01;
else if(rd_width_int >18)
	assign WS2 = 2'b10;

if(((wr_width_int <=18 && wr_depth_int ==depth_level1) ||(wr_width_int <=9 && wr_depth_int==depth_level2)) && rd_depth_int !=depth_level3)


	ram8k_2x1_cell_macro U1 (.A1_0(addr_wr) , 
				 .A1_1(addr_wr), 
				 .A2_0(addr_rd), 
				 .A2_1(addr_rd), 
				 .ASYNC_FLUSH_0(Async_Flush), 
				 .ASYNC_FLUSH_1(GND),
				 .ASYNC_FLUSH_S0(Async_Flush_Sel), 
				 .ASYNC_FLUSH_S1(GND), 
				 .CLK1_0(clk1_sig), 
				 .CLK1_1(GND), 
				 .CLK1EN_0(clk1_sig_en), 
				 .CLK1EN_1(GND), 
				 .CLK2_0(clk2_sig),
				 .CLK2_1(GND), 
				 .CLK1S_0(clk1_sig_sel), 
				 .CLK1S_1(VCC), 
				 .CLK2S_0(clk2_sig_sel),
				 .CLK2S_1(VCC),
				 .CLK2EN_0(clk2_sig_en), 
				 .CLK2EN_1(GND), 
     			 .CONCAT_EN_0(GND),
				 .CONCAT_EN_1(GND), 
				 .CS1_0(fifo_clk1_flush_sig), 
				 .CS1_1(GND), 
				 .CS2_0(fifo_clk2_flush_sig), 
				 .CS2_1(GND), 
				 .DIR_0(Fifo_Dir),
				 .DIR_1(GND), 
				 .FIFO_EN_0(VCC), 
				 .FIFO_EN_1(GND), 
				 .P1_0(p1_sig), 
				 .P1_1(GND), 
				 .P2_0(p2_sig),
				 .P2_1(GND), 
				 .PIPELINE_RD_0(reg_rd), 
				 .PIPELINE_RD_1(GND), 
				 .SYNC_FIFO_0(sync_fifo),
				 .SYNC_FIFO_1(GND), 
				 .WD_1(in_reg[35:18]), 
				 .WD_0(in_reg[17:0]), 
				 .WIDTH_SELECT1_0(WS1), 
				 .WIDTH_SELECT1_1({GND,GND}), 
				 .WIDTH_SELECT2_0(WS2),
				 .WIDTH_SELECT2_1({GND,GND}), 
				  // PP-II doesn't use this signal
				 .WEN1_0({GND,GND}), 
				 .WEN1_1({GND,GND}), 
				 .Almost_Empty_0(Almost_Empty),
				 .Almost_Empty_1(), 
				 .Almost_Full_0(Almost_Full), 
				 .Almost_Full_1(),
				 .POP_FLAG_0(POP_FLAG), 
				 .POP_FLAG_1(), 
				 .PUSH_FLAG_0(PUSH_FLAG), 
				 .PUSH_FLAG_1(),
				 .RD_0(out_reg[17:0]), 
				 .RD_1(out_reg[35:18]),
				 .SD(SD),
				 .SD_RB1(SD_RB1),
				 .LS(LS),
				 .LS_RB1(LS_RB1),
				 .DS(DS),
				 .DS_RB1(DS_RB1),
				 .TEST1A(GND),
				 .TEST1B(GND),
				 .RMA(4'd0),
				 .RMB(4'd0),
				 .RMEA(GND),
				 .RMEB(GND));				
	

if((wr_width_int >18 && wr_depth_int ==depth_level1) || (wr_width_int > 9 && wr_depth_int==depth_level2) || wr_depth_int >depth_level2 || rd_depth_int == depth_level3)
	
	
	ram8k_2x1_cell_macro U2 (.A1_0(addr_wr) , 
				 .A1_1(addr_wr), 
				 .A2_0(addr_rd), 
				 .A2_1(addr_rd), 
				 .ASYNC_FLUSH_0(Async_Flush), 
				 //todo: should it be same as Async_Flush
				 //or GND ?
				 .ASYNC_FLUSH_1(GND),
				 .ASYNC_FLUSH_S0(Async_Flush_Sel), 
				 .ASYNC_FLUSH_S1(Async_Flush_Sel),
				 .CLK1_0(clk1_sig), 
				 .CLK1_1(clk1_sig), 
				 .CLK1EN_0(clk1_sig_en), 
				 .CLK1EN_1(clk1_sig_en), 
				 .CLK2_0(clk2_sig),
				 .CLK2_1(clk2_sig), 
				 .CLK1S_0(clk1_sig_sel), 
				 .CLK1S_1(clk1_sig_sel), 
				 .CLK2S_0(clk2_sig_sel),
				 .CLK2S_1(clk2_sig_sel),
				 .CLK2EN_0(clk2_sig_en), 
				 .CLK2EN_1(clk2_sig_en), 
				 .CONCAT_EN_0(VCC),
				 .CONCAT_EN_1(GND), 
				 .CS1_0(fifo_clk1_flush_sig), 
				 .CS1_1(GND), 
				 .CS2_0(fifo_clk2_flush_sig), 
				 .CS2_1(GND), 
				 .DIR_0(Fifo_Dir),
				 //todo: should it be same as Fifo_Dir or
				 //GND ?
				 .DIR_1(GND), 
				 .FIFO_EN_0(VCC), 
				 .FIFO_EN_1(GND), 
				 .P1_0(p1_sig), 
				 .P1_1(GND), 
				 .P2_0(p2_sig),
				 .P2_1(GND), 
				 .PIPELINE_RD_0(reg_rd), 
				 .PIPELINE_RD_1(GND), 
				 .SYNC_FIFO_0(sync_fifo),
				 .SYNC_FIFO_1(GND), 
				 .WD_1(in_reg[35:18]), 
				 .WD_0(in_reg[17:0]), 
				 .WIDTH_SELECT1_0(WS1), 
				 .WIDTH_SELECT1_1({GND,GND}), 
				 .WIDTH_SELECT2_0(WS2),
				 .WIDTH_SELECT2_1({GND,GND}), 
				  // PP-II doesn't use this signal
				 .WEN1_0({GND,GND}), 
				 .WEN1_1({GND,GND}), 
				 .Almost_Empty_0(Almost_Empty),
				 .Almost_Empty_1(), 
				 .Almost_Full_0(Almost_Full), 
				 .Almost_Full_1(),
				 .POP_FLAG_0(POP_FLAG), 
				 .POP_FLAG_1(), 
				 .PUSH_FLAG_0(PUSH_FLAG), 
				 .PUSH_FLAG_1(),
				 .RD_0(out_reg[17:0]), 
				 .RD_1(out_reg[35:18]),
				 .SD(SD),
				 .SD_RB1(SD_RB1),
				 .LS(LS),
				 .LS_RB1(LS_RB1),
				 .DS(DS),
				 .DS_RB1(DS_RB1),
				 .TEST1A(GND),
				 .TEST1B(GND),
				 .RMA(4'd0),
				 .RMB(4'd0),
				 .RMEA(GND),
				 .RMEB(GND));				 
	
endgenerate

generate

if(wr_width_int == rd_width_int)
assign DOUT[rd_width_int -1 :0]= out_reg[rd_width_int -1 :0];
else if(wr_depth_int == depth_level2 && wr_width_int > 9)
begin
	if(rd_width_int >18)
	begin
		assign DOUT[rd_width_int -1: by_2_read]=out_reg[35- zero_18_2_rg:18];
		assign DOUT[by_2_read-1 : 0]= out_reg[17-zero_18_2_rg: 0];
        end
	else if(rd_width_int <=9)
		assign DOUT[rd_width_int - 1:0]=out_reg[rd_width_int-1:0];
	else 
	begin
		assign DOUT[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign DOUT[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
	end
end	
else if(wr_depth_int ==depth_level2 && wr_width_int <=9 )
	begin
		assign DOUT[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign DOUT[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
	end

else if(wr_depth_int == depth_level3) 
begin
	if(rd_depth_int == depth_level1)
	begin
		assign DOUT[rd_width_int -1 :by_4_readx3 ]= out_reg[35-zero_9_2_rg:27];
		assign DOUT[by_4_readx3-1: by_4_readx2]=out_reg[26-zero_9_2_rg:18];
		assign DOUT[by_4_readx2-1: by_4_read]=out_reg[17-zero_9_2_rg:9];
		assign DOUT[by_4_read-1: 0]=out_reg[8-zero_9_2_rg:0];
	end	
	else
		begin
		assign DOUT[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign DOUT[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
		end
end
else                  
assign DOUT[rd_width_int-1:0] = out_reg[rd_width_int-1:0];
endgenerate



endmodule //FIFO
`endif


