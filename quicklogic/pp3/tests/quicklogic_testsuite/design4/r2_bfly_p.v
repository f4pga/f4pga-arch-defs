/*******************************************************************
 *
 *    FILE:         r2_bfly_p.v 
 *   
 *    DESCRIPTION:  bfly Pipeline.
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - 12/26/2018	Initial coding.
 *			
 *
 * Copyright (C) 2018, Licensed Customers of QuickLogic may copy and modify this
 * file for use in designing QuickLogic devices only.
 *
 * IMPORTANT NOTICE: DISCLAIMER OF WARRANTY
 * This design is provided without warranty of any kind.
 * QuickLogic Corporation does not warrant, guarantee or make any representations
 * regarding the use, or the results of the use, of this design. QuickLogic
 * disclaims all implied warranties, including but not limited to implied
 * warranties of merchantability and fitness for a particular purpose. In addition
 * and without limiting the generality of the foregoing, QuickLogic does not make
 * any warranty of any kind that any item developed based on this design, or any
 * portion of it, will not infringe any copyright, patent, trade secret or other
 * intellectual property right of any person or entity in any country. It is the
 * responsibility of the user of the design to seek licenses for such intellectual
 * property rights where applicable. QuickLogic shall not be liable for any
 * damages arising out of or in connection with the use of the design including
 * liability for lost profit, business interruption, or any other damages whatsoever.
 *
 * ------------------------------------------------------------
 * Date: December 26, 2018
 * Engineer: Anand Wadke
 * Revision: 0.1
 * Change:
 * 1. Initial Coding
 *    Input sequence to bfly is P and Q(both complex).
 *                   k           k
 *    Output is P + W * Q and P-W *Q
 *                   N           N
 * Revisio: 0.2
 * Used 15 bit shifted version of Multiplier O/p
  *******************************************************************/
`timescale 1ns/10ps

//`define ACCUM_40
`define PER_STG_SCALE
`define KOGG_STONE
module r2_bfly_p (
                            clk_i,
							rst_i,
							
							ena_rad2_butfly_i,
							
							//RAM interface
							fRAM_real_data_i,
							fRAM_img_data_i,
							
							fRAM_real_data_o,
							fRAM_img_data_o,
							
							fRAM_realimg_r_addr_o,
							fRAM_realimg_w_addr_o,
							fRAM_realimg_wr_o,
							
							cos_i,
							sin_i,
							
							//bfly_done_o,
							
							scale_last_stg_i,
							last_stg_i,
							
							mul1_a_o,	
							mul1_b_o,	
							mul1_c_i,
							mul1_ena_o,
							
							mul2_a_o,	
							mul2_b_o,	
							mul2_c_i,
							mul2_ena_o,
							
							//loop_cnt_pls_1_i,
							loop_cnt_i,
							stride_i,
							p_init_i,
							p_stage_idx_bfcalc_o,
							
							cycle_cnt_o
							
							//bfly_busy_o
							
	
						 );
parameter                ADDRWIDTH                   =  9           ;
parameter                DATAWIDTH                   =  32           ;
parameter                COEFWIDTH                   =  16           ;
	

input   				clk_i; 
input   				rst_i; 
input   				ena_rad2_butfly_i; 

input 	[DATAWIDTH-1:0]	fRAM_real_data_i;
input 	[DATAWIDTH-1:0]	fRAM_img_data_i;

output 	[DATAWIDTH-1:0]	fRAM_real_data_o;
output 	[DATAWIDTH-1:0]	fRAM_img_data_o;


output	[ADDRWIDTH-1:0]	fRAM_realimg_r_addr_o;
output	[ADDRWIDTH-1:0]	fRAM_realimg_w_addr_o;
output					fRAM_realimg_wr_o;

input   [COEFWIDTH-1:0]	cos_i;	
input   [COEFWIDTH-1:0]	sin_i;	

//output 					bfly_done_o;

input 					scale_last_stg_i;
input 					last_stg_i;

output  [DATAWIDTH-1:0] 	mul1_a_o;	
output  [DATAWIDTH-1:0] 	mul1_b_o;	
input  [DATAWIDTH*2-1:0]	mul1_c_i;
output  					mul1_ena_o;

output  [DATAWIDTH-1:0] 	mul2_a_o;	
output  [DATAWIDTH-1:0] 	mul2_b_o;	
input  [DATAWIDTH*2-1:0]	mul2_c_i;
output  					mul2_ena_o;

//input   [9:0]               loop_cnt_pls_1_i;
input   [9:0]               loop_cnt_i;
input   [9:0]               stride_i;
input   [9:0]               p_init_i;
output  [9:0]               p_stage_idx_bfcalc_o;

