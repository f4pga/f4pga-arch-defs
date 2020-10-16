/*******************************************************************
 *
 *    FILE:         r2_bfly.v 
 *   
 *    DESCRIPTION:  
 *
 *    HIERARCHY:   
 *
 *    AUTHOR:	    Anand A Wadke
 *
 *    HISTORY:
 *			        - 04/26/2018	Initial coding.
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
 *******************************************************************/
`timescale 1ns/10ps
//`define r2_bfly_UTI_CHK
module r2_bfly (
                            clk_i,
							rst_i,
							
							ena_rad2_butfly_i,
							
							P_real_i,							 
                            P_img_i,							 
                            Q_real_i,							 
                            Q_img_i,
                            
							cos_i,
							sin_i,
							
							P_plus_WnQ_real_o,
							P_plus_WnQ_img_o,
							P_minus_WnQ_real_o,
							P_minus_WnQ_img_o,
							
							bfly_done_o
							
`ifdef r2_bfly_UTI_CHK
                                          ,	
							mul1_a_r_o    ,
							mul1_b_r_o    ,
							mul1_ena_r_o  ,
                            mul1_c_i      ,
                                         
                            mul2_a_r_o    ,
                            mul2_b_r_o    ,
                            mul2_ena_r_o  ,
						    mul2_c_i      
							              
`endif							
							
							
	
						 );
parameter                DATAWIDTH                   =  16           ;
	

input   				clk_i; 
input   				rst_i; 
input   				ena_rad2_butfly_i; 

input   [DATAWIDTH-1:0]	P_real_i; 
input   [DATAWIDTH-1:0]	P_img_i;
input   [DATAWIDTH-1:0]	Q_real_i;
input   [DATAWIDTH-1:0]	Q_img_i;	
input   [DATAWIDTH-1:0]	cos_i;	
input   [DATAWIDTH-1:0]	sin_i;	

output  [DATAWIDTH-1:0]	P_plus_WnQ_real_o;	
output  [DATAWIDTH-1:0]	P_plus_WnQ_img_o;	
output  [DATAWIDTH-1:0]	P_minus_WnQ_real_o;	
output  [DATAWIDTH-1:0]	P_minus_WnQ_img_o;	

output 					bfly_done_o;

`ifdef r2_bfly_UTI_CHK

output	[DATAWIDTH-1:0]				mul1_a_r_o    ;
output	[DATAWIDTH-1:0]				mul1_b_r_o    ;
output								mul1_ena_r_o  ;
input   [DATAWIDTH*2-1:0]           mul1_c_i      ;
                                      
output  [DATAWIDTH-1:0]             mul2_a_r_o    ;
output  [DATAWIDTH-1:0]             mul2_b_r_o    ;
output                  			mul2_ena_r_o  ;
input   [DATAWIDTH*2-1:0] 		    mul2_c_i      ;
							              
`endif	

//Internal Signal
reg   [DATAWIDTH-1:0]	mul1_a_r;	
reg   [DATAWIDTH-1:0]	mul1_b_r;	
wire  [DATAWIDTH*2-1:0]	mul1_c_w;
reg   [DATAWIDTH*2-1:0]	mul1_c_r;
reg           	        mul1_ena_r;

reg   [DATAWIDTH-1:0]	mul2_a_r;	
reg   [DATAWIDTH-1:0]	mul2_b_r;	
wire  [DATAWIDTH*2-1:0]	mul2_c_w;	
reg   [DATAWIDTH*2-1:0]	mul2_c_r;	
reg           	        mul2_ena_r;

reg 					bfly_done_r;


reg   [DATAWIDTH*2-1:0]	P_x_real_32b_extend_r;
reg   [DATAWIDTH*2-1:0]	P_x_img_32b_extend_r;

reg   [DATAWIDTH*2-1:0]	sincos_prodsum_32b_real_r;
reg   [DATAWIDTH*2-1:0]	sincos_prodsum_32b_img_r;


reg   [DATAWIDTH-1:0]	P_plus_WnQ_real_r 		;
reg   [DATAWIDTH-1:0]	P_plus_WnQ_img_r        ;
reg   [DATAWIDTH-1:0]	P_minus_WnQ_real_r      ;
reg   [DATAWIDTH-1:0]	P_minus_WnQ_img_r       ;


