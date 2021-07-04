//////////////////////////////////////////////////////////////////////////////////
// Design Name: Multiply and Accumulate Block
// Module Name: mac_tb
// Project Name: DSP48E1 use in Artix7 board
// Target Devices: ARTIX7 Board 
// Description: 
// 
// Here we are testing the block by applying some 
// user defined inputs to it 
// But the inputs should be in the range provided by 
// the register width.
//
// 
//////////////////////////////////////////////////////////////////////////////////



// This is a testbench to test the working of the multiply and accumulate module

module mac_tb();
reg [17:0] a,b;
reg [47:0] c;
wire [47:0] p;
reg clk;
initial clk = 0;
always #10 clk = ~clk;
mac_dsp dsp (.a(a),.b(b),.c(c),.p(p),.clk(clk));
initial begin
    a = 18'd1;
    b = 18'd2;
    c = 48'd3;
    
    #100 a = 18'd1;
        b = 18'd1;
        c = 48'd1;
        
    #100 a = 18'd4;
                b = 18'd5;
                c = 48'd6;
    
end

endmodule