output  [2:0]               cycle_cnt_o;

//output                      bfly_busy_o;


//Internal Signal

wire  [DATAWIDTH-1:0] 	mul1_a_o;	
wire  [DATAWIDTH-1:0] 	mul1_b_o;	
wire  [DATAWIDTH*2-1:0]	mul1_c_i;
wire  					mul1_ena_o;

wire  [DATAWIDTH-1:0] 	mul2_a_o;	
wire  [DATAWIDTH-1:0] 	mul2_b_o;	
wire  [DATAWIDTH*2-1:0]	mul2_c_i;
wire  					mul2_ena_o;

reg   [DATAWIDTH-1:0]   Pr; 
reg   [DATAWIDTH-1:0]   Pi; 
reg   [DATAWIDTH-1:0]   Qr; 
reg   [DATAWIDTH-1:0]   Qi; 
`ifdef ACCUM_40
reg   [DATAWIDTH-1+8:0]   Pr_dash; 
reg   [DATAWIDTH-1+8:0]   Pi_dash; 
reg   [DATAWIDTH-1+8:0]   Qr_dash; 
reg   [DATAWIDTH-1+8:0]   Qi_dash; 
reg   [DATAWIDTH-1+8:0]   Ar; 
reg   [DATAWIDTH-1+8:0]   Br; 
reg   [DATAWIDTH-1+8:0]   Ci;
reg   [DATAWIDTH-1+8:0]   Di;
reg   [DATAWIDTH-1+8:0]   X;
reg   [DATAWIDTH-1+8:0]   Y;
`else
reg   [DATAWIDTH-1:0]   Pr_dash; 
reg   [DATAWIDTH-1:0]   Pi_dash; 
reg   [DATAWIDTH-1:0]   Qr_dash; 
reg   [DATAWIDTH-1:0]   Qi_dash; 
reg   [DATAWIDTH-1:0]   Ar; 
reg   [DATAWIDTH-1:0]   Br; 
reg   [DATAWIDTH-1:0]   Ci;
reg   [DATAWIDTH-1:0]   Di;
reg   [DATAWIDTH-1:0]   X;
reg   [DATAWIDTH-1:0]   Y;
`endif


//reg   [10:0]   			p2n;
//Index
reg   [10:0]   			p;
reg   [10:0]   			j2;
reg   [10:0]   			j2n;
reg   [10:0]   			p2;
reg                     fram_wr_en;

//reg 					bfly_done_r;
wire                    rst_butfly;

reg                     mask_first_wr;
reg 	[2:0] 		    cycle_cnt;


`ifdef KOGG_STONE

	wire [DATAWIDTH-1:0] Ar_plus_Br_sig;
	wire               Ar_plus_Br_carry;
	
	wire [DATAWIDTH-1:0] Ci_plus_Di_sig;
	wire               Ci_plus_Di_carry;
	
	wire [DATAWIDTH-1:0] Pr_plus_X_sig;
	wire               Pr_plus_X_carry;	

	wire [DATAWIDTH-1:0] Pi_plus_Y_sig;
	wire               Pi_plus_Y_carry;
	
	wire [DATAWIDTH-1:0] Pr_plus_mp1X_sig;
	wire [DATAWIDTH-1:0] X_2cmpl;
	wire               Pr_plus_mp1X_carry;
	
	wire [DATAWIDTH-1:0] Pi_plus_mp1Y_sig;
	wire [DATAWIDTH-1:0] Y_2cmpl;
	wire               Pi_plus_mp1Y_carry;
	