wire   	[31:0]		amult1_int;	
wire   	[31:0]		bmult1_int;	
wire   	[63:0]		cmult1_int;		

wire   	[31:0]		amult2_int;	
wire   	[31:0]		bmult2_int;	
wire   	[63:0]		cmult2_int;		


reg [1:0]               fsm_int_cntr;

//FSM control
reg 	[3:0]   		radix_butfly_fsm;
parameter				sR2_SET_ACCUM32_PLS_ROUND	 		= 4'b0000;
parameter				sR2_PROD_R_Im	 					= 4'b0001;
parameter   			sR2_PROD_R_Im_LAT_MUL1				= 4'b0010;
parameter   			sR2_REAL_SUM_LAT_MUL2				= 4'b0011;
parameter   			sR2_IMG_SUM    						= 4'b0100;
parameter				sR2_COMP_32b_BUTTFLY				= 4'b0101;   



assign bfly_done_o = bfly_done_r;

assign P_plus_WnQ_real_o    =  P_plus_WnQ_real_r 	;
assign P_plus_WnQ_img_o     =  P_plus_WnQ_img_r    ;
assign P_minus_WnQ_real_o   =  P_minus_WnQ_real_r  ;
assign P_minus_WnQ_img_o    =  P_minus_WnQ_img_r   ;

	

