
`timescale 1ns / 1ps

module multiplier_8bit_tb( );
    reg [7:0] x0;
    reg [7:0] y0;
    wire [15:0] mult_out;
    reg status; 

    multiplier_8bit DUT (
        .\a_in[0] (x0[0]), .\a_in[1] (x0[1]), .\a_in[2] (x0[2]), .\a_in[3] (x0[3]), .\a_in[4] (x0[4]), .\a_in[5] (x0[5]), .\a_in[6] (x0[6]), .\a_in[7] (x0[7]), .\b_in[0] (y0[0]), .\b_in[1] (y0[1]), .\b_in[2] (y0[2]), .\b_in[3] (y0[3]), .\b_in[4] (y0[4]), .\b_in[5] (y0[5]), .\b_in[6] (y0[6]), .\b_in[7] (y0[7]),	.\prod[0] (mult_out[0]), .\prod[1] (mult_out[1]), .\prod[2] (mult_out[2]), .\prod[3] (mult_out[3]), .\prod[4] (mult_out[4]), .\prod[5] (mult_out[5]), .\prod[6] (mult_out[6]), .\prod[7] (mult_out[7]), .\prod[8] (mult_out[8]), .\prod[9] (mult_out[9]), .\prod[10] (mult_out[10]), .\prod[11] (mult_out[11]), .\prod[12] (mult_out[12]), .\prod[13] (mult_out[13]), .\prod[14] (mult_out[14]), .\prod[15] (mult_out[15]));

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
    $display("\t\ttime,\tx0,\ty0,\tmult_out"); 
    $monitor("%d :\t[%d] X\t[%d] \t= [%d]",$time,x0,y0,mult_out);
    if(status == 1'b0)
	 $display("PASS"); 

  end 
 
initial
#500 $finish;


endmodule
