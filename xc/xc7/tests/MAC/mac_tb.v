//////////////////////////////////////////////////////////////////////////////////
// Company: SymbiFlow
// Engineer: Ajinkya.S.Raghuwanshi
// 
// Design Name: Multiply Block
// Module Name: multi_tb
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board
// Tool Versions: 
// Description: 
// 
// Here we are testing the block by applying some 
// user defined inputs to it 
// But the inputs should be in the range provided by 
// the register width.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



// This is a testbench to test the working of the multiply  module

module multi_tb();
reg [17:0] a,b;
wire [35:0] p;
reg clk;
initial clk = 0;
always #10 clk = ~clk;
mac_dsp dsp (.a(a),.b(b),.c(c),.p(p),.clk(clk));
initial begin
    a = 18'd1;
    b = 18'd2;
    
    
    #100 a = 18'd1;
        b = 18'd1;
        
        
    #100 a = 18'd4;
                b = 18'd5;
                
    
end

endmodule
