`timescale 1ns/1ns
`ifdef RAM_RW
`else
`define RAM_RW

module RAM_RW(WA,RA,WD,WD_SEL,RD_SEL,WClk,RClk,WClk_En,RClk_En,WEN,RD,WClk_Sel,RClk_Sel,LS,SD,DS,LS_RB1,SD_RB1,DS_RB1); 

parameter 	        wr_addr_int = 10,
	 	        rd_addr_int = 9,
	  		wr_depth_int = 1024,
	  		rd_depth_int =512,
	  		wr_width_int =9,
	  		rd_width_int =18,
                        wr_enable_int =4,
	  		reg_rd_int = 0;



output [rd_width_int-1:0] RD;
input  [wr_width_int-1:0] WD;
input  [wr_addr_int-1:0]  WA;
input  [rd_addr_int-1:0]  RA;
input [wr_enable_int-1:0] WEN;
input WD_SEL,RD_SEL;
input WClk /* synthesis syn_isclock = 1 */; 
input RClk /* synthesis syn_isclock = 1 */;
input WClk_En,RClk_En;
input WClk_Sel,RClk_Sel;
input LS,SD,DS,LS_RB1,SD_RB1,DS_RB1;

//parameter depth_level1 = is_2k_int ? 128 : 256;
//parameter depth_level2 = is_2k_int ? 256 : 512;
//parameter depth_level3 = is_2k_int ? 512 : 1024;

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

wire VCC,GND;
//wire [1:0] WS1,WS2,WEN2,WEN1;
wire [1:0] WS1,WS2, WS_GND, WEN2, WEN1;
wire [10:0] addr_wr0,addr_rd0,addr_wr1,addr_rd1;
wire [35:0] in_reg;
wire [4:0] wen_reg;
wire reg_rd;
wire [35:0] out_reg;

assign VCC =1'b1;
assign GND = 1'b0;
assign reg_rd =reg_rd_int; 
assign WS_GND=2'b00;

//Generating write enable

assign wen_reg[4:wr_enable_int]=0;
assign wen_reg[wr_enable_int-1:0]=WEN;


generate 

//if (wr_enable_int < 4) 
//begin
//   assign wen_reg[3:wr_enable_int]=0;
//end

//Generating write address
if(wr_addr_int == 11)
	begin
	assign addr_wr0[10:0]=WA;
	assign addr_wr1=11'b0000000000;
	end
else
	begin
	assign addr_wr0[10:wr_addr_int]=0;
	assign addr_wr0[wr_addr_int-1:0]=WA;
	assign addr_wr1=11'b0000000000;
	end

//Generating read address
if(rd_addr_int == 11)
	begin
	assign addr_rd0[10 :0]=RA;
	assign addr_rd1=11'b0000000000;
	end
else
	begin
	assign addr_rd0[10 :rd_addr_int]=0;
	assign addr_rd0[rd_addr_int-1:0]=RA;
	assign addr_rd1=11'b0000000000;
	end

/*if (is_2k_int == 1 )
begin
	assign addr_wr1=9'b000000000;
	assign addr_rd1=9'b000000000;
end
else
begin
	assign addr_wr1=10'b0000000000;
	assign addr_rd1=10'b0000000000;
end


*/
//Generating data
if(wr_width_int == 1)
	begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[0]=WD[0];
	end

else if (wr_width_int ==36 || wr_width_int == 18 || wr_width_int ==9)
    begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=WD;
	end
else if(wr_width_int ==35 || (wr_width_int ==17 && wr_depth_int ==1024) ||(wr_width_int==17 && wr_depth_int ==512 && rd_depth_int != 2048) || (wr_width_int==8&&wr_depth_int==2048) || (wr_width_int ==8 && wr_depth_int ==1024 && rd_depth_int != 2048))
	begin
	assign in_reg[35:wr_width_int]=0;				 
	assign in_reg[wr_width_int-1 :0]=WD;
	end
else if(wr_width_int == rd_width_int)
begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int -1 :0]=WD;
end
else if(wr_width_int ==34 && rd_depth_int ==2048 ) 
	begin
	assign in_reg[35]=0;
	assign in_reg[26]=0;
	assign in_reg[34:27]=WD[33:26];
	assign in_reg[25:18]=WD[25:18];
	assign in_reg[17:0]=WD[17:0];
	end
else if(wr_width_int ==33 && rd_depth_int == 2048 )
	begin
	assign in_reg[35]=0;
	assign in_reg[26]=0;
	assign in_reg[17]=0;
	assign in_reg[34:27]=WD[33:26];
	assign in_reg[25:18]=WD[25:18];
	assign in_reg[16:0]=WD[17:0];
	end
