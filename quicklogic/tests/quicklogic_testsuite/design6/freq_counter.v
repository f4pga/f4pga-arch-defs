// file           	: freq_counter.v 
// description  	: Frequency Control file
// Modified       	: 2013/27/09 
// Modified by     	: Rakesh Moolacheri	
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2009/10/16      1.0        Mohamad Rajgara      created
// 2010/09/01      1.1        Anand A Wadke        Fixed compilation errors 
// 2010/09/02      1.2        Glen  A Gomes        Fixed Operation
// 2011/04/20      1.3        Glen  A Gomes        Updated to conform to DFM 
//                                                 standards and for speed.
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module freq_counter (

                RST,
                CLK,

                FREQ_CYCLE_TOGGLE,
                FREQ_CYCLE_REG, 
			    PWM_EN,

                FREQ_COUNTER_EN
                );
   
// Define I/O port properties
//
input           RST;
input           CLK;

input           FREQ_CYCLE_TOGGLE;
input   [15:0]  FREQ_CYCLE_REG;
input           PWM_EN;

output          FREQ_COUNTER_EN;
      
wire            RST;
wire            CLK;

wire            FREQ_CYCLE_TOGGLE;
wire    [15:0]  FREQ_CYCLE_REG;
wire            PWM_EN;

reg             FREQ_COUNTER_EN;
      
// Define internal signals
//
reg		 [7:0]	freq_0_cnt;
reg		 [7:0]	freq_0_cnt_nxt;

reg		      	freq_0_cnt_tc;
reg		      	freq_0_cnt_tc_nxt;

reg		 [7:0]	freq_1_cnt;
reg		 [7:0]	freq_1_cnt_nxt;

reg		      	freq_1_cnt_tc;
reg		      	freq_1_cnt_tc_nxt;

reg		[15:0]	freq_cycle_reg_a;
   
        
// Register freq_cnter and output logic
//
always @(posedge CLK or posedge RST) 
begin
   if (RST == 1'b1) 
   begin
       freq_0_cnt         <=  8'h0;        
       freq_0_cnt_tc      <=  1'b0;        

       freq_1_cnt         <=  8'h0;        
       freq_1_cnt_tc      <=  1'b0;        
 
       freq_cycle_reg_a  <= 32'h0;
       FREQ_COUNTER_EN   <=  1'b0;
   end
   else 
   begin
      // Load shadow register following the edge of VSYNC
	  //
      if ((PWM_EN == 1'b0) || (FREQ_CYCLE_TOGGLE == 1'b1))
        freq_cycle_reg_a <= FREQ_CYCLE_REG;

      // Define the operation of the counter's bytes
	  //
	  // Byte 0 free runs
	  //
      freq_0_cnt    <= freq_0_cnt_nxt;
      freq_0_cnt_tc <= freq_0_cnt_tc_nxt;

	  // Byte 1 either loads or counts on terminal count (tc) from lower byte
	  //
	  if ((PWM_EN == 1'b0) || freq_0_cnt_tc)
	  begin
          freq_1_cnt    <= freq_1_cnt_nxt;
          freq_1_cnt_tc <= freq_1_cnt_tc_nxt;
	  end
      // Register the load signal to the duty cycle counter
      //FREQ_COUNTER_EN <=  freq_0_cnt_tc_nxt & (~freq_0_cnt_tc) & freq_1_cnt_tc & freq_2_cnt_tc & freq_3_cnt_tc;
	  FREQ_COUNTER_EN <=  freq_0_cnt_tc_nxt & (~freq_0_cnt_tc) & freq_1_cnt_tc;
   end     
end

// Determine the frequency counter's first byte
//
always @(freq_cycle_reg_a or
		 freq_0_cnt        or
		 PWM_EN            or
		 FREQ_COUNTER_EN
        )
begin
	case({PWM_EN, FREQ_COUNTER_EN})
	2'b10:   freq_0_cnt_nxt <= freq_0_cnt - 8'b1;
	default: freq_0_cnt_nxt <= freq_cycle_reg_a[7:0];
	endcase

	case({PWM_EN, FREQ_COUNTER_EN})
	2'b10:   freq_0_cnt_tc_nxt <= (freq_0_cnt             == 8'h1);
	default: freq_0_cnt_tc_nxt <= (freq_cycle_reg_a[7:0] == 8'h0);
	endcase
end

// Determine the frequency counter's second byte
//
always @(freq_cycle_reg_a or
		 freq_1_cnt        or
		 PWM_EN            or
		 FREQ_COUNTER_EN
        )
begin
	case({PWM_EN, FREQ_COUNTER_EN})
	2'b10:   freq_1_cnt_nxt <= freq_1_cnt - 8'b1;
	default: freq_1_cnt_nxt <= freq_cycle_reg_a[15:8];
	endcase

	case({PWM_EN, FREQ_COUNTER_EN})
	2'b10:   freq_1_cnt_tc_nxt <= (freq_1_cnt              == 8'h1);
	default: freq_1_cnt_tc_nxt <= (freq_cycle_reg_a[15:8] == 8'h0);
	endcase
end

endmodule
