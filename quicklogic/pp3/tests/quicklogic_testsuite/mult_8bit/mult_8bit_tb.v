`timescale 1ns / 1ps

module mult_tb( );
    reg [7:0] x0;
    reg [7:0] y0;
    wire [15:0] A0;
    wire [15:0] out0;
    wire [15:0] out1;

    reg [1:0] valid;

    top mul0 (
        .x0(x0),
        .y0(y0),
	.A0(A0),
        .valid(valid)
    );

    initial begin
	    x0 =0;
	    y0 =0;
	    valid =0;
	    #20 valid = 2'b11;
	    #50 x0 = 25;
	    #20 y0 = 93;
	    #10
	    	    if(A0 == 2325)
		    $display("PASS");
	    else begin
		    $display("FAIL");
	            $fatal(2,"Mult output does not match");
	    end

	    #50 y0 = 87;
            #10  
	    if(A0 == 2175)
		    $display("PASS");
	    else
	    begin
		    $display("FAIL");
	            $fatal(2,"Mult output does not match");
	    end


    end


  initial  begin
    $dumpfile("mult_tb.vcd");
    $dumpvars(0,mult_tb);
    $display("\t\ttime,\tx0,\ty0,\tValid,\tA0"); 
    $monitor("%d,\t%d,\t%d,\t%d,\t%d",$time,x0,y0,valid,A0); 
  end 

 
initial
#500 $finish;


endmodule
