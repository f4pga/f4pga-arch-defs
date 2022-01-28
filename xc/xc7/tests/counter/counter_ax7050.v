//===========================================================================
// Module name: led_test.v
//===========================================================================
`timescale 1ns / 1ps

module top 
(             
  sys_clk,      // system clock 50Mhz on board
  rst_n,          // reset ,low active            
  led             // LED,use for control the LED signal on board
 );
             
//===========================================================================
// PORT declarations
//===========================================================================

input         sys_clk;
input         rst_n;
output [3:0]  led;

//define the time counter
reg [31:0]   timer;                  
reg [3:0]    led;

          
//===========================================================================
// cycle counter:from 0 to 4 sec
//===========================================================================
  always @(posedge sys_clk or negedge rst_n)    
    begin
      if (~rst_n)                           
          timer <= 32'd0;                     // when the reset signal valid,time counter clearing
      else if (timer == 32'd199_999_999)    //4 seconds count(50M*4-1=199999999)
          timer <= 32'd0;                       //count done,clearing the time counter
      else
		    timer <= timer + 1'b1;            //timer counter = timer counter + 1
    end

//===========================================================================
// LED control
//===========================================================================
  always @(posedge sys_clk or negedge rst_n)   
    begin
      if (~rst_n)                      
          led <= 4'b0000;                  //when the reset signal active         
      else if (timer == 32'd49_999_999)    //time counter count to 1st sec,LED1 lighten
    
          led <= 4'b1100;                 
      else if (timer == 32'd99_999_999)    //time counter count to 2nd sec,LED2 lighten
      begin
          led <= 4'b0011;                  
        end
      else if (timer == 32'd149_999_999)   //time counter count to 3nd sec,LED3 lighten
          led <= 4'b1100;                                          
      else if (timer == 32'd199_999_999)   //time counter count to 4nd sec,LED4 lighten
          led <= 4'b0011;                         
    end
    
endmodule