else if(wr_depth_int == 512)
	begin
		if(rd_depth_int == 1024)
		begin
			if(wr_width_int > 18)
			begin
				if(mod2 ==0)
        			begin
				assign in_reg[17 : 18-zero_36_2]=0;
				assign in_reg[35 :  36-zero_36_2]=0  ;            
                        	assign in_reg[18-zero_36_2-1:0]=WD[by_2-1:0] ;
                        	assign in_reg[36-zero_36_2-1:18]= WD[wr_width_int-1:by_2];
                        	end
				else
				begin
				assign in_reg[35:36-zero_36_2_odd]=0;
				assign in_reg[17:18-zero_36_2_odd+1]=0;
				assign in_reg[36-zero_36_2_odd-1:18]=WD[wr_width_int-1:by_2+1];
				assign in_reg[18-zero_36_2_odd:0]=WD[by_2:0];
				end
			end
			else
				begin
				if(mod2==0)
				begin
				assign in_reg[8:9-zero_18_2]=0;
				assign in_reg[17: 18-zero_18_2]=0;
				assign in_reg[9-zero_18_2-1:0]=WD[ by_2-1:0];
				assign in_reg[18-zero_18_2:9]=WD[wr_width_int-1:by_2];
				end
				else
				begin
				assign in_reg[17:18-zero_18_2_odd]=0;
				assign in_reg[8:9-zero_18_2_odd+1]=0;
				assign in_reg[18-zero_18_2_odd-1:9]=WD[wr_width_int-1:by_2+1];
				assign in_reg[9-zero_18_2_odd:0]=WD[by_2:0];
				end
			end
			
		end
		else if(rd_depth_int == 2048 )
		begin
			if(mod4 == 0)
			begin
			assign in_reg[35:36-zero_36_4] = 0;
			assign in_reg[26:27- zero_36_4]=0;
			assign in_reg[17:18-zero_36_4]=0;
			assign in_reg[8:9-zero_36_4]=0;
			assign in_reg[36-zero_36_4-1:27]=WD[wr_width_int-1:by_4_3];
			assign in_reg[27-zero_36_4-1:18]= WD[by_4_3-1:by_4_2];
			assign in_reg[18-zero_36_4-1:9]=WD[by_4_2-1:by_4];
			assign in_reg[9-zero_36_4-1:0]=WD[by_4-1:0];
			end
			else if (mod4==1)
			begin
			assign in_reg[35:36-zero_36_4_3]=0;
			assign in_reg[26:27-zero_36_4_3]=0;
			assign in_reg[17:18-zero_36_4_3]=0;
			assign in_reg[8:9-zero_36_4_3+1]=0;
			assign in_reg[36-zero_36_4_3-1:27]=WD[wr_width_int-1:by_4_3+1];
			assign in_reg[27-zero_36_4_3-1:18]=WD[by_4_3:by_4_2+1];
			assign in_reg[18-zero_36_4_3-1:9]=WD[by_4_2:by_4+1];
			assign in_reg[9-zero_36_4_3:0]=WD[by_4:0];
			end
			else if (mod4==2)
			begin
			assign in_reg[35:36-zero_36_4_2]=0;
			assign in_reg[26:27-zero_36_4_2]=0;
			assign in_reg[17:18-zero_36_4_2+1]=0;
			assign in_reg[8:9-zero_36_4_2+1]=0;
			assign in_reg[36-zero_36_4_2-1:27]=WD[wr_width_int-1:by_4_3+2];
			assign in_reg[27-zero_36_4_2-1:18]=WD[by_4_3+1:by_4_2+2];
			assign in_reg[18-zero_36_4_2:9]=WD[by_4_2+1:by_4+1];
			assign in_reg[9-zero_36_4_2:0]=WD[by_4:0];
			end
			else if (mod4==3)
			begin
			assign in_reg[35:36-zero_36_4_1-1]=0;
			assign in_reg[26:27-zero_36_4_1]=0;
			assign in_reg[17:18-zero_36_4_1]=0;
			assign in_reg[8:9-zero_36_4_1]=0;
			assign in_reg[36-zero_36_4_1-2:27]=WD[wr_width_int-1:by_4_3+3];
			assign in_reg[27-zero_36_4_1-1:18]=WD[by_4_3+2:by_4_2+2];
			assign in_reg[18-zero_36_4_1-1:9]=WD[by_4_2+1:by_4+1];
			assign in_reg[9-zero_36_4_1-1:0]=WD[by_4:0];
			end
		end

	end