`endif


assign rst_butfly = rst_i | ~ena_rad2_butfly_i;

assign mul1_a_o			=	 Qr;	
//assign mul1_b_o			=	(cycle_cnt == 2) ? {{16{cos_i[15]}},cos_i} :{{16{sin_i[15]}},sin_i} ;	
assign mul1_b_o			=	(cycle_cnt == 5) ? {{16{cos_i[15]}},cos_i} :{{16{sin_i[15]}},sin_i} ;	
assign mul1_ena_o		=	1'b1;		
                        
assign mul2_a_o			=    Qi;		
//assign mul2_b_o			=   (cycle_cnt == 2) ? {{16{sin_i[15]}},sin_i} :{{16{cos_i[15]}},cos_i} ;	
assign mul2_b_o			=   (cycle_cnt == 5) ? {{16{sin_i[15]}},sin_i} :{{16{cos_i[15]}},cos_i} ;	
assign mul2_ena_o       =   1'b1;

//assign bfly_done_o = bfly_done_r;




assign cycle_cnt_o 			= cycle_cnt;

assign p_stage_idx_bfcalc_o = p;

//Cycle control
always @(posedge clk_i or posedge rst_butfly)
begin
   if (rst_butfly)
   begin
			//cycle_cnt 		<= 3'h4;
			cycle_cnt 		<= 3'h3;//to accomodate J2
   end
   else
   begin
		    if (cycle_cnt == 3'h5)
				cycle_cnt 		<= 2;	
			else
				cycle_cnt 		<= cycle_cnt + 1;	
   end
end

//Latch Pr, Pi,Qr, Qi, Ar,Br, Ci,Di,X,Y
always @(posedge clk_i or posedge rst_butfly)
begin
   if (rst_butfly)
   begin
			Pr 			<= 0;
			Pi 			<= 0;

			Qr 			<= 0;
			Qi 			<= 0;			
			
			Ar 			<= 0;
			Br 			<= 0;
			Ci 			<= 0;
			Di 			<= 0;
			X  			<= 0;
			Y  			<= 0;
			
			Pr_dash     <= 0; 
			Qr_dash     <= 0; 
			
			Pi_dash     <= 0; 
			Qi_dash     <= 0;			
   end
   else
   begin
          case (cycle_cnt)
		  
		    5 : 	begin
		            	Pr 		<= fRAM_real_data_i;
		            	Pi 		<= fRAM_img_data_i;
`ifdef ACCUM_40		            	
		            	Ar 		<= mul1_c_i[39:0];
		            	Br 		<= ~mul2_c_i[39:0] + 1;
`else
		            	Ar 		<= mul1_c_i[46:15];//Mult O/p right shift by 15 to accomadate 2^15 multiplication
		            	Br 		<= ~mul2_c_i[46:15] + 1;//Mult O/p right shift by 15 to accomadate 2^15 multiplication
`endif						
		              end
		
			2 :      begin 
`ifdef ACCUM_40				
			         	Ci 		<= mul1_c_i[39:0];
			         	Di 		<= mul2_c_i[39:0];
`else	
			         	Ci 		<= mul1_c_i[46:15];//Mult O/p right shift by 15 to accomadate 2^15 multiplication
			         	Di 		<= mul2_c_i[46:15];//Mult O/p right shift by 15 to accomadate 2^15 multiplication	
`endif					

`ifdef KOGG_STONE
						X       <= Ar_plus_Br_sig;
`else			         
			         	X       <= Ar + Br;//Br negated added to Ar
`endif						
			         end
			
			3 :      begin
`ifdef KOGG_STONE
                        Pr_dash  <= Pr_plus_X_sig;
                        Qr_dash  <= Pr_plus_mp1X_sig;	
			            Y        <= Ci_plus_Di_sig; 
`else			
			         	Pr_dash  <= Pr + X;        
			         	Qr_dash  <= Pr - X;		
	                 
		                 Y       <= Ci + Di; 
`endif						 
		               end
					   
			4 :   	  begin
                  		Qr 		<= fRAM_real_data_i;
			      		Qi 		<= fRAM_img_data_i;
						
`ifdef KOGG_STONE
						Pi_dash  <= Pi_plus_Y_sig;  
                        Qi_dash  <= Pi_plus_mp1Y_sig;	
`else						     
						Pi_dash  <= Pi + Y;               
						Qi_dash  <= Pi - Y;	
`endif						
					  end	
            default : begin
						Pr 			<= Pr 		;
			            Pi 			<= Pi 		;
			            Qr 			<= Qr 		;
			            Qi 			<= Qi 		;
			            Ar 			<= Ar 		;
			            Br 			<= Br 		;
			            Ci 			<= Ci 		;
			            Di 			<= Di 		;
			            X  			<= X  		;
			            Y  			<= Y  		;
			            Pr_dash     <= Pr_dash ;
			            Qr_dash     <= Qr_dash ;
			          end
   
		  endcase
    
   end
end


