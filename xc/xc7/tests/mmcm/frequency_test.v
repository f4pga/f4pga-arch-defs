`include "clock_tester.v"

`default_nettype none
`timescale 1ns / 1ps

module top (
    input  wire clk,     
    input  wire rst,     
    output wire  [2:0] led
    );

    wire clk_fb_mmcm, clk_fb_pll;         
    wire clk_out_mmcm, clk_out_pll;        
    wire locked_mmcm, locked_pll;     
    wire clk_buff_mmcm, clk_buff_pll;    

    
    
    MMCME2_ADV #(
        .CLKFBOUT_MULT_F(9),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DIVIDE_F(36),
        .CLKOUT1_DIVIDE(1),  
        .DIVCLK_DIVIDE(1)
    ) MMCME2_ADV_inst (
        .CLKIN1(clk),
        .RST(rst),
        .CLKOUT0(clk_out_mmcm),
        .LOCKED(locked_mmcm),
        .CLKFBOUT(clk_fb_mmcm),
        .CLKFBIN(clk_fb_mmcm),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .PWRDWN()
    );  

    
    
 PLLE2_ADV #(
        .CLKFBOUT_MULT(9),
        .CLKIN1_PERIOD(10.0),
        .CLKOUT0_DIVIDE(36),
        .CLKOUT1_DIVIDE(1),  
        .DIVCLK_DIVIDE(1)
    ) PLLE2_ADV_inst (
        .CLKIN1(clk),
        .RST(rst),
        .CLKOUT0(clk_out_pll),
        .LOCKED(locked_pll),
        .CLKFBOUT(clk_fb_pll),
        .CLKFBIN(clk_fb_pll),
        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5()
    );
    

    BUFG bufg_clk_pll(.I(clk_out_pll), .O(clk_buff_pll));
    BUFG bufg_clk_mmcm(.I(clk_out_mmcm), .O(clk_buff_mmcm));


    clock_tester #(100000000) T0 (clk, led[0]);
    clock_tester #(25000000) T1 (clk_buff_pll, led[1]);
    clock_tester #(25000000) T2 (clk_buff_mmcm, led[2]);

endmodule
