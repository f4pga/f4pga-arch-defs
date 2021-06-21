// This is a test in order to verify the [A+D+Carryin] instruction of the dsp

module top_module( 
    input [16:0] sw,
    output [8:0] led);

    
    wire [7:0] a,b;
    wire cin;
    wire cout;
    wire [7:0] sum;
    assign a = sw[7:0];
    assign b = sw[15:8];
    assign cin = sw[16];
    assign led = {cout,sum};
	wire c10;
    bcd_fadd inst1 (.a(a[3:0]), .b(b[3:0]), .cin(cin), .cout(c10), .sum(sum[3:0]));
    bcd_fadd inst2 (.a(a[7:4]), .b(b[7:4]), .cin(c10), .cout(cout), .sum(sum[7:4]));
endmodule

module bcd_fadd (
    input [3:0] a, b,
    input cin,
    output cout,
    output [3:0] sum
);
//Internal variables
    reg [4:0] sum_temp;
    reg [3:0] sum;
    reg cout;  

//always block for doing the addition
    always @(a,b,cin)
    begin
        sum_temp = a+b+cin; //add all the inputs
        if(sum_temp > 9)    begin
            sum_temp = sum_temp+6; //add 6, if result is more than 9.
            cout = 1;  //set the carry output
            sum = sum_temp[3:0];    end
        else    begin
            cout = 0;
            sum = sum_temp[3:0];
        end
    end 
    
endmodule