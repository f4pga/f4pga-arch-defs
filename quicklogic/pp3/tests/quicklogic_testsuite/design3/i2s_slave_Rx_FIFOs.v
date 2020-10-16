// -----------------------------------------------------------------------------
// title          : I2C Slave Rx FIFOs (Left & Right) Module
// project        : Tamar2 Device
// -----------------------------------------------------------------------------
// file           : i2s_slave_Rx_FIFOs.v
// author         : SSG
// company        : QuickLogic Corp
// created        : 2017/03/23	
// last update    : 2017/03/23
// platform       : ArcticLink 4 S3B
// standard       : Verilog 2001
// -----------------------------------------------------------------------------
// description: Right Rx FIFO and Left Rx FiFO for receiving the right & Left
//              channel I2S data
// -----------------------------------------------------------------------------
// copyright (c) 2016
// -----------------------------------------------------------------------------
// revisions  :
// date            version      author                description
// 2017/03/23      1.0        Rakesh Moolacheri     Initial Release
// 2018/01/29      1.1        Anand Wadke           Modified for FIR decimator
//
// -----------------------------------------------------------------------------
// Comments: This solution is specifically for use with the QuickLogic
//           AL4S3B device. 
// -----------------------------------------------------------------------------
//

`timescale 1ns / 10ps


module i2s_slave_Rx_FIFOs( 

						 i2s_clk_i,
						 
                         WBs_CLK_i,
                         WBs_RST_i,

                         Deci_Rx_FIFO_Flush_i,//Rx_FIFO_Flush_i_
						 
						 L_PreDeci_RXRAM_DAT_i,//L_RXFIFO_DAT_i_written to RAM
						 L_PreDeci_RXRAM_WR_i, //L_RXFIFO_PUSH_i_
						 
						 FIR_L_PreDeci_DATA_RaDDR_i,
						 FIR_L_PreDeci_RD_DATA_o,
						 
						 FIR_Deci_DATA_i,
						 FIR_Deci_DATA_PUSH_i,	

                         L_PreDeci_RXRAM_w_Addr_o,
						 L_PreDeci_I2S_RXRAM_w_ena_o,						
                         i2s_Clock_Stopped_i,						
						 
						//From Wishbone
						 wb_FIR_L_PreDeci_RAM_aDDR_i,
						 wb_FIR_L_PreDeci_RAM_Wen_i,	
						 wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i	,						 
						 
						 
						 //R_RXFIFO_DAT_i,
						 //R_RXFIFO_PUSH_i, 

						 //L_RXFIFO_DAT_o,
                         //L_RXFIFO_Pop_i,
                         
						 //R_RXFIFO_DAT_o,
                         //R_RXFIFO_Pop_i,
						 
						 //STEREO_EN_i,
						 //LR_CHNL_SEL_i,
						 //LR_RXFIFO_DAT_o,
						 //LR_Rx_FIFO_Full_o,
						 //LR_Rx_FIFO_Empty_o,
						 //LR_Rx_FIFO_Level_o,
						 
						 DeciData_RXFIFO_Pop_i,//LR_RXFIFO_Pop_i
						 DeciData_RXFIFO_DAT_o,
						 //DMA_Busy_i

                         DeciData_Rx_FIFO_Empty_o,//L_Rx_FIFO_Empty_o_,
                         DeciData_Rx_FIFO_Full_o,//L_Rx_FIFO_Full_o_,
                         DeciData_Rx_FIFO_Level_o, //L_Rx_FIFO_Level_o_,
						 DeciData_Rx_FIFO_Empty_flag_o
						 
						 //R_Rx_FIFO_Empty_o,
                         //R_Rx_FIFO_Full_o,
                         //R_Rx_FIFO_Level_o
                         );


//------Port Parameters----------------
//

//
// None at this time
//

//------Port Signals-------------------
//

// Fabric Global Signals
//
input                    i2s_clk_i;

input                    WBs_CLK_i;         // Wishbone Fabric Clock
input                    WBs_RST_i;         // Wishbone Fabric Reset


// Rx FIFO Signals
//
input                    Deci_Rx_FIFO_Flush_i;

input            [15:0]  L_PreDeci_RXRAM_DAT_i;
input                    L_PreDeci_RXRAM_WR_i;

//input 	[9:0]  			FIR_L_PreDeci_DATA_RaDDR_i;
input 	[8:0]  			FIR_L_PreDeci_DATA_RaDDR_i;
output 	[15:0]  		FIR_L_PreDeci_RD_DATA_o;
//output 					START_FIR_DECI_o;

input 	[15:0]			FIR_Deci_DATA_i;
input 					FIR_Deci_DATA_PUSH_i;

output 	[8:0]			L_PreDeci_RXRAM_w_Addr_o;
output 					L_PreDeci_I2S_RXRAM_w_ena_o;
input 					i2s_Clock_Stopped_i;

//From Wishbone --> I2s register interface
input [8:0]				wb_FIR_L_PreDeci_RAM_aDDR_i;
input 					wb_FIR_L_PreDeci_RAM_Wen_i;
input 					wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i;

output [15:0]           DeciData_RXFIFO_DAT_o;
input                   DeciData_RXFIFO_Pop_i;
output                  DeciData_Rx_FIFO_Empty_o;
output                  DeciData_Rx_FIFO_Full_o;
output [8:0]            DeciData_Rx_FIFO_Level_o;
output [3:0]            DeciData_Rx_FIFO_Empty_flag_o;

wire                     WBs_CLK_i;         // Wishbone Fabric Clock
wire                     WBs_RST_i;         // Wishbone Fabric Reset
   

// Tx FIFO Signals
//
wire                    Deci_Rx_FIFO_Flush_i;

wire [15:0]  			L_PreDeci_RXRAM_DAT_i;
wire                    L_PreDeci_RXRAM_WR_i;

wire   					L_RXFIFO_Pop;

reg  [8:0]  			I2S_FIR_DATA_WaDDR_sig;
reg 					I2S_wMEM_WE_sig;

wire [8:0]  		    I2SData_ADDR_mux_sig;
wire [15:0] 		    I2SData_DATA_mux_sig;
wire   		            I2SData_wMEM_WE_mux_sig;
wire   		            I2SData_wclk;
wire   		            I2SData_gclk_wclk;

wire [15:0]             L_DeciData_RXFIFO_DAT;

reg               [8:0]  DeciData_Rx_FIFO_Level_o;
reg               [8:0]  DeciData_Rx_FIFO_Level_nxt;

wire               [3:0]  DeciData_Rx_FIFO_Empty_flag_sig;

//------Define Parameters--------------
//

//
// None at this time
//

//------Internal Signals---------------
//


//------Logic Operations---------------
//
// Determine when to Flush the FIFOs
//
assign Rx_FIFO_Flush      			= WBs_RST_i | Deci_Rx_FIFO_Flush_i;
assign L_PreDeci_I2S_RXRAM_w_ena_o  = I2SData_wMEM_WE_mux_sig;
assign DeciData_RXFIFO_DAT_o 		= L_DeciData_RXFIFO_DAT;
assign DeciData_RXFIFO_Pop 			= DeciData_RXFIFO_Pop_i; 

assign DeciData_Rx_FIFO_Empty_flag_o = DeciData_Rx_FIFO_Empty_flag_sig;

assign DeciData_Rx_FIFO_Empty_o = (DeciData_Rx_FIFO_Empty_flag_sig == 4'h0)? 1'b1 : 1'b0;
assign DeciData_Rx_FIFO_Full_o = (DeciData_Rx_FIFO_Empty_flag_sig == 4'hF)? 1'b1 : 1'b0;



always @( DeciData_RXFIFO_Pop           or
          FIR_Deci_DATA_PUSH_i     		or
          Deci_Rx_FIFO_Flush_i          or
          DeciData_Rx_FIFO_Level_o
         )
begin

    case(Deci_Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({DeciData_RXFIFO_Pop, FIR_Deci_DATA_PUSH_i})
        2'b00: DeciData_Rx_FIFO_Level_nxt <= DeciData_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: DeciData_Rx_FIFO_Level_nxt <= DeciData_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: DeciData_Rx_FIFO_Level_nxt <= DeciData_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: DeciData_Rx_FIFO_Level_nxt <= DeciData_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      DeciData_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end 

always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        DeciData_Rx_FIFO_Level_o  <= 9'h0;
    end  
    else
    begin
	    DeciData_Rx_FIFO_Level_o  <= DeciData_Rx_FIFO_Level_nxt;
    end  
end



assign L_PreDeci_RXRAM_w_Addr_o = I2S_FIR_DATA_WaDDR_sig;
//New Addition based on the decimator--Anand
always @( posedge i2s_clk_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
         I2S_FIR_DATA_WaDDR_sig  <= 9'h1FF;
         I2S_wMEM_WE_sig  <= 1'b0;
    end  
    else
    begin
	  if (L_PreDeci_RXRAM_WR_i)
	  begin
		 I2S_FIR_DATA_WaDDR_sig  <= I2S_FIR_DATA_WaDDR_sig + 1;
		 I2S_wMEM_WE_sig         <= 1'b1; 
	  end	 
	  else
	  begin
	     I2S_FIR_DATA_WaDDR_sig  <= I2S_FIR_DATA_WaDDR_sig;
		 I2S_wMEM_WE_sig         <= 1'b0; 
	  end	 
    end  
end 



assign I2SData_ADDR_mux_sig 	= (wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i) ? wb_FIR_L_PreDeci_RAM_aDDR_i : I2S_FIR_DATA_WaDDR_sig ;
assign I2SData_DATA_mux_sig 	= (wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i) ? 15'h00 : L_PreDeci_RXRAM_DAT_i;//L_RXFIFO_DAT_i ;//Default clear with Zeros from Wishbone
assign I2SData_wMEM_WE_mux_sig 	= (wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i) ? wb_FIR_L_PreDeci_RAM_Wen_i  : I2S_wMEM_WE_sig ;
assign I2SData_wclk 			= (wb_FIR_L_PreDeci_RAM_wrMASTER_CTRL_i) ? ~WBs_CLK_i  : ~i2s_clk_i ;



gclkbuff  u_i2s_predeci_ram_gclkbuff
			(
			.A(I2SData_wclk),	
			.Z(I2SData_gclk_wclk)
			);

//FIFO for storing decimation samples
//assign L_MONO_i2sblk_RXFIFO_PUSH 	= (STEREO_EN_i)? L_PreDeci_RXRAM_WR_i: 1'b0;
		
af512x16_512x16                u_af512x16_512x16_L 
                            (
        .DIN                ( FIR_Deci_DATA_i	),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( FIR_Deci_DATA_PUSH_i    ),
        .POP                ( DeciData_RXFIFO_Pop ), //( L_RXFIFO_Pop          ),
        .Push_Clk           ( WBs_CLK_i     ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( DeciData_Rx_FIFO_Empty_flag_sig            ),//L_POP_FLAG_
        .DOUT               ( L_DeciData_RXFIFO_DAT         )//L_RXFIFO_DAT_
        );										
			

// Ram instantiation 
//I2S Mono data is written to RAM for FIR decimation
r512x16_512x16 u_r512x16_512x16_I2S_PREDECIM_DATA (
								 .WA	  	(I2SData_ADDR_mux_sig), //( I2S_FIR_DATA_WaDDR_sig  ) 	,
								 .RA		( FIR_L_PreDeci_DATA_RaDDR_i )	,
								 
								 .WD		(I2SData_DATA_mux_sig), //( L_PreDeci_RXRAM_DAT_i  )	,
								 .WD_SEL	(I2SData_wMEM_WE_mux_sig), //( I2S_wMEM_WE_sig  )	,
								 .RD_SEL	( 1'b1 )	,
								 .WClk		(I2SData_gclk_wclk),//( i2s_clk_i )	,
								 .RClk		( WBs_CLK_i )	,
								 .WClk_En	( 1'b1  )	,
								 .RClk_En	( 1'b1  )	,
								 .WEN		( {I2SData_wMEM_WE_mux_sig,I2SData_wMEM_WE_mux_sig}  )	,
								 .RD		( FIR_L_PreDeci_RD_DATA_o  )	,
								 .LS		( 1'b0  )	,
								 .DS		( 1'b0  )	,
								 .SD		( 1'b0  )	,
								 .LS_RB1	( 1'b0  )	,
								 .DS_RB1	( 1'b0  )	,
								 .SD_RB1    ( 1'b0  )
		

								);
								



endmodule


//input            [15:0]  R_RXFIFO_DAT_i;
//input                    R_RXFIFO_PUSH_i;

//output           [15:0]  L_RXFIFO_DAT_o;
//input                    L_RXFIFO_Pop_i;

//output           [15:0]  R_RXFIFO_DAT_o; 
//input                    R_RXFIFO_Pop_i; 

//output           [31:0]  LR_RXFIFO_DAT_o;
//input                    STEREO_EN_i;
//input                    LR_CHNL_SEL_i; 
//output                   LR_Rx_FIFO_Full_o; 
//output                   LR_Rx_FIFO_Empty_o; 
//output            [8:0]  LR_Rx_FIFO_Level_o;

//input                    DeciData_RXFIFO_Pop_i; //Can be Used as read enable for RAM
//input                    DMA_Busy_i;

//output                   L_Rx_FIFO_Full_o;
//output                   L_Rx_FIFO_Empty_o;
//output            [8:0]  DeciData_Rx_FIFO_Level_o;

//output                   R_Rx_FIFO_Full_o;
//output                   R_Rx_FIFO_Empty_o;
//output            [8:0]  R_Rx_FIFO_Level_o;
// Fabric Global Signals
//

//wire            [15:0]  R_RXFIFO_DAT_i;
//wire                    R_RXFIFO_PUSH_i;

//wire           [15:0]   L_RXFIFO_DAT_o;
//wire                    L_RXFIFO_Pop_i;
//wire           [15:0]   L_DeciData_RXFIFO_DAT;

//wire           [15:0]   R_RXFIFO_DAT_o;
//wire                    R_RXFIFO_Pop_i;
//wire           [15:0]   R_RXFIFO_DAT;

//wire           [31:0]   LR_RXFIFO_DAT_o;
//wire           [15:0]   LR_RXFIFO_DAT;

//wire                    LR_RXFIFO_PUSH;
//wire                    STR_RXFIFO_PUSH;
//wire                    LR_RXFIFO_PUSH_WBCLK;
//wire                    STR_RXFIFO_PUSH_WBCLK;
//wire                    STR_RXFIFO_Pop;
//wire                    STEREO_EN_i;
//wire                    LR_CHNL_SEL_i; 
//wire                    LR_Rx_FIFO_Full_o; 
//wire                    LR_Rx_FIFO_Empty_o;

//wire                    DeciData_RXFIFO_Pop_i; 
//wire                    DMA_Busy_i; 

//reg 					L_RXFIFO_PUSH_r, L_RXFIFO_PUSH_r1, L_RXFIFO_PUSH_r2;
//reg 					R_RXFIFO_PUSH_r, R_RXFIFO_PUSH_r1, R_RXFIFO_PUSH_r2;

//wire   					L_RXFIFO_PUSH;
//wire   					R_RXFIFO_PUSH;

//wire  					DeciData_RXFIFO_Pop;
//wire   					R_RXFIFO_Pop;

  
// FIFO Flags
//
//wire                     L_Rx_FIFO_Full_o;
//wire                     L_Rx_FIFO_Empty_o; 
//wire			[3:0]	 L_DeciData_POP_FLAG;

//wire                     R_Rx_FIFO_Full_o;
//wire                     R_Rx_FIFO_Empty_o; 
//wire			[3:0]	 R_POP_FLAG; 

//wire			[3:0]	 LR_POP_FLAG;

// Count of FIFO contents
//
//reg               [8:0]  DeciData_Rx_FIFO_Level_o;
//reg               [8:0]  DeciData_Rx_FIFO_Level_nxt;

//reg               [8:0]  R_Rx_FIFO_Level_o;
//reg               [8:0]  R_Rx_FIFO_Level_nxt;

//reg               [8:0]  LR_Rx_FIFO_Level_o; 
//reg               [8:0]  LR_Rx_FIFO_Level_nxt;

//wire					 MONO_RXFIFO_PUSH_L; 
//wire					 MONO_RXFIFO_PUSH_R;

//wire					 L_MONO_RXFIFO_PUSH;
//wire					 R_MONO_RXFIFO_PUSH;

//reg   					 LR_RXFIFO_PUSH_t; 
//reg   					 LR_RXFIFO_PUSH_tr1;
//wire					 LR_RXFIFO_PUSH_NEG;



//assign L_RXFIFO_Pop = (STEREO_EN_i)? DeciData_RXFIFO_Pop : 1'b0;
//assign MONO_RXFIFO_PUSH_L = (STEREO_EN_i)? L_RXFIFO_PUSH : 1'b0;
//------Instantiate Modules------------
//

// Left Receive FIFO - Base on AL4S3B 512x16 FIFO
//
//assign L_MONO_RXFIFO_PUSH = (STEREO_EN_i)? L_PreDeci_RXRAM_WR_i: 1'b0;

/* af512x16_512x16                u_af512x16_512x16_L
                            (
        .DIN                ( L_PreDeci_RXRAM_DAT_i		),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( L_MONO_RXFIFO_PUSH    ),
        .POP                ( L_RXFIFO_Pop          ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( L_DeciData_POP_FLAG            ),
        .DOUT               ( L_DeciData_RXFIFO_DAT          )
        ); */

// Right Receive FIFO - Base on AL4S3B 512x16 FIFO
//
/* assign R_MONO_RXFIFO_PUSH = (STEREO_EN_i)? R_RXFIFO_PUSH_i: 1'b0;

af512x16_512x16                u_af512x16_512x16_R
                            (
        .DIN                ( R_RXFIFO_DAT_i		),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( R_MONO_RXFIFO_PUSH    ),
        .POP                ( R_RXFIFO_Pop          ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( R_POP_FLAG            ),
        .DOUT               ( R_RXFIFO_DAT          )
        ); */
		
		
		
/* assign LR_RXFIFO_DAT   = (LR_CHNL_SEL_i)? R_RXFIFO_DAT_i: L_PreDeci_RXRAM_DAT_i;
assign LR_RXFIFO_PUSH  = (LR_CHNL_SEL_i)? R_RXFIFO_PUSH_i: L_PreDeci_RXRAM_WR_i;
assign STR_RXFIFO_PUSH = (STEREO_EN_i)? 1'b0 : LR_RXFIFO_PUSH; */

// Right/Left Receive FIFO - Base on AL4S3B af1024x16_512x32 FIFO
//
/* af1024x16_512x32                u_af1024x16_512x32_LR
                            (
        .DIN                ( LR_RXFIFO_DAT		    ),
        .Fifo_Push_Flush    ( Rx_FIFO_Flush         ),
        .Fifo_Pop_Flush     ( Rx_FIFO_Flush         ),  
        .PUSH               ( STR_RXFIFO_PUSH       ),
        .POP                ( STR_RXFIFO_Pop        ),
        .Push_Clk           ( i2s_clk_i             ),
		.Pop_Clk            ( WBs_CLK_i             ),
        .Push_Clk_En        ( 1'b1                  ),
		.Pop_Clk_En         ( 1'b1                  ),
        .Fifo_Dir           ( 1'b0                  ),
        .Async_Flush        ( Rx_FIFO_Flush         ),
        .Almost_Full        (                       ),
        .Almost_Empty       (                       ),
        .PUSH_FLAG          (                       ),
        .POP_FLAG           ( LR_POP_FLAG           ),
        .DOUT               ( LR_RXFIFO_DAT_o       )
        ); */

//syncing with WBs_CLK_i clock

/* always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        L_RXFIFO_PUSH_r   <= 1'b0;
		L_RXFIFO_PUSH_r1  <= 1'b0;
		L_RXFIFO_PUSH_r2  <= 1'b0;
		
        R_RXFIFO_PUSH_r   <= 1'b0;
		R_RXFIFO_PUSH_r1  <= 1'b0;
		R_RXFIFO_PUSH_r2  <= 1'b0;
		
    end  
    else
    begin
        L_RXFIFO_PUSH_r   <= L_PreDeci_RXRAM_WR_i;
		L_RXFIFO_PUSH_r1  <= L_RXFIFO_PUSH_r;
		L_RXFIFO_PUSH_r2  <= L_RXFIFO_PUSH_r1;
		
        R_RXFIFO_PUSH_r   <= R_RXFIFO_PUSH_i;
		R_RXFIFO_PUSH_r1  <= R_RXFIFO_PUSH_r;
		R_RXFIFO_PUSH_r2  <= R_RXFIFO_PUSH_r1;

    end  
end

assign L_RXFIFO_PUSH = L_RXFIFO_PUSH_r2 & ~L_RXFIFO_PUSH_r1;
assign R_RXFIFO_PUSH = R_RXFIFO_PUSH_r2 & ~R_RXFIFO_PUSH_r1; */

// Define the Fabric's Local Registers
//
/* always @( posedge WBs_CLK_i or posedge WBs_RST_i)
begin
    if (WBs_RST_i)
    begin
        DeciData_Rx_FIFO_Level_o  <= 9'h0;
		R_Rx_FIFO_Level_o  <= 9'h0; 
		LR_Rx_FIFO_Level_o <= 9'h0;
		LR_RXFIFO_PUSH_tr1 <= 1'b0;
    end  
    else
    begin
	    DeciData_Rx_FIFO_Level_o  <= DeciData_Rx_FIFO_Level_nxt;
	    R_Rx_FIFO_Level_o  <= R_Rx_FIFO_Level_nxt;
		LR_Rx_FIFO_Level_o <= LR_Rx_FIFO_Level_nxt;
		LR_RXFIFO_PUSH_tr1 <= LR_RXFIFO_PUSH_t;
    end  
end */

// Determine the Rx FIFO Level  
//
//assign LR_RXFIFO_PUSH_WBCLK  = (LR_CHNL_SEL_i)? R_RXFIFO_PUSH: L_RXFIFO_PUSH;

/* always @( posedge WBs_CLK_i or posedge Rx_FIFO_Flush)
begin
    if (Rx_FIFO_Flush)
    begin
         LR_RXFIFO_PUSH_t  <= 1'b0;
    end  
    else
    begin
	  if (LR_RXFIFO_PUSH_WBCLK)
		 LR_RXFIFO_PUSH_t  <= ~LR_RXFIFO_PUSH_t;
	  else
	     LR_RXFIFO_PUSH_t  <=  LR_RXFIFO_PUSH_t;
    end  
end */

/* assign LR_RXFIFO_PUSH_NEG = LR_RXFIFO_PUSH_tr1 & ~LR_RXFIFO_PUSH_t;
assign STR_RXFIFO_PUSH_WBCLK = (STEREO_EN_i)? 1'b0 : LR_RXFIFO_PUSH_NEG;
assign STR_RXFIFO_Pop = (STEREO_EN_i)? 1'b0 : DeciData_RXFIFO_Pop; */

/* always @( STR_RXFIFO_Pop            or
          STR_RXFIFO_PUSH_WBCLK     or
          Deci_Rx_FIFO_Flush_i           or
          LR_Rx_FIFO_Level_o
         )
begin

    case(Deci_Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({STR_RXFIFO_Pop, STR_RXFIFO_PUSH_WBCLK})
        2'b00: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one word
        2'b10: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one word
        2'b11: LR_Rx_FIFO_Level_nxt <= LR_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      LR_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end */ 


//assign DeciData_RXFIFO_Pop = (DMA_Busy_i)? DeciData_RXFIFO_Pop_i : L_RXFIFO_Pop_i;
//assign R_RXFIFO_Pop = (STEREO_EN_i)? DeciData_RXFIFO_Pop : 1'b0;
//assign MONO_RXFIFO_PUSH_R = (STEREO_EN_i)? R_RXFIFO_PUSH : 1'b0;

/* always @( R_RXFIFO_Pop           or
          MONO_RXFIFO_PUSH_R     or
          Deci_Rx_FIFO_Flush_i        or
          R_Rx_FIFO_Level_o
         )
begin

    case(Deci_Rx_FIFO_Flush_i)
    1'b0:
    begin
        case({R_RXFIFO_Pop, MONO_RXFIFO_PUSH_R})
        2'b00: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o       ;  // No Operation -> Hold
        2'b01: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o + 1'b1;  // Push         -> add      one byte
        2'b10: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o - 1'b1;  // Pop          -> subtract one byte
        2'b11: R_Rx_FIFO_Level_nxt <= R_Rx_FIFO_Level_o       ;  // Push and Pop -> Hold
        endcase
    end
    1'b1:      R_Rx_FIFO_Level_nxt <=  9'h0                 ;
    endcase

end  */


// Determine the Rx FIFO Empty Flag
//
//assign L_Rx_FIFO_Empty_o = (L_DeciData_POP_FLAG == 4'h0)? 1'b1 : 1'b0;
//assign R_Rx_FIFO_Empty_o = (R_POP_FLAG == 4'h0)? 1'b1 : 1'b0;

//assign L_Rx_FIFO_Full_o = (L_DeciData_POP_FLAG == 4'hF)? 1'b1 : 1'b0;
//assign R_Rx_FIFO_Full_o = (R_POP_FLAG == 4'hF)? 1'b1 : 1'b0;

//assign LR_Rx_FIFO_Full_o = (LR_POP_FLAG == 4'hF)? 1'b1 : 1'b0; 
//assign LR_Rx_FIFO_Empty_o = (LR_POP_FLAG == 4'h0)? 1'b1 : 1'b0;


// Match port sizes
//
// Note: The FIFO's contents are undefine prior to the first Push. Therefore,
//       the output should be forced to a default (i.e. "safe") value.
//
/* assign L_RXFIFO_DAT_o      = L_Rx_FIFO_Empty_o ? 16'h0 : L_DeciData_RXFIFO_DAT;
assign R_RXFIFO_DAT_o      = R_Rx_FIFO_Empty_o ? 16'h0 : R_RXFIFO_DAT; */