else if(wr_depth_int == 1024)
begin
	if(rd_depth_int == 2048)
		begin
		if(mod2==0)
		begin
		assign in_reg[8:9-zero_18_2]=0;
		assign in_reg[17: 18-zero_18_2]=0;
		assign in_reg[9-zero_18_2-1:0]=WD[ by_2-1:0];
		assign in_reg[18-zero_18_2:9]=WD[wr_width_int-1:by_2];
		end
		else
		begin
		assign in_reg[17:18-zero_18_2_odd]=0;
		assign in_reg[8:9-zero_18_2_odd+1]=0;
		assign in_reg[18-zero_18_2_odd-1:9]=WD[wr_width_int-1:by_2+1];
		assign in_reg[9-zero_18_2_odd:0]=WD[by_2:0];
		end
	end
	else
	begin
	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=WD;
	end
	
end
else
		
	begin 

	assign in_reg[35:wr_width_int]=0;
	assign in_reg[wr_width_int-1:0]=WD;	
	end	
if(rd_depth_int == 2048 && wr_depth_int ==512)
	assign WS1 =2'b10;
else if(rd_depth_int == 2048 && wr_depth_int == 1024)
	assign WS1=2'b01;
else if(wr_depth_int == 512 && wr_width_int <=9)
	assign WS1=2'b01;
else if(wr_width_int <=9)
	assign WS1 = 2'b00;
else if(wr_width_int >9 && wr_width_int <=18)
	assign WS1 = 2'b01;
else if(wr_width_int > 18)
	assign WS1 = 2'b10;


if(wr_depth_int == 2048 && rd_depth_int == 512)
	assign WS2 = 2'b10;
else if(wr_depth_int == 2048  && rd_depth_int == 1024)
	assign WS2 = 2'b01;
else if(rd_depth_int == 512 && rd_width_int <=9)
	assign WS2 = 2'b01;
else if(rd_width_int <= 9)
	assign WS2 = 2'b00;
else if((rd_width_int >9) && (rd_width_int <= 18))
	assign WS2 = 2'b01;
else if(rd_width_int >18)
	assign WS2 = 2'b10;

