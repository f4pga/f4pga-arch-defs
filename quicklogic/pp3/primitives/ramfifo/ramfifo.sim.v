`timescale 1 ns /10 ps
`define DATAWID 18
`define WEWID 2
module x2_model(
									Concat_En,
									
									ram0_WIDTH_SELA,
									ram0_WIDTH_SELB,
									ram0_PLRD,
									
									ram0_CEA,
									ram0_CEB,
									ram0_I,
									ram0_O,
									ram0_AA,
									ram0_AB,
									ram0_CSBA,
									ram0_CSBB,
									ram0_WENBA,
									
									ram1_WIDTH_SELA,
									ram1_WIDTH_SELB,
									ram1_PLRD,
									
									ram1_CEA,
									ram1_CEB,
									ram1_I,
									ram1_O,
									ram1_AA,
									ram1_AB,
									ram1_CSBA,
									ram1_CSBB,
									ram1_WENBA
								);

parameter ADDRWID = 10;	
parameter [18431:0] INIT = 18432'bx;							

	input										Concat_En;      
	
	input		[1:0]						ram0_WIDTH_SELA;
	input		[1:0]						ram0_WIDTH_SELB;
	input										ram0_PLRD;      
	input										ram0_CEA;
	input										ram0_CEB;
	input		[`DATAWID-1:0]	ram0_I;
	output	[`DATAWID-1:0]	ram0_O;
	input		[ADDRWID-1:0]	ram0_AA;
	input		[ADDRWID-1:0]	ram0_AB;
	input										ram0_CSBA;
	input										ram0_CSBB;
	input		[`WEWID-1:0]		ram0_WENBA;
	
	input		[1:0]						ram1_WIDTH_SELA;
	input		[1:0]						ram1_WIDTH_SELB;
	input										ram1_PLRD;
	input										ram1_CEA;
	input										ram1_CEB;
	input		[`DATAWID-1:0]	ram1_I;
	output	[`DATAWID-1:0]	ram1_O;
	input		[ADDRWID-1:0]	ram1_AA;
	input		[ADDRWID-1:0]	ram1_AB;
	input										ram1_CSBA;
	input										ram1_CSBB;
	input 	[`WEWID-1:0]		ram1_WENBA;
	
	reg										ram0_PLRDA_SEL;
	reg										ram0_PLRDB_SEL;
	reg										ram1_PLRDA_SEL;
	reg										ram1_PLRDB_SEL;
	reg										ram_AA_ram_SEL; 
	reg										ram_AB_ram_SEL;

	reg		[`WEWID-1:0]		ram0_WENBA_SEL;
	reg		[`WEWID-1:0]		ram0_WENBB_SEL;
	reg		[`WEWID-1:0]		ram1_WENBA_SEL;
	reg		[`WEWID-1:0]		ram1_WENBB_SEL;
	
  reg										ram0_A_x9_SEL;
  reg										ram0_B_x9_SEL;
  reg										ram1_A_x9_SEL;
  reg										ram1_B_x9_SEL;
  
	reg		[ADDRWID-3:0]	ram0_AA_SEL;
	reg		[ADDRWID-3:0]	ram0_AB_SEL;
	reg		[ADDRWID-3:0]	ram1_AA_SEL;
	reg		[ADDRWID-3:0]	ram1_AB_SEL;

	reg										ram0_AA_byte_SEL;
	reg										ram0_AB_byte_SEL;
	reg										ram1_AA_byte_SEL;
	reg										ram1_AB_byte_SEL;
	
	reg										ram0_AA_byte_SEL_Q;
	reg										ram0_AB_byte_SEL_Q;
	reg										ram1_AA_byte_SEL_Q;
	reg										ram1_AB_byte_SEL_Q;
	reg										ram0_A_mux_ctl_Q;
	reg										ram0_B_mux_ctl_Q;
	reg										ram1_A_mux_ctl_Q;
	reg										ram1_B_mux_ctl_Q;
	
  reg										ram0_O_mux_ctrl_Q;
  reg										ram1_O_mux_ctrl_Q;
  
	reg										ram_AA_ram_SEL_Q;
	reg										ram_AB_ram_SEL_Q;

	wire	[`DATAWID-1:0]	QA_1_SEL3;
	wire	[`DATAWID-1:0]	QB_0_SEL2;
	wire	[`DATAWID-1:0]	QB_1_SEL2;
  
	reg		[`DATAWID-1:0]	QA_0_Q;
	reg		[`DATAWID-1:0]	QB_0_Q;
	reg		[`DATAWID-1:0]	QA_1_Q;
	reg		[`DATAWID-1:0]	QB_1_Q;
	
	wire	[`DATAWID-1:0]	QA_0;
	wire	[`DATAWID-1:0]	QB_0;
	wire	[`DATAWID-1:0]	QA_1;
	wire	[`DATAWID-1:0]	QB_1;

	wire									ram0_CSBA_SEL;
	wire									ram0_CSBB_SEL;
	wire									ram1_CSBA_SEL;
	wire									ram1_CSBB_SEL;
	
	wire	[`DATAWID-1:0]	ram0_I_SEL1;
	wire	[`DATAWID-1:0]	ram1_I_SEL1;
	
	wire									dual_port;
	
	wire									ram0_WEBA_SEL;
	wire									ram0_WEBB_SEL;
	wire									ram1_WEBA_SEL;
	wire									ram1_WEBB_SEL;
	
	wire	[`DATAWID-1:0]	ram1_I_SEL2;
	
	wire	[`DATAWID-1:0]	QA_1_SEL2;
	wire	[`DATAWID-1:0]	QA_0_SEL1;
	wire	[`DATAWID-1:0]	QB_0_SEL1;
	wire	[`DATAWID-1:0]	QA_1_SEL1;
	wire	[`DATAWID-1:0]	QB_1_SEL1;

	wire	[`DATAWID-1:0]	QB_0_SEL3;
	wire	[`DATAWID-1:0]	QA_0_SEL2;

	initial
	begin
		QA_0_Q							<= 0;
		QB_0_Q							<= 0;
		QA_1_Q							<= 0;
		QB_1_Q							<= 0;
		ram0_AA_byte_SEL_Q	<= 0;
		ram0_A_mux_ctl_Q		<= 0;
		ram0_AB_byte_SEL_Q	<= 0;
		ram0_B_mux_ctl_Q		<= 0;
		ram1_AA_byte_SEL_Q	<= 0;
		ram1_A_mux_ctl_Q		<= 0;
		ram1_AB_byte_SEL_Q	<= 0;
		ram1_B_mux_ctl_Q		<= 0;
		ram_AA_ram_SEL_Q		<= 0;
		ram1_O_mux_ctrl_Q		<= 0;
		ram_AB_ram_SEL_Q		<= 0;
		ram0_O_mux_ctrl_Q		<= 0;
	end

	assign dual_port	= Concat_En & ~( ram0_WIDTH_SELA[1] | ram0_WIDTH_SELB[1] );
	
	assign ram0_CSBA_SEL	= ram0_CSBA;
	assign ram0_CSBB_SEL	= ram0_CSBB;
	assign ram1_CSBA_SEL	= Concat_En ? ram0_CSBA : ram1_CSBA;
	assign ram1_CSBB_SEL	= Concat_En ? ram0_CSBB : ram1_CSBB;

	assign ram0_O = QB_0_SEL3;
	assign ram1_O = dual_port ? QA_1_SEL3 : QB_1_SEL2;
	
	assign ram0_I_SEL1[8:0]		= ram0_I[8:0];
	assign ram1_I_SEL1[8:0]		= ram1_I[8:0];
	assign ram0_I_SEL1[17:9]	= ram0_AA_byte_SEL ? ram0_I[8:0] : ram0_I[17:9];
	assign ram1_I_SEL1[17:9]	= ( ( ~Concat_En & ram1_AA_byte_SEL ) | ( dual_port & ram0_AB_byte_SEL ) ) ? ram1_I[8:0] : ram1_I[17:9];
	
	assign ram1_I_SEL2	= ( Concat_En & ~ram0_WIDTH_SELA[1] ) ? ram0_I_SEL1 : ram1_I_SEL1;
	
	assign ram0_WEBA_SEL	= &ram0_WENBA_SEL;
	assign ram0_WEBB_SEL	= &ram0_WENBB_SEL;
	assign ram1_WEBA_SEL	= &ram1_WENBA_SEL;
	assign ram1_WEBB_SEL	= &ram1_WENBB_SEL;

	assign QA_0_SEL1	= ( ram0_PLRDA_SEL ) ? QA_0_Q : QA_0 ;
	assign QB_0_SEL1	= ( ram0_PLRDB_SEL ) ? QB_0_Q : QB_0 ;
	assign QA_1_SEL1	= ( ram1_PLRDA_SEL ) ? QA_1_Q : QA_1 ;
	assign QB_1_SEL1	= ( ram1_PLRDB_SEL ) ? QB_1_Q : QB_1 ;
	
    assign QA_1_SEL3	= ram1_O_mux_ctrl_Q ? QA_1_SEL2 : QA_0_SEL2;
	
	assign QA_0_SEL2[8:0]	= ram0_A_mux_ctl_Q ? QA_0_SEL1[17:9] : QA_0_SEL1[8:0] ;
	assign QB_0_SEL2[8:0]	= ram0_B_mux_ctl_Q ? QB_0_SEL1[17:9] : QB_0_SEL1[8:0] ;
	assign QA_1_SEL2[8:0]	= ram1_A_mux_ctl_Q ? QA_1_SEL1[17:9] : QA_1_SEL1[8:0] ;
	assign QB_1_SEL2[8:0]	= ram1_B_mux_ctl_Q ? QB_1_SEL1[17:9] : QB_1_SEL1[8:0] ;
	
	assign QA_0_SEL2[17:9]	= QA_0_SEL1[17:9];
	assign QB_0_SEL2[17:9]	= QB_0_SEL1[17:9];
	assign QA_1_SEL2[17:9]	= QA_1_SEL1[17:9];
	assign QB_1_SEL2[17:9]	= QB_1_SEL1[17:9];

	assign QB_0_SEL3 = ram0_O_mux_ctrl_Q ? QB_1_SEL2 : QB_0_SEL2;
	
	always@( posedge ram0_CEA )
	begin
		QA_0_Q <= QA_0;
	end
	always@( posedge ram0_CEB )
	begin
		QB_0_Q <= QB_0;
	end
	always@( posedge ram1_CEA )
	begin
		QA_1_Q <= QA_1;
	end
	always@( posedge ram1_CEB )
	begin
		QB_1_Q <= QB_1;
	end

	always@( posedge ram0_CEA )
	begin
		if( ram0_CSBA_SEL == 0 )
			ram0_AA_byte_SEL_Q	<= ram0_AA_byte_SEL;
		if( ram0_PLRDA_SEL || ( ram0_CSBA_SEL == 0 ) )
			ram0_A_mux_ctl_Q	<= ram0_A_x9_SEL & ( ram0_PLRDA_SEL ? ram0_AA_byte_SEL_Q : ram0_AA_byte_SEL );
	end
	
	always@( posedge ram0_CEB)
	begin
		if( ram0_CSBB_SEL == 0 )
			ram0_AB_byte_SEL_Q	<= ram0_AB_byte_SEL;
		if( ram0_PLRDB_SEL || ( ram0_CSBB_SEL == 0 ) )
			ram0_B_mux_ctl_Q	<= ram0_B_x9_SEL & ( ram0_PLRDB_SEL ? ram0_AB_byte_SEL_Q : ram0_AB_byte_SEL );
	end
	
	always@( posedge ram1_CEA )
	begin
		if( ram1_CSBA_SEL == 0 )
			ram1_AA_byte_SEL_Q	<= ram1_AA_byte_SEL;
		if( ram1_PLRDA_SEL || (ram1_CSBA_SEL == 0 ) )
			ram1_A_mux_ctl_Q	<= ram1_A_x9_SEL & ( ram1_PLRDA_SEL ? ram1_AA_byte_SEL_Q : ram1_AA_byte_SEL );
	end
	
	always@( posedge ram1_CEB )
	begin
		if( ram1_CSBB_SEL == 0 )
			ram1_AB_byte_SEL_Q	<= ram1_AB_byte_SEL;
		if( ram1_PLRDB_SEL || (ram1_CSBB_SEL == 0 ) )
			ram1_B_mux_ctl_Q	<= ram1_B_x9_SEL & ( ram1_PLRDB_SEL ? ram1_AB_byte_SEL_Q : ram1_AB_byte_SEL );
	end

	always@( posedge ram0_CEA )
	begin
		ram_AA_ram_SEL_Q	<= ram_AA_ram_SEL;
		ram1_O_mux_ctrl_Q	<= ( ram0_PLRDA_SEL ? ram_AA_ram_SEL_Q : ram_AA_ram_SEL );
	end

	always@( posedge ram0_CEB )
	begin
		ram_AB_ram_SEL_Q	<= ram_AB_ram_SEL;
		ram0_O_mux_ctrl_Q	<= ( ram0_PLRDB_SEL ? ram_AB_ram_SEL_Q : ram_AB_ram_SEL );
	end

	always@( Concat_En or ram0_WIDTH_SELA or ram0_WIDTH_SELB or ram0_AA or ram0_AB or ram0_WENBA or 
	         ram1_AA or ram1_AB or ram1_WENBA or ram0_PLRD or ram1_PLRD or ram1_WIDTH_SELA or ram1_WIDTH_SELB ) 
	begin
		ram0_A_x9_SEL			<= ( ~|ram0_WIDTH_SELA );
		ram1_A_x9_SEL			<= ( ~|ram0_WIDTH_SELA );
		ram0_B_x9_SEL			<= ( ~|ram0_WIDTH_SELB );
		ram0_AA_byte_SEL	<= ram0_AA[0] & ( ~|ram0_WIDTH_SELA );
		ram0_AB_byte_SEL	<= ram0_AB[0] & ( ~|ram0_WIDTH_SELB );
		if( ~Concat_En )
		begin
			ram_AA_ram_SEL	<= 1'b0;
			ram_AB_ram_SEL	<= 1'b0;
			ram1_B_x9_SEL		<= ( ~|ram1_WIDTH_SELB );
			
			ram0_PLRDA_SEL	<= ram0_PLRD;
			ram0_PLRDB_SEL	<= ram0_PLRD;
			ram1_PLRDA_SEL	<= ram1_PLRD;
			ram1_PLRDB_SEL	<= ram1_PLRD;
			ram0_WENBB_SEL	<= {`WEWID{1'b1}};
			ram1_WENBB_SEL	<= {`WEWID{1'b1}};
			
			ram0_AA_SEL				<= ram0_AA >> ( ~|ram0_WIDTH_SELA );
			ram0_WENBA_SEL[0]	<= ( ram0_AA[0] & ( ~|ram0_WIDTH_SELA ) ) | ram0_WENBA[0];
			ram0_WENBA_SEL[1]	<= ( ~ram0_AA[0] & ( ~|ram0_WIDTH_SELA ) ) | ram0_WENBA[( |ram0_WIDTH_SELA )];
			ram0_AB_SEL				<= ram0_AB >> ( ~|ram0_WIDTH_SELB );

			ram1_AA_SEL				<= ram1_AA >> ( ~|ram1_WIDTH_SELA );
			ram1_AA_byte_SEL	<= ram1_AA[0] & ( ~|ram1_WIDTH_SELA );
			ram1_WENBA_SEL[0]	<= ( ram1_AA[0] & ( ~|ram1_WIDTH_SELA ) ) | ram1_WENBA[0];
			ram1_WENBA_SEL[1]	<= ( ~ram1_AA[0] & ( ~|ram1_WIDTH_SELA ) ) | ram1_WENBA[( |ram1_WIDTH_SELA )];
			ram1_AB_SEL				<= ram1_AB >> ( ~|ram1_WIDTH_SELB );
			ram1_AB_byte_SEL	<= ram1_AB[0] & ( ~|ram1_WIDTH_SELB );
		end
		else
		begin
			ram_AA_ram_SEL	<= ~ram0_WIDTH_SELA[1] & ram0_AA[~ram0_WIDTH_SELA[0]];
			ram_AB_ram_SEL	<= ~ram0_WIDTH_SELB[1] & ram0_AB[~ram0_WIDTH_SELB[0]];
			ram1_B_x9_SEL	<= ( ~|ram0_WIDTH_SELB );

			ram0_PLRDA_SEL	<= ram1_PLRD;
			ram1_PLRDA_SEL	<= ram1_PLRD;
			ram0_PLRDB_SEL	<= ram0_PLRD;
			ram1_PLRDB_SEL	<= ram0_PLRD;
			
			ram0_AA_SEL				<= ram0_AA >> { ~ram0_WIDTH_SELA[1] & ~( ram0_WIDTH_SELA[1] ^ ram0_WIDTH_SELA[0] ), ~ram0_WIDTH_SELA[1] & ram0_WIDTH_SELA[0] };
			ram1_AA_SEL				<= ram0_AA >> { ~ram0_WIDTH_SELA[1] & ~( ram0_WIDTH_SELA[1] ^ ram0_WIDTH_SELA[0] ), ~ram0_WIDTH_SELA[1] & ram0_WIDTH_SELA[0] };
			ram1_AA_byte_SEL	<= ram0_AA[0] & ( ~|ram0_WIDTH_SELA );
			ram0_WENBA_SEL[0]	<= ram0_WENBA[0] | ( ~ram0_WIDTH_SELA[1] & ( ram0_AA[0] | ( ~ram0_WIDTH_SELA[0] & ram0_AA[1] ) ) );
			ram0_WENBA_SEL[1]	<= ( ( ~|ram0_WIDTH_SELA & ram0_WENBA[0] ) | ( |ram0_WIDTH_SELA & ram0_WENBA[1] ) ) | ( ~ram0_WIDTH_SELA[1] & ( ( ram0_WIDTH_SELA[0] & ram0_AA[0] ) | ( ~ram0_WIDTH_SELA[0] & ~ram0_AA[0] ) | ( ~ram0_WIDTH_SELA[0] & ram0_AA[1] ) ) );

			ram1_WENBA_SEL[0]	<= ( ( ~ram0_WIDTH_SELA[1] & ram0_WENBA[0] ) | ( ram0_WIDTH_SELA[1] & ram1_WENBA[0] ) ) | ( ~ram0_WIDTH_SELA[1] & ( ( ram0_WIDTH_SELA[0] & ~ram0_AA[0] ) | ( ~ram0_WIDTH_SELA[0] & ram0_AA[0] ) | ( ~ram0_WIDTH_SELA[0] & ~ram0_AA[1] ) ) );
			ram1_WENBA_SEL[1]	<= ( ( ( ram0_WIDTH_SELA == 2'b00 ) & ram0_WENBA[0] ) | ( ( ram0_WIDTH_SELA[1] == 1'b1 ) & ram1_WENBA[1] ) | ( ( ram0_WIDTH_SELA == 2'b01 ) & ram0_WENBA[1] ) ) | ( ~ram0_WIDTH_SELA[1] & ( ~ram0_AA[0] | ( ~ram0_WIDTH_SELA[0] & ~ram0_AA[1] ) ) );

			ram0_AB_SEL				<= ram0_AB >> { ~ram0_WIDTH_SELB[1] & ~( ram0_WIDTH_SELB[1] ^ ram0_WIDTH_SELB[0] ), ~ram0_WIDTH_SELB[1] & ram0_WIDTH_SELB[0] };
			ram1_AB_SEL				<= ram0_AB >> { ~ram0_WIDTH_SELB[1] & ~( ram0_WIDTH_SELB[1] ^ ram0_WIDTH_SELB[0] ), ~ram0_WIDTH_SELB[1] & ram0_WIDTH_SELB[0] };
			ram1_AB_byte_SEL	<= ram0_AB[0] & ( ~|ram0_WIDTH_SELB );
			ram0_WENBB_SEL[0]	<= ram0_WIDTH_SELB[1] | ( ram0_WIDTH_SELA[1] | ram1_WENBA[0] | ( ram0_AB[0] | ( ~ram0_WIDTH_SELB[0] & ram0_AB[1] ) ) );
			ram0_WENBB_SEL[1]	<= ram0_WIDTH_SELB[1] | ( ram0_WIDTH_SELA[1] | ( ( ~|ram0_WIDTH_SELB & ram1_WENBA[0] ) | ( |ram0_WIDTH_SELB & ram1_WENBA[1] ) ) | ( ( ram0_WIDTH_SELB[0] & ram0_AB[0] ) | ( ~ram0_WIDTH_SELB[0] & ~ram0_AB[0] ) | ( ~ram0_WIDTH_SELB[0] & ram0_AB[1] ) ) );
			ram1_WENBB_SEL[0]	<= ram0_WIDTH_SELB[1] | ( ram0_WIDTH_SELA[1] | ram1_WENBA[0] | ( ( ram0_WIDTH_SELB[0] & ~ram0_AB[0] ) | ( ~ram0_WIDTH_SELB[0] & ram0_AB[0] ) | ( ~ram0_WIDTH_SELB[0] & ~ram0_AB[1] ) ) );
			ram1_WENBB_SEL[1]	<= ram0_WIDTH_SELB[1] | ( ram0_WIDTH_SELA[1] | ( ( ~|ram0_WIDTH_SELB & ram1_WENBA[0] ) | ( |ram0_WIDTH_SELB & ram1_WENBA[1] ) ) | ( ~ram0_AB[0] | ( ~ram0_WIDTH_SELB[0] & ~ram0_AB[1] ) ) );
		end
	end
  
	ram	#(.ADDRWID(ADDRWID-2),
		  .init_1(INIT[ 0*9216 +: 9216])) 
                          ram0_inst(
									.AA( ram0_AA_SEL ),
									.AB( ram0_AB_SEL ),
									.CLKA( ram0_CEA ),
									.CLKB( ram0_CEB ),
									.WENA( ram0_WEBA_SEL ),
									.WENB( ram0_WEBB_SEL ),
									.CENA( ram0_CSBA_SEL ),
									.CENB( ram0_CSBB_SEL ),
									.WENBA( ram0_WENBA_SEL ),
									.WENBB( ram0_WENBB_SEL ),
									.DA( ram0_I_SEL1 ),
									.QA( QA_0 ),
									.DB( ram1_I_SEL1 ),
									.QB( QB_0 )
								);

	ram	#(.ADDRWID(ADDRWID-2),
		  .init_1(INIT[ 1*9216 +: 9216])) 
						   ram1_inst(
									.AA( ram1_AA_SEL ),
									.AB( ram1_AB_SEL ),
									.CLKA( ram1_CEA ),
									.CLKB( ram1_CEB ),
									.WENA( ram1_WEBA_SEL ),
									.WENB( ram1_WEBB_SEL ),
									.CENA( ram1_CSBA_SEL ),
									.CENB( ram1_CSBB_SEL ),
									.WENBA( ram1_WENBA_SEL ),
									.WENBB( ram1_WENBB_SEL ),
									.DA( ram1_I_SEL2 ),
									.QA( QA_1 ),
									.DB( ram1_I_SEL1 ),
									.QB( QB_1 )
								);


endmodule

`timescale 1 ns /10 ps
`define ADDRWID 11
`define DATAWID 18
`define WEWID 2

module ram_block_8K (  
                                CLK1_0,
                                CLK2_0,
                                WD_0,
                                RD_0,
                                A1_0,
                                A2_0,
                                CS1_0,
                                CS2_0,
                                WEN1_0,
                                POP_0,
                                Almost_Full_0,
                                Almost_Empty_0,
                                PUSH_FLAG_0,
                                POP_FLAG_0,
                                
                                FIFO_EN_0,
                                SYNC_FIFO_0,
                                PIPELINE_RD_0,
                                WIDTH_SELECT1_0,
                                WIDTH_SELECT2_0,
                                
                                CLK1_1,
                                CLK2_1,
                                WD_1,
                                RD_1,
                                A1_1,
                                A2_1,
                                CS1_1,
                                CS2_1,
                                WEN1_1,
                                POP_1,
                                Almost_Empty_1,
                                Almost_Full_1,
                                PUSH_FLAG_1,
                                POP_FLAG_1,
                                
                                FIFO_EN_1,
                                SYNC_FIFO_1,
                                PIPELINE_RD_1,
                                WIDTH_SELECT1_1,
                                WIDTH_SELECT2_1,
                                
                                CONCAT_EN_0,
                                CONCAT_EN_1,
				
								PUSH_0,
								PUSH_1,
								aFlushN_0,
								aFlushN_1
				
                              );
parameter [18431:0] INIT = 18432'bx;

  input                   CLK1_0;
  input                   CLK2_0;
  input   [`DATAWID-1:0]  WD_0;
  output  [`DATAWID-1:0]  RD_0;
  input   [`ADDRWID-1:0]    A1_0; 
  input   [`ADDRWID-1:0]    A2_0; 
  input                   CS1_0;
  input                   CS2_0;
  input   [`WEWID-1:0]    WEN1_0;
  input                   POP_0;
  output                  Almost_Full_0;
  output                  Almost_Empty_0;
  output  [3:0]           PUSH_FLAG_0;
  output  [3:0]           POP_FLAG_0;
  input                   FIFO_EN_0;
  input                   SYNC_FIFO_0;
  input                   PIPELINE_RD_0;
  input   [1:0]           WIDTH_SELECT1_0;
  input   [1:0]           WIDTH_SELECT2_0;
  
  input                   CLK1_1;
  input                   CLK2_1;
  input   [`DATAWID-1:0]  WD_1;
  output  [`DATAWID-1:0]  RD_1;
  input   [`ADDRWID-1:0]    A1_1; 
  input   [`ADDRWID-1:0]    A2_1; 
  input                   CS1_1;
  input                   CS2_1;
  input   [`WEWID-1:0]    WEN1_1;
  input                   POP_1;
  output                  Almost_Full_1;
  output                  Almost_Empty_1;
  output  [3:0]           PUSH_FLAG_1;
  output  [3:0]           POP_FLAG_1;
  input                   FIFO_EN_1;
  input                   SYNC_FIFO_1;
  input                   PIPELINE_RD_1;
  input   [1:0]           WIDTH_SELECT1_1;
  input   [1:0]           WIDTH_SELECT2_1;
  
  input                   CONCAT_EN_0;
  input                   CONCAT_EN_1;
 				
  input                   PUSH_0;
  input                   PUSH_1;
  input                   aFlushN_0;
  input                   aFlushN_1;
  
  reg                   rstn;
    
  wire  [`WEWID-1:0]    RAM0_WENb1_SEL;
  wire  [`WEWID-1:0]    RAM1_WENb1_SEL;
  
  wire                  RAM0_CS1_SEL;
  wire                  RAM0_CS2_SEL;
  wire                  RAM1_CS1_SEL;
  wire                  RAM1_CS2_SEL;

  wire  [`ADDRWID-1:0]  Fifo0_Write_Addr;
  wire  [`ADDRWID-1:0]  Fifo0_Read_Addr;
                        
  wire  [`ADDRWID-1:0]  Fifo1_Write_Addr;
  wire  [`ADDRWID-1:0]  Fifo1_Read_Addr;

  wire  [`ADDRWID-1:0]  RAM0_AA_SEL;
  wire  [`ADDRWID-1:0]  RAM0_AB_SEL;
  wire  [`ADDRWID-1:0]  RAM1_AA_SEL;
  wire  [`ADDRWID-1:0]  RAM1_AB_SEL;
  
  wire                  Concat_En_SEL;
  
  initial
  begin
    rstn  = 1'b0;
    #30  rstn  = 1'b1;
  end
  
  assign fifo0_rstn = rstn & aFlushN_0;
  assign fifo1_rstn = rstn & aFlushN_1;

  assign Concat_En_SEL  = ( CONCAT_EN_0 | WIDTH_SELECT1_0[1] | WIDTH_SELECT2_0[1] )? 1'b1 : 1'b0;
  
  assign RAM0_AA_SEL  = FIFO_EN_0 ? Fifo0_Write_Addr : A1_0[`ADDRWID-1:0];
  assign RAM0_AB_SEL  = FIFO_EN_0 ? Fifo0_Read_Addr  : A2_0[`ADDRWID-1:0];
  assign RAM1_AA_SEL  = FIFO_EN_1 ? Fifo1_Write_Addr : A1_1[`ADDRWID-1:0];
  assign RAM1_AB_SEL  = FIFO_EN_1 ? Fifo1_Read_Addr  : A2_1[`ADDRWID-1:0];
  
  assign RAM0_WENb1_SEL = FIFO_EN_0 ? { `WEWID{ ~PUSH_0 } } : ~WEN1_0;
  assign RAM1_WENb1_SEL = ( FIFO_EN_1 & ~Concat_En_SEL ) ? { `WEWID{ ~PUSH_1 } } :
                          ( ( FIFO_EN_0 &  Concat_En_SEL ) ? ( WIDTH_SELECT1_0[1] ? { `WEWID{ ~PUSH_0 } } : { `WEWID{ 1'b1 } } ) : ~WEN1_1 );

  assign RAM0_CS1_SEL = ( FIFO_EN_0 ? CS1_0 : ~CS1_0 );
  assign RAM0_CS2_SEL = ( FIFO_EN_0 ? CS2_0 : ~CS2_0 );
  assign RAM1_CS1_SEL = ( FIFO_EN_1 ? CS1_1 : ~CS1_1 );
  assign RAM1_CS2_SEL = ( FIFO_EN_1 ? CS2_1 : ~CS2_1 );

  x2_model #(.ADDRWID(`ADDRWID),
			 .INIT(INIT)) 
			x2_8K_model_inst(
                            .Concat_En( Concat_En_SEL ),
                            
                            .ram0_WIDTH_SELA( WIDTH_SELECT1_0 ),
                            .ram0_WIDTH_SELB( WIDTH_SELECT2_0 ),
                            .ram0_PLRD( PIPELINE_RD_0 ),
                            
                            .ram0_CEA( CLK1_0 ),
                            .ram0_CEB( CLK2_0 ),
                            .ram0_I( WD_0 ),
                            .ram0_O( RD_0 ),
                            .ram0_AA( RAM0_AA_SEL ),
                            .ram0_AB( RAM0_AB_SEL ),
                            .ram0_CSBA( RAM0_CS1_SEL ),
                            .ram0_CSBB( RAM0_CS2_SEL ),
                            .ram0_WENBA( RAM0_WENb1_SEL ),
                            
                            .ram1_WIDTH_SELA( WIDTH_SELECT1_1 ),
                            .ram1_WIDTH_SELB( WIDTH_SELECT2_1 ),
                            .ram1_PLRD( PIPELINE_RD_1 ),
                            
                            .ram1_CEA( CLK1_1 ),
                            .ram1_CEB( CLK2_1 ),
                            .ram1_I( WD_1 ),
                            .ram1_O( RD_1 ),
                            .ram1_AA( RAM1_AA_SEL ),
                            .ram1_AB( RAM1_AB_SEL ),
                            .ram1_CSBA( RAM1_CS1_SEL ),
                            .ram1_CSBB( RAM1_CS2_SEL ),
                            .ram1_WENBA( RAM1_WENb1_SEL )
                          );

  fifo_controller_model #(.MAX_PTR_WIDTH(`ADDRWID+1)) fifo_controller0_inst(
                                                .Push_Clk( CLK1_0 ),
                                                .Pop_Clk( CLK2_0 ),
                                                
                                                .Fifo_Push( PUSH_0 ),
                                                .Fifo_Push_Flush( CS1_0 ),
                                                .Fifo_Full( Almost_Full_0 ),
                                                .Fifo_Full_Usr( PUSH_FLAG_0 ),
                                                
                                                .Fifo_Pop( POP_0 ),
                                                .Fifo_Pop_Flush( CS2_0 ),
                                                .Fifo_Empty( Almost_Empty_0 ),
                                                .Fifo_Empty_Usr( POP_FLAG_0 ),
                                                
                                                .Write_Addr( Fifo0_Write_Addr ),
                                                
                                                .Read_Addr( Fifo0_Read_Addr ),
                                                                        
                                                .Fifo_Ram_Mode( Concat_En_SEL ),
                                                .Fifo_Sync_Mode( SYNC_FIFO_0 ),
                                                .Fifo_Push_Width( WIDTH_SELECT1_0 ),
                                                .Fifo_Pop_Width( WIDTH_SELECT2_0 ),
                                                .Rst_n( fifo0_rstn )
                                              );

  fifo_controller_model #(.MAX_PTR_WIDTH(`ADDRWID+1)) fifo_controller1_inst(
                                                .Push_Clk( CLK1_1 ),
                                                .Pop_Clk( CLK2_1 ),
                                                
                                                .Fifo_Push( PUSH_1 ),
                                                .Fifo_Push_Flush( CS1_1 ),
                                                .Fifo_Full( Almost_Full_1 ),
                                                .Fifo_Full_Usr( PUSH_FLAG_1 ),
                                                
                                                .Fifo_Pop( POP_1 ),
                                                .Fifo_Pop_Flush( CS2_1 ),
                                                .Fifo_Empty( Almost_Empty_1 ),
                                                .Fifo_Empty_Usr( POP_FLAG_1 ),
                                                
                                                .Write_Addr( Fifo1_Write_Addr ),
                                                
                                                .Read_Addr( Fifo1_Read_Addr ),
                                                                        
                                                .Fifo_Ram_Mode( 1'b0 ),
                                                .Fifo_Sync_Mode( SYNC_FIFO_1 ),
                                                .Fifo_Push_Width( { 1'b0, WIDTH_SELECT1_1[0] } ),
                                                .Fifo_Pop_Width( { 1'b0, WIDTH_SELECT2_1[0] } ),
                                                .Rst_n( fifo1_rstn )
                                              );

endmodule

module sw_mux (
	port_out,
	default_port,
	alt_port,
	switch
	);
	
	output port_out;
	input default_port;
	input alt_port;
	input switch;
	
	assign port_out = switch ? alt_port : default_port;
	
endmodule


`define ADDRWID_8k2 11
`define DATAWID 18
`define WEWID 2

module ram8k_2x1_cell_macro (  
        CLK1_0,
        CLK2_0,
		CLK1S_0,
        CLK2S_0,
        WD_0,
        RD_0,
        A1_0,
        A2_0,
        CS1_0,
        CS2_0,
        WEN1_0,
        CLK1EN_0,
        CLK2EN_0,
        P1_0,
        P2_0,
        Almost_Full_0,
        Almost_Empty_0,
        PUSH_FLAG_0,
        POP_FLAG_0,

        FIFO_EN_0,
        SYNC_FIFO_0,
        PIPELINE_RD_0,
        WIDTH_SELECT1_0,
        WIDTH_SELECT2_0,
        DIR_0,
        ASYNC_FLUSH_0,
		ASYNC_FLUSH_S0,

        CLK1_1,
        CLK2_1,
		CLK1S_1,
        CLK2S_1,
        WD_1,
        RD_1,
        A1_1,
        A2_1,
        CS1_1,
        CS2_1,
        WEN1_1,
        CLK1EN_1,
        CLK2EN_1,
        P1_1,
        P2_1,
        Almost_Empty_1,
        Almost_Full_1,
        PUSH_FLAG_1,
        POP_FLAG_1,

        FIFO_EN_1,
        SYNC_FIFO_1,
        PIPELINE_RD_1,
        WIDTH_SELECT1_1,
        WIDTH_SELECT2_1,
        DIR_1,
        ASYNC_FLUSH_1,
		ASYNC_FLUSH_S1,

        CONCAT_EN_0,
        CONCAT_EN_1

);

parameter [18431:0] INIT = 18432'bx;

  input                   CLK1_0;
  input                   CLK2_0;
  input                   CLK1S_0;
  input                   CLK2S_0;
  input   [`DATAWID-1:0]  WD_0;
  output  [`DATAWID-1:0]  RD_0;
  input   [`ADDRWID_8k2-1:0]  A1_0;
  input   [`ADDRWID_8k2-1:0]  A2_0;
  input                   CS1_0;
  input                   CS2_0;
  input   [`WEWID-1:0]    WEN1_0;
  input  		  CLK1EN_0;
  input                   CLK2EN_0;
  input                   P1_0;
  input                   P2_0;
  output                  Almost_Full_0;
  output                  Almost_Empty_0;
  output  [3:0]           PUSH_FLAG_0;
  output  [3:0]           POP_FLAG_0;
  input                   FIFO_EN_0;
  input                   SYNC_FIFO_0;
  input                   DIR_0;
  input                   ASYNC_FLUSH_0;
  input                   ASYNC_FLUSH_S0;
  input                   PIPELINE_RD_0;
  input   [1:0]           WIDTH_SELECT1_0;
  input   [1:0]           WIDTH_SELECT2_0;
  
  input                   CLK1_1;
  input                   CLK2_1;
  input                   CLK1S_1;
  input                   CLK2S_1;
  input   [`DATAWID-1:0]  WD_1;
  output  [`DATAWID-1:0]  RD_1;
  input   [`ADDRWID_8k2-1:0]  A1_1;
  input   [`ADDRWID_8k2-1:0]  A2_1;
  input                   CS1_1;
  input                   CS2_1;
  input   [`WEWID-1:0]    WEN1_1;
  input  		  CLK1EN_1;
  input  		  CLK2EN_1;
  input  		  P1_1;
  input  		  P2_1;
  output                  Almost_Full_1;
  output                  Almost_Empty_1;
  output  [3:0]           PUSH_FLAG_1;
  output  [3:0]           POP_FLAG_1;
  input                   FIFO_EN_1;
  input                   SYNC_FIFO_1;
  input  		  DIR_1;
  input  		  ASYNC_FLUSH_1;
  input  		  ASYNC_FLUSH_S1;
  input                   PIPELINE_RD_1;
  input   [1:0]           WIDTH_SELECT1_1;
  input   [1:0]           WIDTH_SELECT2_1;
  
  input                   CONCAT_EN_0;
  input                   CONCAT_EN_1;

reg	RAM0_domain_sw;
reg	RAM1_domain_sw;

wire CLK1P_0, CLK1P_1, CLK2P_0, CLK2P_1, ASYNC_FLUSHP_1, ASYNC_FLUSHP_0;

assign WidSel1_1 = WIDTH_SELECT1_0[1];
assign WidSel2_1 = WIDTH_SELECT2_0[1];

assign CLK1P_0 = CLK1S_0 ? ~CLK1_0 : CLK1_0;
assign CLK1P_1 = CLK1S_1 ? ~CLK1_1 : CLK1_1;
assign CLK2P_0 = CLK2S_0 ? ~CLK2_0 : CLK2_0;
assign CLK2P_1 = CLK2S_1 ? ~CLK2_1 : CLK2_1;
assign ASYNC_FLUSHP_0 = ASYNC_FLUSH_S0? ~ASYNC_FLUSH_0 : ASYNC_FLUSH_0;
assign ASYNC_FLUSHP_1 = ASYNC_FLUSH_S1? ~ASYNC_FLUSH_1 : ASYNC_FLUSH_1;


always @( CONCAT_EN_0 or FIFO_EN_0 or FIFO_EN_1 or WidSel1_1 or WidSel2_1 or DIR_0 or DIR_1)

begin
	if (CONCAT_EN_0)                                               
		begin
		if (~FIFO_EN_0)                                            
			begin
			RAM0_domain_sw = 1'b0;                                 
			RAM1_domain_sw = 1'b0;
			end
		else                                                       
			begin
			RAM0_domain_sw = DIR_0;                                
			RAM1_domain_sw = DIR_0;
			end
		end
	else                                                           
		begin
			if (WidSel1_1 || WidSel2_1)        
				begin
				if (~FIFO_EN_0)                
					begin
					RAM0_domain_sw = 1'b0;     
					RAM1_domain_sw = 1'b0;
					end
				else                           
					begin
   		 		RAM0_domain_sw = DIR_0;        
			  	RAM1_domain_sw = DIR_0;
					end
				end
			else                               
				begin
				if (~FIFO_EN_0)                
					RAM0_domain_sw = 1'b0;
				else                           
					RAM0_domain_sw = DIR_0;
				if (~FIFO_EN_1)                
					RAM1_domain_sw = 1'b0;
				else                           
			  	RAM1_domain_sw = DIR_1;
				end
		end
end

assign RAM0_Clk1_gated = CLK1EN_0 & CLK1P_0;
assign RAM0_Clk2_gated = CLK2EN_0 & CLK2P_0;
assign RAM1_Clk1_gated = CLK1EN_1 & CLK1P_1;
assign RAM1_Clk2_gated = CLK2EN_1 & CLK2P_1;

sw_mux RAM0_clk_sw_port1 (.port_out(RAM0_clk_port1), .default_port(RAM0_Clk1_gated), .alt_port(RAM0_Clk2_gated), .switch(RAM0_domain_sw));
sw_mux RAM0_P_sw_port1 (.port_out(RAM0_push_port1), .default_port(P1_0), .alt_port(P2_0), .switch(RAM0_domain_sw));
sw_mux RAM0_Flush_sw_port1 (.port_out(RAM0CS_Sync_Flush_port1), .default_port(CS1_0), .alt_port(CS2_0), .switch(RAM0_domain_sw));
sw_mux RAM0_WidSel0_port1 (.port_out(RAM0_Wid_Sel0_port1), .default_port(WIDTH_SELECT1_0[0]), .alt_port(WIDTH_SELECT2_0[0]), .switch(RAM0_domain_sw));
sw_mux RAM0_WidSel1_port1 (.port_out(RAM0_Wid_Sel1_port1), .default_port(WIDTH_SELECT1_0[1]), .alt_port(WIDTH_SELECT2_0[1]), .switch(RAM0_domain_sw));

sw_mux RAM0_clk_sw_port2 (.port_out(RAM0_clk_port2), .default_port(RAM0_Clk2_gated), .alt_port(RAM0_Clk1_gated), .switch(RAM0_domain_sw));
sw_mux RAM0_P_sw_port2 (.port_out(RAM0_pop_port2), .default_port(P2_0), .alt_port(P1_0), .switch(RAM0_domain_sw));
sw_mux RAM0_Flush_sw_port2 (.port_out(RAM0CS_Sync_Flush_port2), .default_port(CS2_0), .alt_port(CS1_0), .switch(RAM0_domain_sw));
sw_mux RAM0_WidSel0_port2 (.port_out(RAM0_Wid_Sel0_port2), .default_port(WIDTH_SELECT2_0[0]), .alt_port(WIDTH_SELECT1_0[0]), .switch(RAM0_domain_sw));
sw_mux RAM0_WidSel1_port2 (.port_out(RAM0_Wid_Sel1_port2), .default_port(WIDTH_SELECT2_0[1]), .alt_port(WIDTH_SELECT1_0[1]), .switch(RAM0_domain_sw));

sw_mux RAM1_clk_sw_port1 (.port_out(RAM1_clk_port1), .default_port(RAM1_Clk1_gated), .alt_port(RAM1_Clk2_gated), .switch(RAM1_domain_sw));
sw_mux RAM1_P_sw_port1 (.port_out(RAM1_push_port1), .default_port(P1_1), .alt_port(P2_1), .switch(RAM1_domain_sw));
sw_mux RAM1_Flush_sw_port1 (.port_out(RAM1CS_Sync_Flush_port1), .default_port(CS1_1), .alt_port(CS2_1), .switch(RAM1_domain_sw));
sw_mux RAM1_WidSel0_port1 (.port_out(RAM1_Wid_Sel0_port1), .default_port(WIDTH_SELECT1_1[0]), .alt_port(WIDTH_SELECT2_1[0]), .switch(RAM1_domain_sw));
sw_mux RAM1_WidSel1_port1 (.port_out(RAM1_Wid_Sel1_port1), .default_port(WIDTH_SELECT1_1[1]), .alt_port(WIDTH_SELECT2_1[1]), .switch(RAM1_domain_sw));

sw_mux RAM1_clk_sw_port2 (.port_out(RAM1_clk_port2), .default_port(RAM1_Clk2_gated), .alt_port(RAM1_Clk1_gated), .switch(RAM1_domain_sw));
sw_mux RAM1_P_sw_port2 (.port_out(RAM1_pop_port2), .default_port(P2_1), .alt_port(P1_1), .switch(RAM1_domain_sw));
sw_mux RAM1_Flush_sw_port2 (.port_out(RAM1CS_Sync_Flush_port2), .default_port(CS2_1), .alt_port(CS1_1), .switch(RAM1_domain_sw));
sw_mux RAM1_WidSel0_port2 (.port_out(RAM1_Wid_Sel0_port2), .default_port(WIDTH_SELECT2_1[0]), .alt_port(WIDTH_SELECT1_1[0]), .switch(RAM1_domain_sw));
sw_mux RAM1_WidSel1_port2 (.port_out(RAM1_Wid_Sel1_port2), .default_port(WIDTH_SELECT2_1[1]), .alt_port(WIDTH_SELECT1_1[1]), .switch(RAM1_domain_sw));

ram_block_8K  # (.INIT(INIT))
			  ram_block_8K_inst (  
                                .CLK1_0(RAM0_clk_port1),
                                .CLK2_0(RAM0_clk_port2),
                                .WD_0(WD_0),
                                .RD_0(RD_0),
                                .A1_0(A1_0),
                                .A2_0(A2_0),
                                .CS1_0(RAM0CS_Sync_Flush_port1),
                                .CS2_0(RAM0CS_Sync_Flush_port2),
                                .WEN1_0(WEN1_0),
                                .POP_0(RAM0_pop_port2),
                                .Almost_Full_0(Almost_Full_0),
                                .Almost_Empty_0(Almost_Empty_0),
                                .PUSH_FLAG_0(PUSH_FLAG_0),
                                .POP_FLAG_0(POP_FLAG_0),
                                
                                .FIFO_EN_0(FIFO_EN_0),
                                .SYNC_FIFO_0(SYNC_FIFO_0),
                                .PIPELINE_RD_0(PIPELINE_RD_0),
                                .WIDTH_SELECT1_0({RAM0_Wid_Sel1_port1,RAM0_Wid_Sel0_port1}),
                                .WIDTH_SELECT2_0({RAM0_Wid_Sel1_port2,RAM0_Wid_Sel0_port2}),
                                
                                .CLK1_1(RAM1_clk_port1),
                                .CLK2_1(RAM1_clk_port2),
                                .WD_1(WD_1),
                                .RD_1(RD_1),
                                .A1_1(A1_1),
                                .A2_1(A2_1),
                                .CS1_1(RAM1CS_Sync_Flush_port1),
                                .CS2_1(RAM1CS_Sync_Flush_port2),
                                .WEN1_1(WEN1_1),
                                .POP_1(RAM1_pop_port2),
                                .Almost_Empty_1(Almost_Empty_1),
                                .Almost_Full_1(Almost_Full_1),
                                .PUSH_FLAG_1(PUSH_FLAG_1),
                                .POP_FLAG_1(POP_FLAG_1),
                                
                                .FIFO_EN_1(FIFO_EN_1),
                                .SYNC_FIFO_1(SYNC_FIFO_1),
                                .PIPELINE_RD_1(PIPELINE_RD_1),
                                .WIDTH_SELECT1_1({RAM1_Wid_Sel1_port1,RAM1_Wid_Sel0_port1}),
                                .WIDTH_SELECT2_1({RAM1_Wid_Sel1_port2,RAM1_Wid_Sel0_port2}),
                                
                                .CONCAT_EN_0(CONCAT_EN_0),
                                .CONCAT_EN_1(CONCAT_EN_1),
				
								.PUSH_0(RAM0_push_port1),
								.PUSH_1(RAM1_push_port1),
								.aFlushN_0(~ASYNC_FLUSHP_0),
								.aFlushN_1(~ASYNC_FLUSHP_1)
				
                              );

endmodule

module ram8k_2x1_cell  (
    input A1_0_b0,
	input A1_0_b1,
	input A1_0_b2,
	input A1_0_b3,
	input A1_0_b4,
	input A1_0_b5,
	input A1_0_b6,
	input A1_0_b7,
	input A1_0_b8,
	input A1_0_b9,
	input A1_0_b10,
    input A2_0_b0,
	input A2_0_b1,
	input A2_0_b2,
	input A2_0_b3,
	input A2_0_b4,
	input A2_0_b5,
	input A2_0_b6,
	input A2_0_b7,
	input A2_0_b8,
	input A2_0_b9,
	input A2_0_b10,
    input A1_1_b0,
	input A1_1_b1,
	input A1_1_b2,
	input A1_1_b3,
	input A1_1_b4,
	input A1_1_b5,
	input A1_1_b6,
	input A1_1_b7,
	input A1_1_b8,
	input A1_1_b9,
	input A1_1_b10,
    input A2_1_b0,
	input A2_1_b1,
	input A2_1_b2,
	input A2_1_b3,
	input A2_1_b4,
	input A2_1_b5,
	input A2_1_b6,
	input A2_1_b7,
	input A2_1_b8,
	input A2_1_b9,
	input A2_1_b10, 
	input WD_0_b0, 
	input WD_0_b1, 
	input WD_0_b2, 
	input WD_0_b3, 
	input WD_0_b4, 
	input WD_0_b5, 
	input WD_0_b6, 
	input WD_0_b7, 
	input WD_0_b8, 
	input WD_0_b9,
	input WD_0_b10, 
	input WD_0_b11,
	input WD_0_b12,
	input WD_0_b13,
	input WD_0_b14,
	input WD_0_b15,
	input WD_0_b16,
	input WD_0_b17,
	input WD_1_b0, 
	input WD_1_b1, 
	input WD_1_b2, 
	input WD_1_b3, 
	input WD_1_b4, 
	input WD_1_b5, 
	input WD_1_b6, 
	input WD_1_b7, 
	input WD_1_b8, 
	input WD_1_b9,
	input WD_1_b10, 
	input WD_1_b11,
	input WD_1_b12,
	input WD_1_b13,
	input WD_1_b14,
	input WD_1_b15,
	input WD_1_b16,
	input WD_1_b17,
    input CLK1_0,
    input CLK1_1,
    input CLK2_0,
    input CLK2_1,
    output Almost_Empty_0, Almost_Empty_1, Almost_Full_0, Almost_Full_1,
    input ASYNC_FLUSH_0, ASYNC_FLUSH_1, CLK1EN_0, CLK1EN_1, CLK2EN_0, CLK2EN_1, CONCAT_EN_0, CONCAT_EN_1, CS1_0, CS1_1,CS2_0, CS2_1, DIR_0, DIR_1, FIFO_EN_0, FIFO_EN_1, P1_0, P1_1, P2_0,P2_1, PIPELINE_RD_0, PIPELINE_RD_1,
    output POP_FLAG_0_b0,
	output POP_FLAG_0_b1,
	output POP_FLAG_0_b2,
	output POP_FLAG_0_b3,
    output POP_FLAG_1_b0,
	output POP_FLAG_1_b1,
	output POP_FLAG_1_b2,
	output POP_FLAG_1_b3,
    output PUSH_FLAG_0_b0,
	output PUSH_FLAG_0_b1,
	output PUSH_FLAG_0_b2,
	output PUSH_FLAG_0_b3,
    output PUSH_FLAG_1_b0,
	output PUSH_FLAG_1_b1,
	output PUSH_FLAG_1_b2,
	output PUSH_FLAG_1_b3,
    output RD_0_b0,
	output RD_0_b1,
	output RD_0_b2,
	output RD_0_b3,
	output RD_0_b4,
	output RD_0_b5,
	output RD_0_b6,
	output RD_0_b7,
	output RD_0_b8,
	output RD_0_b9,
	output RD_0_b10,
	output RD_0_b11,
	output RD_0_b12,
	output RD_0_b13,
	output RD_0_b14,
	output RD_0_b15,
	output RD_0_b16,
	output RD_0_b17,
    output RD_1_b0,
	output RD_1_b1,
	output RD_1_b2,
	output RD_1_b3,
	output RD_1_b4,
	output RD_1_b5,
	output RD_1_b6,
	output RD_1_b7,
	output RD_1_b8,
	output RD_1_b9,
	output RD_1_b10,
	output RD_1_b11,
	output RD_1_b12,
	output RD_1_b13,
	output RD_1_b14,
	output RD_1_b15,
	output RD_1_b16,
	output RD_1_b17,
    input  SYNC_FIFO_0, SYNC_FIFO_1,
    input  WEN1_0_b0,   
	input  WEN1_0_b1,
	input  WEN1_1_b0,
	input  WEN1_1_b1,
    input [1:0] WIDTH_SELECT1_0,
    input [1:0] WIDTH_SELECT1_1,
    input [1:0] WIDTH_SELECT2_0,
    input [1:0] WIDTH_SELECT2_1,
    input RMA_b0,
	input RMA_b1,
	input RMA_b2,
	input RMA_b3,
	input RMB_b0,
	input RMB_b1,
	input RMB_b2,
    input RMB_b3
	);

	parameter [18431:0] INIT = 18432'bx;
	
	ram8k_2x1_cell_macro # (.INIT(INIT))
						I1 ( 	
							.A1_0({A1_0_b10,A1_0_b9,A1_0_b8,A1_0_b7,A1_0_b6,A1_0_b5,A1_0_b4,A1_0_b3,A1_0_b2,A1_0_b1,A1_0_b0}), 
							.A1_1({A1_1_b10,A1_1_b9,A1_1_b8,A1_1_b7,A1_1_b6,A1_1_b5,A1_1_b4,A1_1_b3,A1_1_b2,A1_1_b1,A1_1_b0}),
							.A2_0({A2_0_b10,A2_0_b9,A2_0_b8,A2_0_b7,A2_0_b6,A2_0_b5,A2_0_b4,A2_0_b3,A2_0_b2,A2_0_b1,A2_0_b0}), 
							.A2_1({A2_1_b10,A2_1_b9,A2_1_b8,A2_1_b7,A2_1_b6,A2_1_b5,A2_1_b4,A2_1_b3,A2_1_b2,A2_1_b1,A2_1_b0}),
							.Almost_Empty_0(Almost_Empty_0),
							.Almost_Empty_1(Almost_Empty_1),
							.Almost_Full_0(Almost_Full_0),
							.Almost_Full_1(Almost_Full_1),
							.ASYNC_FLUSH_0(ASYNC_FLUSH_0),
							.ASYNC_FLUSH_1(ASYNC_FLUSH_1),
							.ASYNC_FLUSH_S0(1'b0),
							.ASYNC_FLUSH_S1(1'b0), 
							.CLK1_0(CLK1_0),
							.CLK1_1(CLK1_1) , 
							.CLK1EN_0(CLK1EN_0) , 
							.CLK1EN_1(CLK1EN_1),
							.CLK1S_0(1'b0) , 
							.CLK1S_1(1'b0) , 
							.CLK2_0(CLK2_0),
							.CLK2_1(CLK2_1) , 
							.CLK2EN_0(CLK2EN_0) , 
							.CLK2EN_1(CLK2EN_1),
							.CLK2S_0(1'b0) , 
							.CLK2S_1(1'b0),
							.CONCAT_EN_0(CONCAT_EN_0) , 
							.CONCAT_EN_1(CONCAT_EN_1),
							.CS1_0(CS1_0) , 
							.CS1_1(CS1_1) , 
							.CS2_0(CS2_0) , 
							.CS2_1(CS2_1),
							.DIR_0(DIR_0) , 
							.DIR_1(DIR_1) , 
							.FIFO_EN_0(FIFO_EN_0),
							.FIFO_EN_1(FIFO_EN_1) , 
							.P1_0(P1_0) , 
							.P1_1(P1_1) , 
							.P2_0(P2_0),
							.P2_1(P2_1) , 
							.PIPELINE_RD_0(PIPELINE_RD_0),
							.PIPELINE_RD_1(PIPELINE_RD_1),
							.POP_FLAG_0({POP_FLAG_0_b3,POP_FLAG_0_b2,POP_FLAG_0_b1,POP_FLAG_0_b0}),
							.POP_FLAG_1({POP_FLAG_1_b3,POP_FLAG_1_b2,POP_FLAG_1_b1,POP_FLAG_1_b0}),
							.PUSH_FLAG_0({PUSH_FLAG_0_b3,PUSH_FLAG_0_b2,PUSH_FLAG_0_b1,PUSH_FLAG_0_b0}),
							.PUSH_FLAG_1({PUSH_FLAG_1_b3,PUSH_FLAG_1_b2,PUSH_FLAG_1_b1,PUSH_FLAG_1_b0}), 
							.RD_0({RD_0_b17,RD_0_b16,RD_0_b15,RD_0_b14,RD_0_b13,RD_0_b12,RD_0_b11,RD_0_b10,RD_0_b9,RD_0_b8,RD_0_b7,RD_0_b6,RD_0_b5,RD_0_b4,RD_0_b3,RD_0_b2,RD_0_b1,RD_0_b0}),
							.RD_1({RD_1_b17,RD_1_b16,RD_1_b15,RD_1_b14,RD_1_b13,RD_1_b12,RD_1_b11,RD_1_b10,RD_1_b9,RD_1_b8,RD_1_b7,RD_1_b6,RD_1_b5,RD_1_b4,RD_1_b3,RD_1_b2,RD_1_b1,RD_1_b0}) , 
							.SYNC_FIFO_0(SYNC_FIFO_0),
							.SYNC_FIFO_1(SYNC_FIFO_1) , 
							.WD_0({WD_0_b17,WD_0_b16,WD_0_b15,WD_0_b14,WD_0_b13,WD_0_b12,WD_0_b11,WD_0_b10,WD_0_b9,WD_0_b8,WD_0_b7,WD_0_b6,WD_0_b5,WD_0_b4,WD_0_b3,WD_0_b2,WD_0_b1,WD_0_b0}),
							.WD_1({WD_1_b17,WD_1_b16,WD_1_b15,WD_1_b14,WD_1_b13,WD_1_b12,WD_1_b11,WD_1_b10,WD_1_b9,WD_1_b8,WD_1_b7,WD_1_b6,WD_1_b5,WD_1_b4,WD_1_b3,WD_1_b2,WD_1_b1,WD_1_b0}), 
							.WEN1_0({WEN1_0_b1,WEN1_0_b0}),
							.WEN1_1({WEN1_1_b1,WEN1_1_b0}),
							.WIDTH_SELECT1_0({ WIDTH_SELECT1_0[1:0] }),
							.WIDTH_SELECT1_1({ WIDTH_SELECT1_1[1:0] }),
							.WIDTH_SELECT2_0({ WIDTH_SELECT2_0[1:0] }),
							.WIDTH_SELECT2_1({ WIDTH_SELECT2_1[1:0] }) 
							);
					 
endmodule