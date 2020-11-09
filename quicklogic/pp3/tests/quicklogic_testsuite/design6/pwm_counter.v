// file           	: pwm_counter.v 
// description  	: PWM counter file
// Modified       	: 2013/27/09 
// Modified by     	: Rakesh Moolacheri	
// -----------------------------------------------------------------------------
// copyright (c) 2012
// -----------------------------------------------------------------------------
// revisions  :
// date            version    author              description
// 2009/10/16       1.0        XXXXX               created
// -----------------------------------------------------------------------------
// Comments: 
// -----------------------------------------------------------------------------
`timescale 1ns/10ps

module pwm_counter (
                CLK,
                RST,

                FREQ_CYCLE_REG, 
                FREQ_CYCLE_TOGGLE, 

                DUTY_CYCLE_REG,
                DUTY_CYCLE_TOGGLE,

                PWM_ENA,
				idle_pol,

                PWM
                );


// Define I/O port properties
//
input           CLK;
input           RST;

input   [15:0]  FREQ_CYCLE_REG;
//input    [1:0]  FREQ_CYCLE_TOGGLE;
input    FREQ_CYCLE_TOGGLE;

input   [15:0]  DUTY_CYCLE_REG;
//input    [1:0]  DUTY_CYCLE_TOGGLE;
input    DUTY_CYCLE_TOGGLE;

input           PWM_ENA; 
input           idle_pol;
   
output          PWM;

   
wire            CLK;
wire            RST;

wire    [15:0]  FREQ_CYCLE_REG;
wire      FREQ_CYCLE_TOGGLE;

wire    [15:0]  DUTY_CYCLE_REG;
wire      DUTY_CYCLE_TOGGLE;

wire            PWM_ENA;
   
wire            PWM;
   

// Define internal signals
wire            freq_counter_en;

// Counter instantiations
//
 freq_counter freq_counter_inst (
     .RST            (RST),
     .CLK             (CLK),
     .FREQ_CYCLE_TOGGLE          (FREQ_CYCLE_TOGGLE),
     .FREQ_CYCLE_REG     (FREQ_CYCLE_REG),
     .PWM_EN             (PWM_ENA),
     .FREQ_COUNTER_EN    (freq_counter_en)
   );
   
   
 duty_cycle_count duty_cycle_count_inst(
     .RST            (RST),
     .CLK             (CLK),
     .DUTY_CYCLE_TOGGLE          (DUTY_CYCLE_TOGGLE),
     .DUTY_CYCLE_REG     (DUTY_CYCLE_REG),
     .PWM_EN             (PWM_ENA),
	 .idle_pol		(idle_pol),
     .FREQ_COUNTER_EN    (freq_counter_en),
     .PWM                (PWM)
   );   
   
endmodule   