//Instantiating RAM8K_2x1 primitive.
if((((wr_width_int <= 18) && (wr_depth_int == 512)) ||((wr_width_int <=9) && (wr_depth_int==1024))) && (rd_depth_int != 2048))

	ram8k_2x1_cell_macro U1 (.A1_0(addr_wr0) , 
				 .A1_1(addr_wr1), 
				 .A2_0(addr_rd0), 
				 .A2_1(addr_rd1), 
				 .ASYNC_FLUSH_0(GND), //chk
				 .ASYNC_FLUSH_1(GND), //chk
				 .ASYNC_FLUSH_S0(GND),
				 .ASYNC_FLUSH_S1(GND),
				 .CLK1_0(WClk), 
				 .CLK1_1(GND), 
				 .CLK1S_0(WClk_Sel), 
				 .CLK1S_1(VCC),
				 .CLK1EN_0(WClk_En), 
				 .CLK1EN_1(GND), 
				 .CLK2_0(RClk),
				 .CLK2_1(GND), 
				 .CLK2S_0(RClk_Sel),
				 .CLK2S_1(VCC), 
				 .CLK2EN_0(RClk_En), 
				 .CLK2EN_1(GND), 
				 .CONCAT_EN_0(GND),
				 .CONCAT_EN_1(GND), 
				 .CS1_0(WD_SEL), 
				 .CS1_1(GND), 
				 .CS2_0(RD_SEL), 
				 .CS2_1(GND), 
				 .DIR_0(GND),
				 .DIR_1(GND), 
				 .FIFO_EN_0(GND), 
				 .FIFO_EN_1(GND), 
				 .P1_0(GND), //P1_0
				 .P1_1(GND), //P1_1
				 .P2_0(GND), //
				 .P2_1(GND), //
				 .PIPELINE_RD_0(reg_rd), 
				 .PIPELINE_RD_1(GND), 
				 .SYNC_FIFO_0(GND),
				 .SYNC_FIFO_1(GND), 
				 .WD_1(in_reg[35:18]), 
				 .WD_0(in_reg[17:0]), 
				 .WIDTH_SELECT1_0(WS1), 
				 .WIDTH_SELECT1_1(WS_GND), 
				 .WIDTH_SELECT2_0(WS2),
				 .WIDTH_SELECT2_1(WS_GND), 
				 .WEN1_0(wen_reg[1:0]), 
				 .WEN1_1(wen_reg[3:2]), 
				 .Almost_Empty_0(),
				 .Almost_Empty_1(), 
				 .Almost_Full_0(), 
				 .Almost_Full_1(),
				 .POP_FLAG_0(), 
				 .POP_FLAG_1(), 
				 .PUSH_FLAG_0(), 
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


if((wr_width_int > 18 && wr_depth_int==512) ||(wr_width_int > 9 && wr_depth_int == 1024) || wr_depth_int > 1024 || rd_depth_int == 2048 )
       	 
	ram8k_2x1_cell_macro U2 (.A1_0(addr_wr0) , 
				 .A1_1(addr_wr1), 
				 .A2_0(addr_rd0), 
				 .A2_1(addr_rd1), 
				 .ASYNC_FLUSH_0(GND), 
				 .ASYNC_FLUSH_1(GND),
				 .ASYNC_FLUSH_S0(GND),
				 .ASYNC_FLUSH_S1(GND),
				 .CLK1_0(WClk), 
				 .CLK1_1(WClk),
				 .CLK1S_0(WClk_Sel),
				 .CLK1S_1(WClk_Sel), 
				 .CLK1EN_0(WClk_En), 
				 .CLK1EN_1(WClk_En), 
				 .CLK2_0(RClk),
				 .CLK2_1(RClk),
				 .CLK2S_0(RClk_Sel),
				 .CLK2S_1(RClk_Sel), 
				 .CLK2EN_0(RClk_En), 
				 .CLK2EN_1(RClk_En), 
				 .CONCAT_EN_0(VCC),
				 .CONCAT_EN_1(GND), 
				 .CS1_0(WD_SEL), 
				 .CS1_1(GND), 
				 .CS2_0(RD_SEL), 
				 .CS2_1(GND), 
				 .DIR_0(GND),
				 .DIR_1(GND), 
				 .FIFO_EN_0(GND), 
				 .FIFO_EN_1(GND), 
				 .P1_0(GND), 
				 .P1_1(GND), 
				 .P2_0(GND),
				 .P2_1(GND), 
				 .PIPELINE_RD_0(reg_rd), 
				 .PIPELINE_RD_1(GND), 
				 .SYNC_FIFO_0(GND),
				 .SYNC_FIFO_1(GND), 
				 .WD_1(in_reg[35:18]), 
				 .WD_0(in_reg[17:0]), 
				 .WIDTH_SELECT1_0(WS1), 
				 .WIDTH_SELECT1_1(WS_GND), 
				 .WIDTH_SELECT2_0(WS2),
				 .WIDTH_SELECT2_1(WS_GND), 
				 .WEN1_0(wen_reg[1:0]), 
				 .WEN1_1(wen_reg[3:2]), 
				 .Almost_Empty_0(),
				 .Almost_Empty_1(), 
				 .Almost_Full_0(), 
				 .Almost_Full_1(),
				 .POP_FLAG_0(), 
				 .POP_FLAG_1(), 
				 .PUSH_FLAG_0(), 
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
assign RD[rd_width_int -1 :0]= out_reg[rd_width_int -1 :0];
else if(wr_depth_int == 1024 && wr_width_int > 9)
begin
	if(rd_width_int >18)
	begin
		assign RD[rd_width_int -1: by_2_read]=out_reg[35- zero_18_2_rg:18];
		assign RD[by_2_read-1 : 0]= out_reg[17-zero_18_2_rg: 0];
        end
	else if(rd_width_int <=9)
		assign RD[rd_width_int - 1:0]=out_reg[rd_width_int-1:0];
	else 
	begin
		assign RD[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign RD[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
	end
end	
else if(wr_depth_int ==1024 && wr_width_int <=9 )
	begin
		assign RD[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign RD[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
	end

else if(wr_depth_int == 2048) 
begin
	if(rd_depth_int == 512)
	begin
		assign RD[rd_width_int -1 :by_4_readx3 ]= out_reg[35-zero_9_2_rg:27];
		assign RD[by_4_readx3-1: by_4_readx2]=out_reg[26-zero_9_2_rg:18];
		assign RD[by_4_readx2-1: by_4_read]=out_reg[17-zero_9_2_rg:9];
		assign RD[by_4_read-1: 0]=out_reg[8-zero_9_2_rg:0];
	end	
	else
		begin
		assign RD[rd_width_int -1 : by_2_read] = out_reg[17-zero_9_2_rg:9];
		assign RD[by_2_read-1:0]=out_reg[8-zero_9_2_rg:0];	
		end
end
else                  
assign RD[rd_width_int-1:0] = out_reg[rd_width_int-1:0];
endgenerate


endmodule
`endif