//RAM access
assign  fRAM_realimg_r_addr_o = (cycle_cnt==3)? j2n : p;
assign  fRAM_realimg_w_addr_o = (cycle_cnt==2)? j2 : p2;
assign 	fRAM_realimg_wr_o 	= fram_wr_en;
/* assign 	fRAM_real_data_o 		= (cycle_cnt==2)? Pr_dash : Qr_dash;
assign 	fRAM_img_data_o 		= (cycle_cnt==2)? Pi_dash : Qi_dash; */
`ifdef ACCUM_40
assign 	fRAM_real_data_o 		= (cycle_cnt==2)? Qr_dash[39:8] : Pr_dash[39:8];
assign 	fRAM_img_data_o 		= (cycle_cnt==2)? Qi_dash[39:8] : Pi_dash[39:8];
`else
`ifdef PER_STG_SCALE
assign 	fRAM_real_data_o 		= (cycle_cnt==2)? {Qr_dash[31],Qr_dash[31:1]} : {Pr_dash[31],Pr_dash[31:1]};
assign 	fRAM_img_data_o 		= (cycle_cnt==2)? {Qi_dash[31],Qi_dash[31:1]} : {Pi_dash[31],Pi_dash[31:1]};
`else
assign 	fRAM_real_data_o 		= (cycle_cnt==2)? Qr_dash : Pr_dash;
assign 	fRAM_img_data_o 		= (cycle_cnt==2)? Qi_dash : Pi_dash;
`endif
`endif

reg mask_first_p_incr;

//RAM read-write address generation
//always @(posedge clk_i or posedge rst_butfly)
always @(posedge clk_i or posedge rst_i)
begin
   if (rst_i)
   begin
			j2  		  <= 0;
			j2n  		  <= 0;
			p2  		  <= 0;
			//p2n  		  <= 0;
			fram_wr_en  <= 0;
			p             <= 0;
			mask_first_wr <= 1;
			mask_first_p_incr <= 1;	
			
   end
   else
   begin
      if (~ena_rad2_butfly_i)
	  begin
			j2  		  <= p+loop_cnt_i;
			j2n  		  <= p+loop_cnt_i;
			p2  		  <= p_init_i;
			fram_wr_en  <= 0;
			p             <= p_init_i;
            mask_first_wr <= 1;			
            mask_first_p_incr <= 1;			
      end
	  else
	  begin
         case (cycle_cnt)
		
			2 		:  begin
							j2n  		  	<= p+loop_cnt_i+stride_i;
                            j2            	<= j2n;
							mask_first_wr   <= 0;
							//
							
							
					   end		
			3 		:  begin 
							p2  			<= p;
							if (~mask_first_p_incr)
							    p   			<= p+stride_i;
							fram_wr_en  	<= 0;
							
							//mask_first_wr   <= 0;
					   end	

			5 		:  begin 
			                if (~mask_first_wr)
							 fram_wr_en  	<= 1;
						 
							 mask_first_p_incr <= 0;
					   end						   

			default : begin
							j2 				<= j2;
							p2 				<= p2;
							//p2n 			<= p2n;
							p 				<= p;
							fram_wr_en  	<= fram_wr_en;
                      end		  
		 endcase
	   end	
	  	
  end
end

							
							
 //kogg Adder		
`ifdef KOGG_STONE

	ksa32 Ar_plus_Br_kaddrinst (
				  .a	(Ar)	,
				  .b	(Br)	,
				  .cin	(1'b0)	,
				  .sum	(Ar_plus_Br_sig)	,
				  .cout (Ar_plus_Br_carry)
				);	

	
	ksa32 Ci_plus_Di_kaddrinst (
				  .a	(Ci)	,
				  .b	(Di)	,
				  .cin	(1'b0)	,
				  .sum	(Ci_plus_Di_sig)	,
				  .cout (Ci_plus_Di_carry)
				);					
				
	
	ksa32 Pr_plus_X_kaddrinst (
				  .a	(Pr)	,
				  .b	(X)	,
				  .cin	(1'b0)	,
				  .sum	(Pr_plus_X_sig)	,
				  .cout (Pr_plus_X_carry)
				);	

	
	ksa32 Pi_plus_Y_kaddrinst (
				  .a	(Pi)	,
				  .b	(Y)	,
				  .cin	(1'b0)	,
				  .sum	(Pi_plus_Y_sig)	,
				  .cout (Pi_plus_Y_carry)
				);		

	
	assign X_2cmpl = ~X + 1;
	
	ksa32 Pr_plus_mp1X_kaddrinst (
				  .a	(Pr)	,
				  .b	(X_2cmpl)	,
				  .cin	(1'b0)	,
				  .sum	(Pr_plus_mp1X_sig)	,
				  .cout (Pr_plus_mp1X_carry)
				);					

				
	assign Y_2cmpl = ~Y + 1;	
	
	ksa32 Pi_plus_mp1Y_kaddrinst (
				  .a	(Pi)	,
				  .b	(Y_2cmpl)	,
				  .cin	(1'b0)	,
				  .sum	(Pi_plus_mp1Y_sig)	,
				  .cout (Pi_plus_mp1Y_carry)
				);									


 
`endif
	

endmodule	



