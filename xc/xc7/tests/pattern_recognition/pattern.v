//////////////////////////////////////////////////////////////////////////////////
// Company: SymbiFlow
// Engineer: Ajinkya.S.Raghuwanshi
// 
// Design Name: Pattern Recognition
// Module Name: pattern
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board
// Tool Versions: 
// Description: 
//
// This is a module used to give the output as 1 
// whenever the desired pattern provided in the input
// is found to match the data in the register present 
// inside the DSP.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pattern(
    input CLK,
    input CE,
    input [47:0] DATA_IN,
    input RST,
    output Q,
    input DYNAMIC_PATTERN

    );
    
    // Now from here user can specify what kind of pattern recognition
    // and its properties the user desires
    // Here below I have defined the description of each and 
    // every input as well as output
    // user can change gowever they want
    
     
       EQ_COMPARE_MACRO #(
       .DEVICE("7SERIES"),       // Target Device: "7SERIES" 
       .LATENCY(2),              // Desired clock cycle latency, 0-2
       .MASK(48'h000000000000),  // Select bits to be masked, must set SEL_MASK="MASK" 
       .SEL_MASK("MASK"),        // "MASK" = use MASK parameter,
       .SEL_PATTERN("STATIC_PATTERN"), // "STATIC_PATTERN" = use STATIC_PATTERN parameter,
       // .SEL_PATTERN("DYNAMIC_PATTERN"),  //   "DYNAMIC_PATTERN = use DYNAMIC_PATTERN input bus
       .STATIC_PATTERN(48'h000000000000), // Specify static pattern, must set SEL_PATTERN = "STATIC_PATTERN" 
       .WIDTH(48)                // Comparator output bus width, 1-48
    ) EQ_COMPARE_MACRO_inst (
       .Q(Q),     // 1-bit output indicating a match
       .CE(CE),   // 1-bit active high input clock enable
       .CLK(CLK), // 1-bit positive edge clock input
       .DATA_IN(DATA_IN), // Input Data Bus, width determined by WIDTH parameter 
       .DYNAMIC_PATTERN(DYNAMIC_PATTERN), // Input Dynamic Match/Mask Bus, width determined by WIDTH parameter 
       .RST(RST)  // 1-bit input active high reset
    );
endmodule
