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
//`define AEC_1_0
module fll_acslip (
					wbs_clk_i,
					wbs_rst_i,
                    ACSLIP_EN_i,                       					
					
					sys_ref_clk_i,
					
					sys_ref_clk_16khz_o,
					i2s_clk_div3_o,
					
					i2s_ws_clk_i,
					
					ACSLIP_Reg_Rst_i,
					
					i2s_en_i,
					
`ifdef AEC_1_0
				    cnt_mic_dat_o ,
                    cnt_i2s_dat_o ,
`endif
					
					
					ACLSIP_Reg_o


				   );
parameter           ACSLIP_REG_WIDTH            = 32;//Default 9
				   
input 				wbs_clk_i;			   
input 				wbs_rst_i;	
input 				ACSLIP_EN_i;	
input 				sys_ref_clk_i;	
output 				sys_ref_clk_16khz_o;	
output 				i2s_clk_div3_o;	
input 				i2s_ws_clk_i;	
input 				ACSLIP_Reg_Rst_i;	
input 				i2s_en_i;	

`ifdef AEC_1_0
output              [31:0]  cnt_mic_dat_o ;
output              [31:0]  cnt_i2s_dat_o ;
`endif


//output 	 [9:0]		ACLSIP_Reg_o;	
output 	 [ACSLIP_REG_WIDTH-1:0]		ACLSIP_Reg_o;	




//reg      [9:0]      aclsip_reg;
reg      [ACSLIP_REG_WIDTH-1:0]      aclsip_reg;
wire                acslip_rst;

reg [3:0] 			clk16_cnt;
reg [1:0] 			clk_pos_cnt;
wire       			sys_ref_clk_div_16;
wire       			sys_ref_clk_div_16_g;
reg       			div0_t;
reg       			div2_t;
wire      			i2s_clk_div3_int;
wire      			i2s_clk_div3;



reg 				clk16khz_sigpos;
reg 				clk16khz_signeg;

wire                i2s_ws_clk_g;

reg 				i2s_clk_h_n_detect;


reg 				i2s_clk_div3_r1;
reg 				i2s_clk_div3_r2;
reg 				i2s_clk_div3_r3;
wire 				i2s_clk_div3_P_edge_det;

reg 				ref_clk_r1;
reg 				ref_clk_r2;
reg 				ref_clk_r3;
wire 				ref_clk_P_edge_det;

//AEC1.0 For Debug
reg              [31:0]  cnt_mic_dat ;
reg              [31:0]  cnt_i2s_dat ;

`ifdef AEC_1_0
assign  cnt_mic_dat_o  = cnt_mic_dat;
assign  cnt_i2s_dat_o  = cnt_i2s_dat;
`endif

assign ACLSIP_Reg_o = aclsip_reg;

//assign acslip_rst = wbs_rst_i | ACSLIP_Reg_Rst_i | ~ACSLIP_EN_i;
assign acslip_rst = wbs_rst_i | ACSLIP_Reg_Rst_i | ~ACSLIP_EN_i | ~i2s_en_i;

gclkbuff u_gclkbuff_clock12M ( .A( clk16_cnt[3]  )  , .Z( sys_ref_clk_div_16_g  ) );
//gclkbuff u_gclkbuff_div3     ( .A(i2s_clk_div3_int) , .Z(i2s_clk_div3       ) );
gclkbuff u_gclkbuff_i2swclk     ( .A(i2s_ws_clk_i) , .Z(i2s_ws_clk_g       ) );

assign sys_ref_clk_div_16 = clk16_cnt[3];
assign i2s_clk_div3 = i2s_clk_div3_int;

assign sys_ref_clk_16khz_o = sys_ref_clk_div_16_g;
assign i2s_clk_div3_o      = i2s_clk_div3;

