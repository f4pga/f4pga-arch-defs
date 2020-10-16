// file           	: duty_cycle_counter.v 
// description  	: Duty Cycle Control file
// Modified       	: 2013/27/09 
// Modified by     	: Rakesh Moolacheri	
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author         description
// 2009/10/16      1.0        Mohamad Rajgara      created
// 2010/09/01      1.1        Anand A Wadke        changed PWM out assigned statements
// 2010/09/02	   1.2		  Glen Gomes		   changed PWM output to be registered
// 2011/04/20	   1.3		  Glen Gomes		   Updated to conform to DFM standards
//                                                 and for higher speed operation
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------

`timescale 1ns/10ps

module duty_cycle_count (

				RST,
				CLK,

				DUTY_CYCLE_TOGGLE,
				DUTY_CYCLE_REG, 

				PWM_EN,
				idle_pol,
				FREQ_COUNTER_EN,

				PWM
				);
   

// Define I/O ports
//
input 			RST;
input 			CLK;

input 			DUTY_CYCLE_TOGGLE;
input	[15:0]	DUTY_CYCLE_REG;

input           PWM_EN;
input 			FREQ_COUNTER_EN;

input           idle_pol;

output 			PWM;
      
wire 			RST;
wire 			CLK;

wire 			DUTY_CYCLE_TOGGLE;
wire	[15:0]	DUTY_CYCLE_REG;

wire            PWM_EN;
wire 			FREQ_COUNTER_EN;

reg 			PWM_r;
reg 			PWM_nxt;
      

// Define internal signals
//
reg		 [7:0]	duty_0_cnt;
reg		 [7:0]	duty_0_cnt_nxt;

reg		      	duty_0_cnt_tc;
reg		      	duty_0_cnt_tc_nxt;

reg		 [7:0]	duty_1_cnt;
reg		 [7:0]	duty_1_cnt_nxt;

reg		      	duty_1_cnt_tc;
reg		      	duty_1_cnt_tc_nxt;

reg     		duty_cycle_cnt_ld;
reg     		duty_cycle_cnt_ld_nxt;

reg             duty_cycle_cnt_tc;
wire            duty_cycle_cnt_tc_nxt;

reg				duty_cycle_ld_tc;
wire			duty_cycle_ld_tc_nxt;

reg		[15:0]	duty_cycle_reg_a;

reg		 [1:0]  duty_cycle_state;
reg		 [1:0]  duty_cycle_state_nxt;

  
// Define the Duty Cycle Counter's State bits
//
parameter  DUTY_IDLE_ST   = 3'h0;
parameter  DUTY_COUNT_ST  = 3'h1;
parameter  DUTY_WAIT_ST   = 3'h2;

assign PWM = (idle_pol)? ~PWM_r: PWM_r;
// Register duty cycle counter and output logic
//
always @(posedge CLK or posedge RST) 
begin
	if (RST == 1'b1) 
	begin
	    duty_cycle_state  <=  DUTY_IDLE_ST;

   		duty_0_cnt 		  <=  8'h0;
   		duty_0_cnt_tc	  <=  1'b0;

   		duty_1_cnt 		  <=  8'h0;
   		duty_1_cnt_tc	  <=  1'b0;

		duty_cycle_cnt_ld <=  1'b1;
		duty_cycle_cnt_tc <=  1'b0;
		duty_cycle_ld_tc  <=  1'b0;

		duty_cycle_reg_a  <= 32'h0;

		PWM_r			      <=  1'b0;
	end
    else 
	begin
	    duty_cycle_state <= duty_cycle_state_nxt;

		// Update shadow register on the VSYNC signal edge
		// and allow loading during periods when PWM is disabled.
		//
		if ((~PWM_EN) || DUTY_CYCLE_TOGGLE)
			duty_cycle_reg_a <= DUTY_CYCLE_REG;

	    duty_0_cnt    <= duty_0_cnt_nxt;
		duty_0_cnt_tc <= duty_0_cnt_tc_nxt;

		if (FREQ_COUNTER_EN || duty_cycle_cnt_ld || duty_0_cnt_tc)
		begin
	        duty_1_cnt    <= duty_1_cnt_nxt;
		    duty_1_cnt_tc <= duty_1_cnt_tc_nxt;
        end

		duty_cycle_cnt_ld <= duty_cycle_cnt_ld_nxt;
		duty_cycle_cnt_tc <= duty_cycle_cnt_tc_nxt;
		duty_cycle_ld_tc  <= duty_cycle_ld_tc_nxt;

		PWM_r <= PWM_nxt;
    end      
end


// Define when the Duty Cycle Counter is done
//
// Note: The Duty Cycle Counter's value should always be less than or equal 
//       to the Frequency Counter's value. However, if the Frequency Counter
//       value is smaller then the Duty Cycle Counter, the terms below will
//       correctly maintain counter loading. 
//
//       In addition, these terms allow for proper loading when the PWM is disabled.
//
//assign duty_cycle_cnt_tc_nxt = (FREQ_COUNTER_EN || duty_cycle_cnt_ld) ? duty_cycle_ld_tc : duty_0_cnt_tc_nxt & duty_1_cnt_tc & duty_2_cnt_tc & duty_3_cnt_tc;
assign duty_cycle_cnt_tc_nxt = (FREQ_COUNTER_EN || duty_cycle_cnt_ld) ? duty_cycle_ld_tc : duty_0_cnt_tc_nxt & duty_1_cnt_tc;


// Define the Terminal Count for a load of zero
//
// Note: The register, duty_cycle_reg_a, is a static register that is only
//       updated following VSYNC.
//
//       This was done in this way to avoid having to decode 32-bits at a time
//       to address certain corner cases. These cases should not happen if the 
//       correct values are loaded into the Frequency and Duty Cycle Counters.
//
assign duty_cycle_ld_tc_nxt  = (duty_cycle_reg_a[15:0] == 32'h0) ? 1'b1: 1'b0;


// Define the Duty Cycle Counter's statemachine
//
// Note: The PWM starts at the begining of each Frequency Counter Cycle and
//       then should shut off until the start of the next cycle.
//
//       This statemachine handles conditions when the Duty Cycle Counter
//       value is below, equal to, or above the Frequency Counter value.
//
always @(duty_cycle_state      or
		 PWM_EN                or
         FREQ_COUNTER_EN       or
		 duty_cycle_cnt_tc_nxt or
		 duty_cycle_cnt_tc
        )
begin
    case(duty_cycle_state)
	DUTY_IDLE_ST:
	begin
		case(PWM_EN)
		1'b0: // Waiting for the PWM to be enabled
		begin
			duty_cycle_state_nxt  <= DUTY_IDLE_ST;

			duty_cycle_cnt_ld_nxt <= 1'b1;
			PWM_nxt               <= 1'b0;
		end
		1'b1:  // The PWM has been enabled
		begin
			duty_cycle_state_nxt  <= DUTY_COUNT_ST;

			duty_cycle_cnt_ld_nxt <=  duty_cycle_cnt_tc_nxt;
			PWM_nxt               <=  1'b1;
		end
        endcase
	end
    DUTY_COUNT_ST:
	begin
		case({PWM_EN, FREQ_COUNTER_EN, duty_cycle_cnt_tc})
		3'b100: // The Duty Cycle is counting down
		begin
			duty_cycle_state_nxt  <= DUTY_COUNT_ST;

			duty_cycle_cnt_ld_nxt <= duty_cycle_cnt_tc_nxt;
			PWM_nxt               <= 1'b1;
		end
		3'b101: // The Frequency Count is longer than the Duty Cycle.
		begin
			duty_cycle_state_nxt  <= DUTY_WAIT_ST;

			duty_cycle_cnt_ld_nxt <= 1'b1;
			PWM_nxt               <= 1'b0;
		end
		3'b110: // The Frequency Count is shorter than the Duty Cycle count.
		        // Note: For proper operation, the Frequency Count should 
				//       never be shorter than the Duty Cycle.
		begin
			duty_cycle_state_nxt  <= DUTY_COUNT_ST;

			duty_cycle_cnt_ld_nxt <= 1'b0;
			PWM_nxt               <= 1'b1;
		end
		3'b111: // The Frequency Count is the same as the Duty Cycle.
		begin
			duty_cycle_state_nxt  <= DUTY_COUNT_ST;

			duty_cycle_cnt_ld_nxt <= 1'b0;
			PWM_nxt               <= 1'b1;
		end
		default: // The PWM has been disabled.
		begin
			duty_cycle_state_nxt  <= DUTY_IDLE_ST;

			duty_cycle_cnt_ld_nxt <= 1'b1;
			PWM_nxt               <= 1'b0;
		end
        endcase
	end
    DUTY_WAIT_ST:
	begin
		case({PWM_EN, FREQ_COUNTER_EN})
		2'b10: // Waiting for the Frequency Counter to count down
		begin
			duty_cycle_state_nxt  <= DUTY_WAIT_ST;

			duty_cycle_cnt_ld_nxt <= 1'b1;
			PWM_nxt               <= 1'b0;
		end
		2'b11: // Frequency Counter has finished
		begin
			duty_cycle_state_nxt  <= DUTY_COUNT_ST;

			duty_cycle_cnt_ld_nxt <=  duty_cycle_cnt_tc_nxt;
			PWM_nxt               <=  1'b1;
		end
		default: // The PWM has been disabled
		begin
			duty_cycle_state_nxt  <= DUTY_IDLE_ST;

			duty_cycle_cnt_ld_nxt <= 1'b1;
			PWM_nxt               <= 1'b0;
		end
        endcase
	end
	default: // An unexpected condition has happened
	begin
		duty_cycle_state_nxt  <= DUTY_IDLE_ST;

		duty_cycle_cnt_ld_nxt <= 1'b1;
		PWM_nxt               <= 1'b0;
	end
	endcase
end

// Determine the duty cycle counter's first byte
//
// Note: The Duty Cycle Counter is define in terms of bytes to enable higher
//       speed operation.
//
always @(duty_cycle_cnt_ld or
		 duty_0_cnt        or
		 duty_cycle_reg_a  or
		 FREQ_COUNTER_EN
)
begin
	case({FREQ_COUNTER_EN, duty_cycle_cnt_ld})
	2'b00:   duty_0_cnt_nxt <= duty_0_cnt - 8'h1;
	default: duty_0_cnt_nxt <= duty_cycle_reg_a[7:0];
    endcase

	case({FREQ_COUNTER_EN, duty_cycle_cnt_ld})
	2'b00:   duty_0_cnt_tc_nxt <= (duty_0_cnt            == 8'h1);
	default: duty_0_cnt_tc_nxt <= (duty_cycle_reg_a[7:0] == 8'h0);
    endcase
end

// Determine the duty cycle counter's second byte
//
always @(duty_cycle_cnt_ld or
		 duty_1_cnt        or
		 duty_cycle_reg_a  or
		 FREQ_COUNTER_EN
)
begin
	case({FREQ_COUNTER_EN, duty_cycle_cnt_ld})
	2'b00:   duty_1_cnt_nxt <= duty_1_cnt - 8'h1;
	default: duty_1_cnt_nxt <= duty_cycle_reg_a[15:8];
    endcase

	case({FREQ_COUNTER_EN, duty_cycle_cnt_ld})
	2'b00:   duty_1_cnt_tc_nxt <= (duty_1_cnt             == 8'h1);
	default: duty_1_cnt_tc_nxt <= (duty_cycle_reg_a[15:8] == 8'h0);
    endcase
end

endmodule