always @(posedge clk_i or posedge rst_i)
begin
   if (rst_i)
   begin
        bfly_done_r 		<= 1'b0;
		
		mul1_a_r         		<= 0;
		mul1_b_r         		<= 0;
		mul1_ena_r       		<= 0;

		mul2_a_r         		<= 0;
		mul2_b_r         		<= 0;		
		mul2_ena_r       		<= 0;	
		
		P_x_real_32b_extend_r 	<= 0;
		P_x_img_32b_extend_r  	<= 0;
		
		sincos_prodsum_32b_real_r <= 0;
		sincos_prodsum_32b_img_r  <= 0;
		
		mul1_c_r 				<= 0;
		mul2_c_r  				<= 0;
		
		P_plus_WnQ_real_r    	<=  0;
		P_plus_WnQ_img_r     	<=  0;
		P_minus_WnQ_real_r   	<=  0;
		P_minus_WnQ_img_r    	<=  0;
		
			
		fsm_int_cntr        <= 0;//nu

        radix_butfly_fsm <= sR2_SET_ACCUM32_PLS_ROUND;		
   
   
   end
   else
   begin
        case (radix_butfly_fsm)
		
			sR2_SET_ACCUM32_PLS_ROUND : begin
			                                  bfly_done_r     <= 1'b0;
											  
											  P_x_real_32b_extend_r <= (P_real_i << 15) + 16'h8000;	
					                          P_x_img_32b_extend_r  <= (P_img_i << 15) + 16'h8000;
											  
											  mul1_c_r 				<= 0;
											  mul2_c_r  			<= 0;
											 
											  
											  mul1_a_r         <= 0;
											  mul1_b_r         <= 0;
											  mul1_ena_r       <= 0;
									          mul2_a_r         <= 0;
											  mul2_b_r         <= 0;		
											  mul2_ena_r       <= 0;
											  
											  P_plus_WnQ_real_r    <=  P_plus_WnQ_real_r  ;//0;
											  P_plus_WnQ_img_r     <=  P_plus_WnQ_img_r   ;//0;
											  P_minus_WnQ_real_r   <=  P_minus_WnQ_real_r ;//0;
											  P_minus_WnQ_img_r    <=  P_minus_WnQ_img_r  ;//0;											  

											  sincos_prodsum_32b_real_r <= 0;
											  sincos_prodsum_32b_img_r  <= 0;	
											  
											  if (ena_rad2_butfly_i)
											  begin
                                                radix_butfly_fsm <= sR2_PROD_R_Im;
                                              end
                                              else
                                              begin
                                                radix_butfly_fsm <= radix_butfly_fsm;
                                              end											  
										end
										
			 							
            sR2_PROD_R_Im             : begin
			                                  P_x_real_32b_extend_r <= P_x_real_32b_extend_r ;
											  P_x_img_32b_extend_r  <= P_x_img_32b_extend_r  ;
											  
											  mul1_c_r 				<= 0;
											  mul2_c_r  			<= 0;
											  
											  bfly_done_r <= 1'b0;
											  
											  mul1_a_r         <= Q_real_i;
											  mul1_b_r         <= cos_i;
											  mul1_ena_r       <= 1'b1;	

											  mul2_a_r         <= Q_img_i;
											  mul2_b_r         <= sin_i;
											  mul2_ena_r       <= 1'b1;	
											  
											  sincos_prodsum_32b_real_r <= 0;
											  sincos_prodsum_32b_img_r  <= 0;											  
											  
			                                  radix_butfly_fsm <= sR2_PROD_R_Im_LAT_MUL1;	
			
			                             end
										 
			sR2_PROD_R_Im_LAT_MUL1     :  begin
			                                  P_x_real_32b_extend_r <= P_x_real_32b_extend_r ;
											  P_x_img_32b_extend_r  <= P_x_img_32b_extend_r  ;
											  
											  sincos_prodsum_32b_real_r <= 0;
											  sincos_prodsum_32b_img_r  <= 0;	
											  
											  mul1_c_r 				<= mul1_c_w;
											  mul2_c_r  			<= mul2_c_w;
											  
											  bfly_done_r <= 1'b0;
											  
											  mul1_a_r         <= (~Q_real_i) + 1;
											  mul1_b_r         <= sin_i;
											  mul1_ena_r       <= 1'b1;	

											  mul2_a_r         <= Q_img_i;
											  mul2_b_r         <= cos_i;
											  mul2_ena_r       <= 1'b1;	
											  
			                                  radix_butfly_fsm <= sR2_REAL_SUM_LAT_MUL2;


                                       end 

			sR2_REAL_SUM_LAT_MUL2     :  begin
			                                  P_x_real_32b_extend_r <= P_x_real_32b_extend_r ;
											  P_x_img_32b_extend_r  <= P_x_img_32b_extend_r  ;
											  
											  sincos_prodsum_32b_real_r <= mul1_c_r+mul2_c_r;
											  sincos_prodsum_32b_img_r  <= 0;	
											  
											  mul1_c_r 				<= mul1_c_w;
											  mul2_c_r  			<= mul2_c_w;
											  
											  bfly_done_r <= 1'b0;
											  
											  mul1_a_r         <= (~Q_real_i) + 1;
											  mul1_b_r         <= sin_i;
											  mul1_ena_r       <= 1'b1;	

											  mul2_a_r         <= Q_img_i;
											  mul2_b_r         <= cos_i;
											  mul2_ena_r       <= 1'b1;	
											  
			                                  radix_butfly_fsm <= sR2_IMG_SUM;


                                       end	

			sR2_IMG_SUM               :  begin
			                                  P_x_real_32b_extend_r <= P_x_real_32b_extend_r ;
											  P_x_img_32b_extend_r  <= P_x_img_32b_extend_r  ;
											  
											  sincos_prodsum_32b_real_r <= sincos_prodsum_32b_real_r;
											  sincos_prodsum_32b_img_r  <= mul1_c_r+mul2_c_r;	
											  
											  mul1_c_r 				<= mul1_c_w;
											  mul2_c_r  			<= mul2_c_w;
											  
											  bfly_done_r <= 1'b0;
											  
											  mul1_a_r         		<= 0;
											  mul1_b_r         		<= 0;
											  mul1_ena_r       		<= 0;	
		
											  mul2_a_r         		<= 0;
											  mul2_b_r         		<= 0;
											  mul2_ena_r       		<= 0;	
											  
			                                  radix_butfly_fsm      <= sR2_COMP_32b_BUTTFLY;


                                       end		


           sR2_COMP_32b_BUTTFLY        : begin
		                                   
											  P_plus_WnQ_real_r    <=  (P_x_real_32b_extend_r 	- sincos_prodsum_32b_real_r ) >> 16;
                                              P_plus_WnQ_img_r     <=  (P_x_img_32b_extend_r 	- sincos_prodsum_32b_img_r  ) >> 16;
                                              P_minus_WnQ_real_r   <=  (P_x_real_32b_extend_r 	+ sincos_prodsum_32b_real_r ) >> 16;
										      P_minus_WnQ_img_r    <=  (P_x_img_32b_extend_r 	+ sincos_prodsum_32b_img_r  ) >> 16;
											  
											  bfly_done_r     <=   1'b1;

			                                  P_x_real_32b_extend_r <= P_x_real_32b_extend_r ;
											  P_x_img_32b_extend_r  <= P_x_img_32b_extend_r  ;
											  
											  sincos_prodsum_32b_real_r <= sincos_prodsum_32b_real_r;
											  sincos_prodsum_32b_img_r  <= sincos_prodsum_32b_img_r;	
											  
											  mul1_c_r 				<= 0;
											  mul2_c_r  			<= 0;
											  
											  mul1_a_r         		<= 0;
											  mul1_b_r         		<= 0;
											  mul1_ena_r       		<= 0;	
		
											  mul2_a_r         		<= 0;
											  mul2_b_r         		<= 0;
											  mul2_ena_r       		<= 0;	
											  
											  radix_butfly_fsm      <= sR2_SET_ACCUM32_PLS_ROUND;
										 end
										 
			default                     : begin
											  radix_butfly_fsm      <= sR2_SET_ACCUM32_PLS_ROUND;	

                                          end			



        endcase
   end