always @(posedge wbs_clk_i or posedge acslip_rst)			
begin
	if (acslip_rst == 1'b1)
	begin
		aclsip_reg 				<= 0;//8'h00
		i2s_clk_h_n_detect <= 1'b0;
	end
	else
	begin
	    if (i2s_clk_div3_P_edge_det==1'b1 && ref_clk_P_edge_det==1'b1)
		begin
			aclsip_reg 				<= aclsip_reg;
		end
		else if (i2s_clk_div3_P_edge_det==1'b1)
		begin
			aclsip_reg 				<= aclsip_reg+1;
		end
		else if (ref_clk_P_edge_det==1'b1)
		begin
			aclsip_reg 				<= aclsip_reg-1;
		end
	
	end
end	


//I2S Clk Posedge detect.


assign i2s_clk_div3_P_edge_det = i2s_clk_div3_r2 & ~i2s_clk_div3_r3;
always @(posedge wbs_clk_i or posedge wbs_rst_i)			
begin
	if (wbs_rst_i == 1'b1)
	begin
		i2s_clk_div3_r1 <= 0;
		i2s_clk_div3_r2 <= 0;
		i2s_clk_div3_r3 <= 0;
    end
	else
	begin
		i2s_clk_div3_r1 <= i2s_clk_div3;
		i2s_clk_div3_r2 <= i2s_clk_div3_r1;
		i2s_clk_div3_r3 <= i2s_clk_div3_r2;
    end
end

//Ref Clk Posedge detect.

assign ref_clk_P_edge_det = ref_clk_r2 & ~ref_clk_r3;
always @(posedge wbs_clk_i or posedge wbs_rst_i)			
begin
	if (wbs_rst_i == 1'b1)
	begin
		ref_clk_r1 <= 0;
		ref_clk_r2 <= 0;
		ref_clk_r3 <= 0;
    end
	else
	begin
		ref_clk_r1 <= sys_ref_clk_div_16;
		ref_clk_r2 <= ref_clk_r1;
		ref_clk_r3 <= ref_clk_r2;
    end
end


//always @(posedge sys_ref_clk_i or posedge acslip_rst)  
always @(posedge sys_ref_clk_i or posedge wbs_rst_i)  
begin
    if (wbs_rst_i)
    begin
        clk16_cnt	<=  4'h0  ;
    end
    else 
    begin
			clk16_cnt   <=  clk16_cnt + 1;
 	end
end 


//Div 3 Logic


//always @(posedge i2s_ws_clk_i or posedge acslip_rst)   
//always @(posedge i2s_ws_clk_g or posedge acslip_rst)   
always @(posedge i2s_ws_clk_g or posedge wbs_rst_i)   
begin
    //if (acslip_rst)
    if (wbs_rst_i)
    begin
        clk16khz_sigpos		 <=  0  ;
        clk_pos_cnt		     <=  2'b00  ;
    end
    else 
    begin  
	   if (clk_pos_cnt == 2'b10)
	   begin
	        clk16khz_sigpos		 <=  1  ;
			clk_pos_cnt	         <=  2'b00  ;
		end		
	   else
	   begin
	        clk16khz_sigpos		 <=  0  ;
	        clk_pos_cnt          <=  clk_pos_cnt + 1; 
		end		
 	end
end 


//always @(negedge i2s_ws_clk_i or posedge acslip_rst)   
//always @(negedge i2s_ws_clk_g or posedge acslip_rst)   
always @(negedge i2s_ws_clk_g or posedge wbs_rst_i)   
begin
    //if (acslip_rst)
    if (wbs_rst_i)
    begin
        clk16khz_signeg		 <=  0  ;
    end
    else 
    begin  
	   if (clk_pos_cnt == 2'b10)
	   begin
	        clk16khz_signeg		 <=  1  ;
		end		
	   else
	   begin
	        clk16khz_signeg		 <=  0  ;

		end		
 	end
end 


assign i2s_clk_div3_int = clk16khz_sigpos | clk16khz_signeg;


`ifdef AEC_1_0

///MIC DATA Count
always @(posedge sys_ref_clk_div_16 or posedge acslip_rst)   
begin
    if (acslip_rst)
    begin
        cnt_mic_dat		<=  32'h0  ;
    end
    else 
    begin  
	    cnt_mic_dat   <=  cnt_mic_dat + 1;
 	end
end 

///I2S DATA Count
always @(posedge i2s_clk_div3 or posedge acslip_rst)   
begin
    if (acslip_rst)
    begin
        cnt_i2s_dat		<=  32'h0  ;
    end
    else 
    begin  
	    cnt_i2s_dat   <=  cnt_i2s_dat + 1;
 	end
end 



`endif




			

endmodule

/* reg i2s_clk_div3_r1;
reg i2s_clk_div3_r2;
reg i2s_clk_div3_r3;
reg sys_reference_clk_enable;
wire i2s_clk_div3_P_edge_det;
assign i2s_clk_div3_P_edge_det = i2s_clk_div3_r2 & ~i2s_clk_div3_r3;
always @(posedge wbs_clk_i or posedge acslip_rst)			
begin
	if (acslip_rst == 1'b1)
	begin
		i2s_clk_div3_r1 <= 0;
		i2s_clk_div3_r2 <= 0;
		i2s_clk_div3_r3 <= 0;
    end
	else
	begin
		i2s_clk_div3_r1 <= i2s_clk_div3_int;
		i2s_clk_div3_r2 <= i2s_clk_div3_r1;
		i2s_clk_div3_r3 <= i2s_clk_div3_r2;
    end
end

always @(posedge wbs_clk_i or posedge acslip_rst)			
begin
	if (acslip_rst == 1'b1)
	begin
       sys_reference_clk_enable <= 0;
    end
	else
	begin
	     if (i2s_clk_div3_P_edge_det)
			 sys_reference_clk_enable <= 1;	
	
    end
end */

///divide by 3--Old

/* //Div 3 Logic
always @(posedge i2s_ws_clk_i or posedge acslip_rst)  
begin
    if (acslip_rst)
    begin
        div0_t	<=  1'b0  ;
    end
    else 
    begin  
	   if (clk_pos_cnt == 2'b00)
			div0_t	<=  ~div0_t  ;
	   else
	        div0_t   <=  div0_t; 
 	end
end 

always @(posedge i2s_ws_clk_i or posedge acslip_rst)  
begin
    if (acslip_rst)
    begin
        div2_t	<=  1'b0  ;
    end
    else 
    begin  
	   if (clk_pos_cnt == 2'b10)
			div2_t	<=  ~div2_t  ;
	   else
	        div2_t   <=  div2_t; 
 	end
end 

assign i2s_clk_div3_int = div0_t ^ div2_t;  */