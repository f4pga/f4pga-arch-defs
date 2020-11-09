`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Team: Virginia Tech Secure Embedded Systems (SES) Lab 
// Implementer: Ege Gulcan
// 
////////////////////////////////////////////////////////////////////////////////

module top_module_test;

	// Inputs
	reg clk;
	reg data_in;
	reg [1:0] data_rdy;

	// Outputs
	wire cipher_out;
	
	// Plaintext and key from the NSA Simon and Speck paper
	reg [127:0] plaintext = 128'h63736564207372656c6c657661727420;
	reg [127:0] key = 128'h0f0e0d0c0b0a09080706050403020100;
	
	integer i;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk(clk), 
		.data_in(data_in), 
		.data_rdy(data_rdy), 
		.cipher_out(cipher_out)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		data_in = 0;
		data_rdy = 0;

		#110;
		#5;
		//Set data_rdy=1 to load plaintext
		data_rdy=1;
		
		//Loads the plaintext one bit per clock cycle for 128 cycles
		for(i=0;i<128;i = i+1)
		begin
			data_in = plaintext[i];
			#20;
		end
		
		//Set data_rdy=2 to load key
		data_rdy = 2;
			
		//Loads the key one bit per clock cycle for 128 cycles
		for(i=0;i<128;i = i+1)
		begin
			data_in = key[i];
			#20;
		end
		//Set data_rdy=0 after loading is done
		data_rdy = 0;
		#20;
		
		//Keep data_rdy=3 while the cipher is running
		data_rdy = 3;


	end
	

	
	always #10 clk = ~clk;
 
  initial  begin
    $dumpfile("Simon_bit_serial_tb.vcd");
    $dumpvars(0,top_module_test);
    $display("\t\ttime,\tclk,\tdata_in,\tdata_rdy,\tcipher_out"); 
    $monitor("%d,\t%b,\t%b,\t%b,\t%d",$time, clk,data_in,data_rdy,cipher_out); 
  end 

 
initial
#10000 $finish;
      
endmodule