end	
	
`ifndef r2_bfly_UTI_CHK
	
//Multiplier	
/*
qlal4s3_mult_16x16_cell u_qlal4s3_mult_16x16_cell_cos_mul //qlal4s3_mult_16x16_cell
						( 
							.Amult			(mul1_a_r), 
							.Bmult			(mul1_b_r), 
							.Valid_mult		(mul1_ena_r),
                            //.sel_mul_32x32  (1'b0),							
							.Cmult			(mul1_c_w));	
	
	
	
qlal4s3_mult_16x16_cell u_qlal4s3_mult_16x16_sin_mul //qlal4s3_mult_16x16_cell
						( 
							.Amult			(mul2_a_r), 
							.Bmult			(mul2_b_r), 
							.Valid_mult		(mul2_ena_r),
                            //.sel_mul_32x32  (1'b0),							
							.Cmult			(mul2_c_w));
*/	
							
assign amult1_int = {{16{mul1_a_r[15]}},mul1_a_r};
assign bmult1_int = {{16{mul1_b_r[15]}},mul1_b_r};
assign mul1_c_w = cmult1_int[31:0];

qlal4s3_mult_cell_macro u_qlal4s3_mult_cell_macro_1//qlal4s3_mult_cell_macro 
						( 
							.Amult			(amult1_int), 
							.Bmult			(bmult1_int), 
							.Valid_mult		(2'b11),
                            .sel_mul_32x32  (1'b0),							
							.Cmult			(cmult1_int));
							
assign amult2_int = {{16{mul2_a_r[15]}},mul2_a_r};
assign bmult2_int = {{16{mul2_b_r[15]}},mul2_b_r};
assign mul2_c_w = cmult2_int[31:0];

qlal4s3_mult_cell_macro u_qlal4s3_mult_cell_macro_2//qlal4s3_mult_cell_macro 
						( 
							.Amult			(amult2_int), 
							.Bmult			(bmult2_int), 
							.Valid_mult		(2'b11),
                            .sel_mul_32x32  (1'b0),							
							.Cmult			(cmult2_int));
							
`else

assign mul1_a_r_o      =  mul1_a_r    ; 
assign mul1_b_r_o      =  mul1_b_r    ;
assign mul1_ena_r_o    =  mul1_ena_r  ;
assign mul1_c_w        =  mul1_c_i;
                          
assign mul2_a_r_o      =  mul2_a_r    ;
assign mul2_b_r_o      =  mul2_b_r    ;
assign mul2_ena_r_o    =  mul2_ena_r  ;	
assign mul2_c_w        =  mul2_c_i;				

`endif							
							
							
/* //kogg Adder		

	ksa32 sum_p_plus_wnq_ksa32_inst (
				  .a	(koggS_a_sig_lram)	,
				  .b	(koggS_b_sig_lram)	,
				  .cin	(1'b0)	,
				  .sum	(koggS_sum_o_sig_lram)	,
				  .cout (koggS_c_o_sig_lram)
				);						
	

	ksa32 sum_p_minus_wnq_ksa32_inst (
				  .a	(koggS_a_sig_lram)	,
				  .b	(koggS_b_sig_lram)	,
				  .cin	(1'b0)	,
				  .sum	(P_minus_WnQ_o)	,
				  .cout (koggS_c_o_sig_lram)
				);	 */

	

endmodule	



