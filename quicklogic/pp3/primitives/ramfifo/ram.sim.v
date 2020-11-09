`timescale 10 ps /1 ps

`define DATAWID 18 
`define WEWID 2

module ram(
						AA,
						AB,
						CLKA,
						CLKB,
						WENA,
						WENB,
						CENA,
						CENB,
						WENBA,
						WENBB,
						DA,
						QA,
						DB,
						QB
					);


parameter ADDRWID = 8;
parameter DEPTH = (1<<ADDRWID);
parameter [9215:0] init_1 = 9216'bx;

	output	[`DATAWID-1:0]	QA;
	input										CLKA;
	input										CENA;
	input										WENA;
	input		[`WEWID-1:0]		WENBA;
	input		[ADDRWID-1:0]	AA;
	input		[`DATAWID-1:0]	DA;
	output	[`DATAWID-1:0]	QB;
	
	input										CLKB;
	input										CENB;
	input										WENB;
	input		[`WEWID-1:0]		WENBB;
	input		[ADDRWID-1:0]	AB;
	input		[`DATAWID-1:0]	DB;
	
	integer	i, j, k, l, m;

	wire									CEN1;
	wire									OEN1;
	wire									WEN1;
	wire	[`WEWID-1:0]		WENB1;
	wire	[ADDRWID-1:0]	A1;

	reg	[ADDRWID-1:0]	AddrOut1;
	wire	[`DATAWID-1:0]	I1;
	
	wire									CEN2;
	wire									OEN2;
	wire									WEN2;
	wire	[`WEWID-1:0]		WENB2;
	wire	[ADDRWID-1:0]	A2;

	reg	[ADDRWID-1:0]	AddrOut2;
	wire	[`DATAWID-1:0]	I2;
	
	reg		[`DATAWID-1:0]	O1, QAreg;
	reg		[`DATAWID-1:0]	O2, QBreg;
	
	reg										WEN1_f;
	reg										WEN2_f;
	reg	[ADDRWID-1:0]	A2_f;
	reg	[ADDRWID-1:0]	A1_f;
	
	wire									CEN1_SEL;
	wire									WEN1_SEL;
	wire	[ADDRWID-1:0]	A1_SEL;
	wire	[`DATAWID-1:0]	I1_SEL;
	wire	[`WEWID-1:0]		WENB1_SEL;
	
	wire									CEN2_SEL;
	wire									WEN2_SEL;
	wire	[ADDRWID-1:0]	A2_SEL;
	wire	[`DATAWID-1:0]	I2_SEL;
	wire	[`WEWID-1:0]		WENB2_SEL;
	wire  overlap;
	
	wire CLKA_d, CLKB_d, CEN1_d, CEN2_d;
	
	assign	A1_SEL    = AA;
	assign	I1_SEL    = DA;
	assign	CEN1_SEL  = CENA;
	assign	WEN1_SEL  = WENA;
	assign	WENB1_SEL = WENBA;
	
	assign	A2_SEL    = AB;
	assign	I2_SEL    = DB;
	assign	CEN2_SEL  = CENB;
	assign	WEN2_SEL  = WENB;
	assign	WENB2_SEL = WENBB;
	
	assign	CEN1	= CEN1_SEL;
	assign	OEN1	= 1'b0;                           
	assign	WEN1	= WEN1_SEL;
	assign	WENB1	= WENB1_SEL;
	assign	A1		= A1_SEL;
	assign	I1		= I1_SEL;
	
	assign	CEN2	= CEN2_SEL;
	assign	OEN2	= 1'b0;
	assign	WEN2	= WEN2_SEL;
	assign	WENB2	= WENB2_SEL;
	assign	A2		= A2_SEL;
	assign	I2		= I2_SEL;

	reg		[`DATAWID-1:0]	ram[DEPTH-1:0];
	reg		[`DATAWID-1:0]	wrData1;
	reg		[`DATAWID-1:0]	wrData2;
	wire	[`DATAWID-1:0]	tmpData1;
	wire	[`DATAWID-1:0]	tmpData2;
	
reg CENreg1, CENreg2;

assign #1 CLKA_d = CLKA;
assign #1 CLKB_d = CLKB;

assign #2 CEN1_d = CEN1;
assign #2 CEN2_d = CEN2;

assign	QA = QAreg | O1;
assign	QB = QBreg | O2;

	assign	tmpData1	= ram[A1];
	assign	tmpData2	= ram[A2];
	
	assign	overlap	= ( A1_f == A2_f ) & WEN1_f & WEN2_f;
	
	initial
	begin
		for( i = 0; i < DEPTH; i = i+1 )
		begin
			//ram[i]	= 18'bxxxxxxxxxxxxxxxxxx;
			ram[i] <= init_1[16*i +: 16];
		end
	end
	
	always@( WENB1 or I1 or tmpData1 )
	begin
		for( j = 0; j < 9; j = j+1 )
		begin
			wrData1[j]	<= ( WENB1[0] ) ? tmpData1[j] : I1[j];
		end
		for( l = 9; l < 19; l = l+1 )
		begin
			wrData1[l]	<= ( WENB1[1] ) ? tmpData1[l] : I1[l];
		end
	end
	
	always@( posedge CLKA )
	begin
		if( ~WEN1 & ~CEN1 )
		begin
			ram[A1]	<= wrData1[`DATAWID-1:0];
		end
	end
	
	always@( posedge CLKA_d)
    if(~CEN1_d)
	    begin
	      O1	= 18'h3ffff;
        #100;
		    O1	= 18'h00000;
		end
	

	always@( posedge CLKA )
		if (~CEN1)
			begin
			AddrOut1 <= A1;
			end

	always@( posedge CLKA_d)
		if (~CEN1_d)
			begin
			QAreg <= ram[AddrOut1];
			end


	always@( posedge CLKA )
	begin
		WEN1_f	<= ~WEN1 & ~CEN1;
		A1_f<= A1;
		
	end
	
	always@( WENB2 or I2 or tmpData2 )
	begin
		for( k = 0; k < 9; k = k+1 )
		begin
			wrData2[k]	<= ( WENB2[0] ) ? tmpData2[k] : I2[k];
		end
		for( m = 9; m < 19; m = m+1 )
		begin
			wrData2[m]	<= ( WENB2[1] ) ? tmpData2[m] : I2[m];
		end
	end
	
	always@( posedge CLKB )
	begin
		if( ~WEN2 & ~CEN2 )
		begin
			ram[A2]	<= wrData2[`DATAWID-1:0];
		end
	end

	always@( posedge CLKB_d )
    if(~CEN2_d)
	    begin
	      O2	= 18'h3ffff;
        #100;
		    O2	= 18'h00000;
		end

	always@( posedge CLKB )
		if (~CEN2)
			begin
			AddrOut2 <= A2;
			end

	always@( posedge CLKB_d )
		if (~CEN2_d)
			begin
			QBreg <= ram[AddrOut2];
			end

	always@( posedge CLKB )
	begin
		WEN2_f	<= ~WEN2 & ~CEN2;
		A2_f<=A2;
		
	end

	always@( A1_f or A2_f or overlap)
	begin
		if( overlap )
		begin
			ram[A1_f]	<= 18'bxxxxxxxxxxxxxxxxxx;
		end
	end

endmodule