
`timescale 1ns / 1ps

module multiplier_8bit_tb( );
    reg [7:0] x0;
    reg [7:0] y0;
    wire [15:0] mult_out;
    reg status; 

    multiplier_8bit DUT (
        .a_in(x0),
	.b_in(y0),
	.prod(mult_out));

    initial begin
	    status = 0;
	    x0 =0;
	    y0 =0;
	    #50 x0 = 25;
	    #20 y0 = 93;
	    #10
 	    if(mult_out == 2325)
		    $display("Valid Output");
	    else begin
		    $display("FAIL");
	            $fatal(2,"Mult output does not match");
		    status =1;
	    end

	    #50 y0 = 87;
            #10  
	    if(mult_out == 2175)
		    $display("Valid Output");
	    else
	    begin
		    $display("FAIL");
	            $fatal(2,"Mult output does not match");
		    status =1;
	    end


    end


  initial  begin
    $dumpfile("multiplier_8bit_tb.vcd");
    $dumpvars(0,multiplier_8bit_tb);
    $sdf_annotate("multiplier_8bit_post_synthesis.sdf", DUT);
    $display("\t\ttime,\tx0,\ty0,\tmult_out"); 
    $monitor("%d :\t[%d] X\t[%d] \t= [%d]",$time,x0,y0,mult_out);
    if(status == 1'b0)
	 $display("PASS"); 

  end 
 
initial
#500 $finish;


endmodule
